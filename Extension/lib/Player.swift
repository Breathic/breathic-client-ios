import Foundation
import SwiftUI
import AVFAudio
import MediaPlayer
//import Sentry

class Player {
    @ObservedObject private var store: Store = .shared

    let step = Step()
    var location = Location()
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
        store.state.sessions = readSessions()
        store.state.activeSession = readActiveSession()

        initIntervals()

        if store.state.activeSession.isActive {
            store.state.isResumable = true
        }

        startElapsedTimer()
        cachePlayers(Breathe.BreatheIn.rawValue)
        cachePlayers(Breathe.BreatheOut.rawValue)
        sync(store.state.sessions.shuffled())
        print(API_URL)
    }

    func cachePlayers(_ type: String = "") {
        for key in store.state.distances.keys {
            let forResource = SAMPLE_PATH + String(key) + "-" + type + "." + SAMPLE_EXTENSION
            let player = load(forResource: forResource, withExtension: SAMPLE_EXTENSION)
            player?.prepareToPlay()
            players[forResource] = player
        }
    }

    func initIntervals() {
        Timer.scheduledTimer(withTimeInterval: TIMESERIES_SAVER_INTERVAL_SECONDLY, repeats: true) { timer in
            if self.store.state.activeSession.isActive && !self.store.state.isResumable  {
                self.saveReadings(TimeUnit.Second)
            }
        }

        Timer.scheduledTimer(withTimeInterval: TIMESERIES_SAVER_INTERVAL_MINUTELY, repeats: true) { timer in
            if self.store.state.activeSession.isActive && !self.store.state.isResumable  {
                self.saveReadings(TimeUnit.Minute)
            }
        }

        Timer.scheduledTimer(withTimeInterval: SYNC_INTERVAL_S, repeats: true) { timer in
            self.sync(self.store.state.sessions.shuffled())
        }
    }

    func sync(_ sessions: [Session]) {
        func _update(_ session: Session) {
            saveSession(session)
            store.state.sessions = readSessions()
        }

        if store.state.isSyncInProgress {
            return
        }

        store.state.isSyncInProgress = true

        Task {
            do {
                let sessions = sessions.filter { session in
                    if session.endTime != nil && session.syncStatus != SyncStatus.Synced {
                        return true
                    }

                    return false
                }

                if sessions.count > 0 {
                    let session = sessions[0]
                    session.syncStatus = SyncStatus.Syncing
                    _update(session)

                    let success = try await uploadSession(session)
                    if success {
                        session.syncStatus = SyncStatus.Synced
                        _update(session)
                    }
                }
            }
            catch {
                print("sync()", error)
            }
        }

        store.state.isSyncInProgress = false
    }

    func saveReadings(_ timeUnit: TimeUnit) {
        let readingContainer: ReadingContainer = getAverages(timeseries: store.state.readings[timeUnit]!)
        let id: String = String(Date().timeIntervalSince1970)

        do {
            let data = try JSONEncoder().encode(readingContainer)
            let folderURL = getFolderURLForReading(
                session: store.state.activeSession,
                timeUnit: timeUnit
            )
            createFolderIfNotExists(url: folderURL)
            let fileURL = folderURL.appendingPathComponent(id)
            writeToFile(url: fileURL, data: data)
        } catch {}

        store.state.readings[timeUnit]!.keys.forEach {
            store.state.readings[timeUnit]![$0] = []
        }
    }

    func start() {
        if !store.state.isResumable {
            store.state.activeSession = Session()
        }

        store.state.isResumable = false
        store.state.setMetricValuesToDefault()
        putToBackground()

        if !isLoopStarted {
            loop()
            isLoopStarted = true
        }

        create()
        play()
        store.state.activeSession.start()
        sessionPlay()
    }

    func stop() {
        pause()
        saveReadings(TimeUnit.Second)
        saveReadings(TimeUnit.Minute)
        store.state.setMetricValuesToDefault()
        sessionPause()
        store.state.activeSession.stop()
        store.state.activeSession.distance = getDistance(store.state.selectedSession)
        store.state.sessions.append(store.state.activeSession)
        saveSession(store.state.activeSession)
        store.state.activeSession = Session()
        coordinator.invalidate()
        sync([store.state.sessions[store.state.sessions.count - 1]])
    }

    func startElapsedTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if self.store.state.activeSession.isActive && !self.store.state.isResumable {
                self.store.state.activeSession.elapsedSeconds = self.store.state.activeSession.elapsedSeconds + 1
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
        String(channelIndex) + forResource
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
        let isVerticalPanning = store.state.audioPanningMode == "Vertical"
        let isHorizontalPanning = store.state.audioPanningMode == "Horizontal"
        let channel = audios[audioIndex].channels[channelIndex]
        let breathType = isVerticalPanning && isPanningReversed
            ? Breathe.BreatheIn.rawValue
            : Breathe.BreatheOut.rawValue
        let separator = "." + SAMPLE_EXTENSION
        let forResource = channel[sampleIndex].split(separator: separator)[0] + "-" + breathType + separator
        if Platform.isSimulator {
            print(forResource)
        }
        let pansScaleIndex: Int = !isPanningReversed
            ? sampleIndex
            : panScale.count - 1 - sampleIndex
        let hasResources: Bool = forResource.count > 0
        if hasResources {
            let playerId = forResource

            players[playerId]?.currentTime = 0
            players[playerId]?.pan = isHorizontalPanning
                ? panScale[pansScaleIndex]
                : 0
            let fade = audios[audioIndex].fadeIndex > -1
                ? fadeScale[audios[audioIndex].fadeIndex]
                : 0

            players[playerId]?.volume = store.state.activeSession.volume / 100 * Float(fade)
            players[playerId]?.play()

            let sampleId = Float(playerId
                .split(separator: "/")[2]
                .split(separator: "-")[0])!
            store.state.setMetricValue("sample-id", sampleId)
        }
    }

    func incrementSelectedRhythmIndex() {
        store.state.selectedRhythmIndex = store.state.selectedRhythmIndex + 1 < getRhythms(store).count
            ? store.state.selectedRhythmIndex + 1
            : 0
    }

    func getSelectedRhythm() -> Double {
        Double(getRhythms(store)[store.state.selectedRhythmIndex])
    }

    func getLoopInterval(selectedRhythmIndex: Int) -> TimeInterval {
        let metricType = METRIC_TYPES[getSourceMetricTypes()[store.state.activeSession.metricTypeIndex]]!
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

    func updateFeedback() {
        for (audioIndex, audio) in audios.enumerated() {
            for (channelIndex, channel) in audio.channels.enumerated() {
                let isAudio = FEEDBACK_MODES[store.state.activeSession.feedbackModeIndex] == "Audio"
                let isHaptic = FEEDBACK_MODES[store.state.activeSession.feedbackModeIndex] == "Haptic"
                let isMuted = !(Float(store.state.activeSession.volume) > 0)

                if audioIndex == 0 {
                    incrementSelectedRhythmIndex()
                }

                if audio.sampleIndex == 0 {
                    isPanningReversed = !isPanningReversed

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

            if self.store.state.activeSession.isPlaying {
                self.updateFeedback()
                self.updateGraph()
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
        let metricType: MetricType = METRIC_TYPES[getSourceMetricTypes()[store.state.activeSession.metricTypeIndex]]!

        store.state.setMetricValue("breath", 1 / Float(loopIntervalSum) / Float(DOWN_SCALE) * 60)

        PRESETS[store.state.activeSession.presetIndex].breathingTypes.forEach {
            if $0.rhythm > 0 {
                store.state.setMetricValue($0.key.rawValue, $0.rhythm)
            }
        }

        for metric in store.state.metrics.keys {
            let value: Float = store.state.getMetricValue(metric)

            if canUpdate(value) {
                let reading = Reading()
                reading.timestamp = timestamp
                reading.value = value

                store.state.readings.forEach {
                    if store.state.readings[$0.key]![metric] == nil {
                        store.state.readings[$0.key]![metric] = []
                    }

                    store.state.readings[$0.key]![metric]?.append(reading)
                }
            }
        }
    }

    func togglePlay() {
        if store.state.activeSession.isPlaying { sessionPause() }
        else { sessionPlay() }
    }

    func sessionPlay() {
        heart.start()
        step.start()
        location.start()
        store.state.activeSession.isPlaying = true
    }

    func sessionPause() {
        heart.stop()
        step.stop()
        location.stop()
        store.state.activeSession.isPlaying = false
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
