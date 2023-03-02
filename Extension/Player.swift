import Foundation
import SwiftUI
import AVFAudio
import MediaPlayer
import WatchKit
//import Sentry

class Player {
    @ObservedObject private var store: Store = .shared

    let step = Step()
    var speed = Speed()
    var heart = Heart()
    var isPanningReversed: Bool = true
    var fadeScale: [Float] = []
    var panScale: [Float] = []
    var audios: [Audio] = []
    var players: [String: AVAudioPlayer] = [:]
    var isLoopStarted: Bool = false
    var coordinator = WKExtendedRuntimeSession()

    init() {
        /*
        SentrySDK.start { options in
            options.dsn = SENTRY_DSN
            options.debug = true
            options.tracesSampleRate = 1.0
        }
        */
        store.state.setMetricValuesToDefault()
        store.state.seeds = getAllSeeds(seedInputs: SEED_INPUTS)
        fadeScale = getFadeScale()
        panScale = getPanScale()

        do {
            let data = readFromFile(key: STORE_SESSION_LOGS)
            store.state.sessionLogs = try JSONDecoder().decode([Session].self, from: data)
            store.state.sessionLogIds = getSessionIds(sessions: store.state.sessionLogs)
        } catch {}

        do {
            let data = readFromFile(key: STORE_ACTIVE_SESSION)
            store.state.session = try JSONDecoder().decode(Session.self, from: data)
        } catch {}

        initIntervals()

        if store.state.session.isActive {
            store.state.isResumable = true
        }

        startElapsedTimer()
        cachePlayers()
    }

    func cachePlayers() {
        for key in store.state.distances.keys {
            let forResource = SAMPLE_PATH + String(key) + "." + SAMPLE_EXTENSION
            let player = load(forResource: forResource, withExtension: SAMPLE_EXTENSION)
            player?.prepareToPlay()
            players[forResource] = player
        }
    }

    func initIntervals() {
        Timer.scheduledTimer(withTimeInterval: TIMESERIES_SAVER_INTERVAL_S, repeats: true) { timer in
            if self.store.state.session.isActive && !self.store.state.isResumable  {
                self.saveReadings()
            }
        }
    }

    func saveReadings() {
        let readings: [String: [Reading]] = getAverages(timeseries: store.state.readings)
        let id = getTimeseriesUpdateId(uuid: store.state.session.uuid, date: Date()) + "|" + DEFAULT_TIME_RESOLUTION

        do {
            let data = try JSONEncoder().encode(readings)
            writeToFile(key: id, data: data)
        } catch {}

        store.state.readings.keys.forEach {
            store.state.readings[$0] = []
        }
    }

    func start() {
        store.state.isResumable = false
        store.state.setMetricValuesToDefault()
        putToBackground()

        if !isLoopStarted {
            loop()
            isLoopStarted = true
        }

        create()
        play()
        store.state.session.start()
        sessionPlay()
    }

    func stop() {
        pause()
        saveReadings()
        store.state.elapsedTime = ""
        store.state.setMetricValuesToDefault()
        sessionPause()
        store.state.session.stop()
        store.state.sessionLogs.append(store.state.session)
        store.state.sessionLogIds = getSessionIds(sessions: store.state.sessionLogs)
        saveSessionLogs(sessionLogs: store.state.sessionLogs)
        store.state.session = Session()
        coordinator.invalidate()
    }

