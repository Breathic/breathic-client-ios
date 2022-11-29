import Foundation
import SwiftUI
import AVFAudio
import MediaPlayer

class Player {
    @ObservedObject private var store: Store = .shared

    let coordinator = Coordinator()
    let step = Step()
    var speed = Speed()
    var heart = Heart()
    var isPanningReversed: Bool = true
    var fadeScale: [Float] = []
    var panScale: [Float] = []
    var audios: [Audio] = []
    var players: [String: AVAudioPlayer] = [:]
    var isLoopStarted = false

    init() {
        store.state.setMetricValuesToDefault()
        store.state.seeds = getAllSeeds(seedInputs: SEED_INPUTS)
        cachePlayers()
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

        initReadingsSaver()

        if store.state.session.isActive {
            store.state.isResumable = true
        }

        startElapsedTimer()

        //UserDefaults.standard.set("", forKey: STORE_ACTIVE_SESSION) // Clear a key.
    }

    func cachePlayers() {
        for key in store.state.distances.keys {
            let forResource = SAMPLE_PATH + String(key) + "." + SAMPLE_EXTENSION
            let player = load(forResource: forResource, withExtension: SAMPLE_EXTENSION)
            player?.prepareToPlay()
            players[forResource] = player
        }
    }

    func initReadingsSaver() {
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

    /*
    func initCommandCenter() {
        let commandCenter = MPRemoteCommandCenter.shared()

        commandCenter.playCommand.addTarget { [unowned self] event in
            self.play()
            return .success
        }

        commandCenter.pauseCommand.addTarget { [unowned self] event in
            self.pause()
            return .success
        }

        commandCenter.nextTrackCommand.addTarget { [unowned self] event in
            self.create()
            return .success
        }
    }
    */

    func initInactivityTimer() {
        store.state.lastDataChangeTime = .now()

        Timer.scheduledTimer(withTimeInterval: DATA_INACTIVITY_S, repeats: true) { timer in
            if self.store.state.lastDataChangeTime.distance(to: .now()).toDouble() > DATA_INACTIVITY_S {
                self.store.state.lastDataChangeTime = .now()
                self.pause()
            }
        }
    }

    func start() {
        store.state.isResumable = false

        store.state.setMetricValuesToDefault()

        heart.start()
        step.start()
        speed.start()
        coordinator.start()

        if !isLoopStarted {
            loop()
            isLoopStarted = true
        }

        if !Platform.isSimulator {
            initInactivityTimer()
        }

        create()
        play()
        store.state.session.start()
    }

    func startElapsedTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if self.store.state.session.isActive && !self.store.state.isResumable {
                self.store.state.elapsedTime = getElapsedTime(from: self.store.state.session.startTime, to: Date())
            }
        }
    }

    func stop() {
        pause()
        heart.stop()
        step.stop()
        speed.stop()
        coordinator.stop()
        store.state.session.stop()
        saveReadings()
        store.state.elapsedTime = ""
        store.state.sessionLogs.append(store.state.session)
        store.state.sessionLogIds = getSessionIds(sessions: store.state.sessionLogs)
        saveSessionLogs(sessionLogs: store.state.sessionLogs)
        store.state.setMetricValuesToDefault()
    }

    func load(forResource: String, withExtension: String) -> AVAudioPlayer? {
        do {
            guard let url = Bundle.main.url(
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

    func getRhythm(sample: String, seedInput: SeedInput) -> Rhythm {
        //let durationRange = seedInput.durationRange
        let interval = seedInput.interval
        let rhythm = Rhythm()

        rhythm.id = Int(sample.split(separator: ".")[0])!
        //rhythm.durationRange = durationRange

        for space in interval {
            rhythm.samples.append(space > 0 ? SAMPLE_PATH + sample : "")
        }

        return rhythm
    }

    func getAllSeeds(seedInputs: [SeedInput]) -> [Seed] {
        var seeds: [Seed] = []
        
        for seedInput in seedInputs {
            let seed = Seed()

            seed.rhythms = store.state.distances
                .map {
                    getRhythm(sample: String($0.key) + "." + SAMPLE_EXTENSION, seedInput: seedInput)
                }
                .shuffled()
            seeds.append(seed)
        }
        
        return seeds
    }

    func setChannels(audioIndex: Int) {
        audios[audioIndex].channels = []

        for seed in store.state.seeds {
            let channel: [String] = seed.rhythms[store.state.queueIndex + audioIndex].samples

            audios[audioIndex].channels.append(channel)
        }
    }

    func getPlayerId(channelIndex: Int, forResource: String) -> String {
        return String(channelIndex) + forResource
    }

    func setPlayer(
        audioIndex: Int,
        channelIndex: Int,
        sampleIndex: Int
    ) {
        let channel = audios[audioIndex].channels[channelIndex]
        let forResource = channel[sampleIndex]
        let pansScaleIndex = !isPanningReversed
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

        if store.state.selectedRhythmIndex == store.state.session.getRhythms().count {
            store.state.selectedRhythmIndex = 0
        }
    }

    func getSelectedRhythm() -> Double {
        return Double(store.state.session.getRhythms()[store.state.selectedRhythmIndex]) / 10
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
        let loopIntervalSum: TimeInterval = store.state.session.getRhythms().enumerated()
            .map { (index, _) in
                return getLoopInterval(selectedRhythmIndex: index)
            }
            .reduce(0, +)

        return loopIntervalSum
    }

    func updateAudio(loopInterval: TimeInterval) {
        for (audioIndex, audio) in audios.enumerated() {
            for (channelIndex, channel) in audio.channels.enumerated() {
                if audioIndex == 0 && channelIndex == 0 && (
                    audio.sampleIndex == 0 || audio.sampleIndex == DOWN_SCALE - 1) {
                    isPanningReversed = !isPanningReversed
                    incrementSelectedRhythmIndex()
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

                if channel[audio.sampleIndex] != "" {
                    setPlayer(
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

        if !loopInterval.isInfinite && store.state.isAudioSessionLoaded {
            Timer.scheduledTimer(withTimeInterval: loopInterval, repeats: false) { timer in
                self.loop()
            }

            self.updateGraph()
            self.updateAudio(loopInterval: loopInterval)
        }
        else {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
                self.loop()
            }
        }
    }

    func updateGraph() {
        let timestamp = Date()
        let loopIntervalSum = getLoopIntervalSum()

        store.state.setMetricValue("breath", 1 / Float(loopIntervalSum) / Float(DOWN_SCALE) * 60)
        store.state.setMetricValue(store.state.metricType.metric + "-to-breath", store.state.getMetricValue("breath"))
        store.state.setMetricValue("rhythm-in", Float(store.state.session.getRhythms()[0]) / 10)
        store.state.setMetricValue("rhythm-out", Float(store.state.session.getRhythms()[1]) / 10)

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
        if store.state.isAudioSessionLoaded { pause() }
        else { play() }
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
                let audioSession = AVAudioSession.sharedInstance()
                try audioSession.setCategory(
                    .playback,
                    mode: .default,
                    options: [.mixWithOthers]
                )
                store.state.isAudioSessionLoaded = try await audioSession.activate()
            }
            catch {
                store.state.isAudioSessionLoaded = false
                print("startAudioSession()", error)
            }
        }
    }

    func pause() {
        store.state.isAudioSessionLoaded = false

        for audio in audios {
            audio.forResources.forEach {
                players[$0]?.pause()
            }
        }
    }

    func shuffle() {
        var channels: [Seed] = []
        for channel in store.state.seeds {
            channel.rhythms = channel.rhythms.shuffled()
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

                for (rhythmIndex, _) in store.state.seeds[channelIndex].rhythms.enumerated() {
                    let lastRhythm = store.state.seeds[channelIndex].rhythms[rhythmIndex]
                    let distances: [Distance] = store.state.distances[lastRhythm.id] ?? []
                    var summary: [Int: Double] = [:]

                    for distance in distances {
                        let nextDistances: [Distance] = store.state.distances[distance.rightId] ?? []

                        for nextDistance in nextDistances {
                            summary[nextDistance.rightId] = distance.value + nextDistance.value
                        }
                    }

                    let sortedSummary = summary
                        .sorted { Double($0.value) < Double($1.value) }
                    let index = store.state.seeds[channelIndex].rhythms
                        .firstIndex(where: { $0.id == sortedSummary[0].key }) ?? 0
                    let element = store.state.seeds[channelIndex].rhythms
                        .remove(at: index)
                    store.state.seeds[channelIndex].rhythms
                        .insert(element, at: rhythmIndex)
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