    func startElapsedTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if self.store.state.session.isActive && !self.store.state.isResumable {
                self.store.state.elapsedTime = getElapsedTime(from: self.store.state.session.startTime, to: Date())
            }
        }
    }

    func load(forResource: String, withExtension: String) -> AVAudioPlayer? {
        do {
            guard let url: URL = Bundle.main.url(
                forResource: forResource.replacingOccurrences(of: "." + withExtension, with: ""),
                withExtension: withExtension
            ) else {
                return nil
            }

            return try AVAudioPlayer(contentsOf: url)
        }
        catch {
            print("load()", error)
        }

        return nil
    }

    func getTrack(sample: String, seedInput: SeedInput) -> Track {
        let interval = seedInput.interval
        let track = Track()

        track.id = Int(sample.split(separator: ".")[0])!

        for space in interval {
            track.samples.append(space > 0 ? SAMPLE_PATH + sample : "")
        }

        return track
    }

    func getAllSeeds(seedInputs: [SeedInput]) -> [Seed] {
        var seeds: [Seed] = []
        
        for seedInput in seedInputs {
            let seed = Seed()

            seed.tracks = store.state.distances
                .map {
                    getTrack(sample: String($0.key) + "." + SAMPLE_EXTENSION, seedInput: seedInput)
                }
                .shuffled()
            seeds.append(seed)
        }

        return seeds
    }

    func setChannels(audioIndex: Int) {
        audios[audioIndex].channels = []

        for seed in store.state.seeds {
            let channel: [String] = seed.tracks[store.state.queueIndex + audioIndex].samples

            audios[audioIndex].channels.append(channel)
        }
    }

    func getPlayerId(channelIndex: Int, forResource: String) -> String {
        return String(channelIndex) + forResource
    }

    func setHaptic() {
        if !Platform.isSimulator {
            if isPanningReversed {
                WKInterfaceDevice.current().play(.failure)
            }
            else {
                WKInterfaceDevice.current().play(.success)
            }
        }
    }

    func setAudio(
        audioIndex: Int,
        channelIndex: Int,
        sampleIndex: Int
    ) {
        let channel = audios[audioIndex].channels[channelIndex]
        let forResource = channel[sampleIndex]
        let pansScaleIndex: Int = !isPanningReversed
            ? sampleIndex
            : panScale.count - 1 - sampleIndex
        let hasResources: Bool = forResource.count > 0
        if hasResources {
            let playerId = forResource

            players[playerId]?.currentTime = 0
            players[playerId]?.pan = panScale[pansScaleIndex]
            let fade = audios[audioIndex].fadeIndex > -1
                ? fadeScale[audios[audioIndex].fadeIndex]
                : 0
            players[playerId]?.volume = store.state.session.volume / 100 * Float(fade)
            players[playerId]?.play()
        }
    }

    func incrementSelectedRhythmIndex() {
        store.state.selectedRhythmIndex = store.state.selectedRhythmIndex + 1

        if store.state.selectedRhythmIndex == getRhythms(store).count {
            store.state.selectedRhythmIndex = 0
        }
    }

    func getSelectedRhythm() -> Double {
        return Double(getRhythms(store)[store.state.selectedRhythmIndex])
    }

    func getLoopInterval(selectedRhythmIndex: Int) -> TimeInterval {
        let metricType = store.state.metricType
        let pace = store.state.getMetricValue(metricType.metric)
        let isReversed = metricType.isReversed
        let selectedRhythm: Double = getSelectedRhythm()

        var loopInterval: TimeInterval = isReversed ? selectedRhythm / 1 / Double(pace) : selectedRhythm / Double(pace)
        loopInterval = loopInterval / Double(DOWN_SCALE)
        loopInterval = loopInterval <= 0 ? 1 : loopInterval
        loopInterval = loopInterval * 60
        return loopInterval
    }

    func getLoopIntervalSum() -> TimeInterval {
        let loopIntervalSum: TimeInterval = getRhythms(store).enumerated()
            .map { (index, _) in
                return getLoopInterval(selectedRhythmIndex: index)
            }
            .reduce(0, +)

        return loopIntervalSum
    }

    func updateFeedback(loopInterval: TimeInterval) {
        for (audioIndex, audio) in audios.enumerated() {
            for (channelIndex, channel) in audio.channels.enumerated() {
                let isAudio = FEEDBACK_MODES[store.state.session.feedbackModeIndex] == "Audio"
                let isHaptic = FEEDBACK_MODES[store.state.session.feedbackModeIndex] == "Haptic"
                let isMuted = !(Float(store.state.session.volume) > 0)

                if audioIndex == 0 && channelIndex == 0 && (audio.sampleIndex == 0 || audio.sampleIndex == DOWN_SCALE - 1) {
                    isPanningReversed = !isPanningReversed
                    incrementSelectedRhythmIndex()

                    if isHaptic {
                        setHaptic()
                    }
                }

                if channelIndex == audio.channels.count - 1 {
                    audio.sampleIndex = audio.sampleIndex + 1
                }

                if audio.sampleIndex == channel.count {
                    audio.sampleIndex = 0
                }

                audio.fadeIndex = audio.fadeIndex + 1
                let isTransitioning = audio.fadeIndex == CHANNEL_REPEAT_COUNT

                let islastQuarter = audio.fadeIndex == FADE_DURATION * 3 - 1
                if islastQuarter {
                    pick(audioIndex: 1, regenerate: false)
                    audios[1].fadeIndex = 0
                }

                if isTransitioning {
                    audios[0].fadeIndex = -FADE_DURATION * 2 + 1
                    audios = audios.reversed()
                }

                if !isMuted && isAudio && channel[audio.sampleIndex] != "" {
                    setAudio(
                        audioIndex: audioIndex,
                        channelIndex: channelIndex,
                        sampleIndex: audio.sampleIndex
                    )
                }
            }
        }
    }

    func loop() {
        let loopInterval: TimeInterval = getLoopInterval(selectedRhythmIndex: store.state.selectedRhythmIndex)

        if !loopInterval.isInfinite && store.state.isAudioPlaying {
            Timer.scheduledTimer(withTimeInterval: loopInterval, repeats: false) { (timer: Timer) in
                self.loop()
            }

            if self.store.state.session.isPlaying {
                self.updateGraph()
                self.updateFeedback(loopInterval: loopInterval)
            }
        }
        else {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { (timer: Timer) in
                self.loop()
            }
        }
    }

    func updateGraph() {
        let timestamp: Date = Date()
        let loopIntervalSum: TimeInterval = getLoopIntervalSum()

        store.state.setMetricValue("breath", 1 / Float(loopIntervalSum) / Float(DOWN_SCALE) * 60)
        store.state.setMetricValue(store.state.metricType.metric + "-to-breath", store.state.getMetricValue("breath"))
        store.state.preset.breathingTypes.forEach {
            store.state.setMetricValue($0.key.rawValue, $0.rhythm)
        }

        for metric in METRIC_TYPES.keys {
            let value: Float = store.state.getMetricValue(metric)

            if canUpdate(value) {
                if store.state.readings[metric] == nil {
                    store.state.readings[metric] = []
                }

                let reading = Reading()
                reading.timestamp = timestamp
                reading.value = value
                store.state.readings[metric]?.append(reading)
            }
        }
    }

    func togglePlay() {
        if store.state.session.isPlaying { sessionPause() }
        else { sessionPlay() }
    }

    func sessionPlay() {
        heart.start()
        step.start()
        speed.start()
        store.state.session.isPlaying = true
    }

    func sessionPause() {
        heart.stop()
        step.stop()
        speed.stop()
        store.state.session.isPlaying = false
    }

    func create() {
        audios = []
        shuffle()
        flushAll()

        let audio = Audio(
            fadeIndex: 0,
            sampleIndex: 0,
            channels: [],
            forResources: []
        )
        let audio2 = audio.copy() as! Audio
        audio2.fadeIndex = -FADE_DURATION * 3 + 1

        audios.append(audio)
        audios.append(audio2)

        setChannels(audioIndex: 0)
        setChannels(audioIndex: 1)
        resetFadeIndexes()
    }

    func play() {
        Task {
            do {
                if !store.state.isAudioSessionLoaded {
                    let audioSession = AVAudioSession.sharedInstance()
                    try audioSession.setCategory(
                        .playback,
                        mode: .default,
                        options: [.mixWithOthers]
                    )
                    store.state.isAudioSessionLoaded = try await audioSession.activate()
                }

                store.state.isAudioPlaying = true

            }
            catch {
                print("startAudioSession()", error)
            }
        }
    }

    func pause() {
        store.state.isAudioPlaying = false

        for audio in audios {
            audio.forResources.forEach {
                players[$0]?.pause()
            }
        }
    }

    func putToBackground() {
        takeFromBackground()
        coordinator.start()
    }

    func takeFromBackground() {
        if coordinator.state == .running {
            coordinator.invalidate()
        }
    }

    func shuffle() {
        var channels: [Seed] = []
        for channel in store.state.seeds {
            channel.tracks = channel.tracks.shuffled()
            channels.append(channel)
        }
        store.state.seeds = channels
    }

    func resetFadeIndexes() {
        audios[0].fadeIndex = FADE_DURATION - 1
        audios[1].fadeIndex = -FADE_DURATION * 2 + 1
    }

    func flushAll() {
        for (audioIndex, _) in audios.enumerated() {
            flush(audioIndex: audioIndex)
            pick(audioIndex: audioIndex, regenerate: true)
        }
    }

    func flush(audioIndex: Int) {
        audios[audioIndex].sampleIndex = 0
        audios[audioIndex].forResources = []
    }

    func incrementQueueIndex() {
        store.state.queueIndex = store.state.queueIndex + 1

        if store.state.queueIndex == store.state.distances.count - 1 {
            store.state.queueIndex = 0
        }
    }

    func pick(audioIndex: Int, regenerate: Bool) {
        if regenerate {
            shuffle()

            for (channelIndex, _) in store.state.seeds.enumerated() {
                store.state.queueIndex = 0

                for (trackIndex, _) in store.state.seeds[channelIndex].tracks.enumerated() {
                    let lastTrack = store.state.seeds[channelIndex].tracks[trackIndex]
                    let distances: [Distance] = store.state.distances[lastTrack.id] ?? []
                    var summary: [Int: Double] = [:]

                    for distance in distances {
                        let nextDistances: [Distance] = store.state.distances[distance.rightId] ?? []

                        for nextDistance in nextDistances {
                            summary[nextDistance.rightId] = distance.value + nextDistance.value
                        }
                    }

                    let sortedSummary: [Dictionary<Int, Double>.Element] = summary
                        .sorted { Double($0.value) < Double($1.value) }

                    // Introduce some randomness to the audio picker.
                    let shuffledSummary: [Dictionary<Int, Double>.Element] = Array(sortedSummary[0...1])
                        .shuffled()

                    let index = store.state.seeds[channelIndex].tracks
                        .firstIndex(where: { $0.id == shuffledSummary[0].key }) ?? 0
                    let element = store.state.seeds[channelIndex].tracks
                        .remove(at: index)
                    store.state.seeds[channelIndex].tracks
                        .insert(element, at: trackIndex)
                }
            }

            flush(audioIndex: audioIndex)
        }
        else {
            incrementQueueIndex()
        }

        setChannels(audioIndex: audioIndex)
        play()
    }
}
