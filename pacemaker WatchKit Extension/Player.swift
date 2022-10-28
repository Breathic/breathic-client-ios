import Foundation
import SwiftUI
import AVFAudio
import MediaPlayer

class Player {
    @ObservedObject private var store: AppStore = .shared

    let coordinator = SessionCoordinator()
    let pedometer = Pedometer()
    var location = Location()
    var heartRate = HeartRate()
    let commandCenter = MPRemoteCommandCenter.shared()
    var isPanningReversed: Bool = true
    var panScale: [Float] = []
    var collections: [[Audio]] = []
    var players: [String: AVAudioPlayer] = [:]

    init() {
        store.state.seeds = getAllSeeds(seedInputs: store.state.seedInputs)
        panScale = getPanScale()
        store.state.sessionLogs = readSessionLogs()
        store.state.sessionLogIds = getSessionLogIds(sessionLogs: store.state.sessionLogs)
        initCommandCenter()
        /*
        let update = Update()
        update.value = 60.0
        update.timestamp = Date()
        
        for (index, _) in Array(1...10).enumerated() {
            let update2 = Update()
            update2.timestamp = update.timestamp.addingTimeInterval(5.0 * Double(index))
            update2.value = update.value + Float(index)
            store.state.averageHeartRatesPerMinute.append(update2)
        }
        */
    }

    func initCommandCenter() {
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

    func initInactivityTimer() {
        store.state.lastDataChangeTime = .now()

        Timer.scheduledTimer(withTimeInterval: DATA_INACTIVITY_S, repeats: true) { timer in
            if self.store.state.lastDataChangeTime.distance(to: .now()).toDouble() > DATA_INACTIVITY_S {
                self.store.state.lastDataChangeTime = .now()
                self.pause()
            }
        }
    }

    func startAudioSession() async {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(
                .playback,
                mode: .default,
                policy: .longFormAudio,
                options: []
            )
            
            try await session.activate()
        }
        catch {
            print(error)
        }
    }

    func startSession() {
        store.state.sessionStartTime = Date()

        if !store.state.isAudioSessionLoaded {
            store.state.isAudioSessionLoaded = true
            Task {
                await startAudioSession()
            }
            loop()

            //if !Platform.isSimulator {
            //    initInactivityTimer()
            //}
            //updateGraph()

            heartRate.start()
            pedometer.start()
            location.start()
            coordinator.start()
        }

        create()
        play()
        let sessionLog = SessionLog()
        store.state.sessionLogs.append(sessionLog)
        store.state.activeSessionId = getSessionLogIds(sessionLogs: [sessionLog])[0]
        writeSessionLogs(sessionLogs: store.state.sessionLogs)
    }

    func stopSession() {
        pause()
        store.state.activeSessionId = ""
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
            print(error)
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

    func setChannels(collectionIndex: Int, audioIndex: Int) {
        collections[collectionIndex][audioIndex].channels = []

        for seed in store.state.seeds {
            let samples: [String] = seed.rhythms[store.state.queueIndex].samples
            var channel: [String] = []

            for sample in samples {
                channel.append(sample)
            }

            collections[collectionIndex][audioIndex].channels.append(channel)
        }
    }

    func getPlayerId(channelIndex: Int, forResource: String) -> String {
        return String(channelIndex) + forResource
    }

    func setPlayer(
        collectionIndex: Int,
        audioIndex: Int,
        channelIndex: Int,
        sampleIndex: Int
    ) {
        let channel = collections[collectionIndex][audioIndex].channels[channelIndex]
        let forResource = channel[sampleIndex]
        let pansScaleIndex = !isPanningReversed
            ? sampleIndex
            : panScale.count - 1 - sampleIndex
        let hasResources: Bool = forResource.count > 0

        if hasResources {
            let playerId = getPlayerId(channelIndex: channelIndex, forResource: forResource)

            if players[playerId] == nil {
                let player = load(forResource: forResource, withExtension: SAMPLE_EXTENSION)
                player?.prepareToPlay()
                player?.volume = 0
                players[playerId] = player
                collections[collectionIndex][audioIndex].forResources.append(forResource)
            }

            if players[playerId] != nil {
                players[playerId]?.currentTime = 0
                players[playerId]?.pan = panScale[pansScaleIndex]
                players[playerId]?.play()
            }
        }
    }

    func getPanScale() -> [Float] {
        let easingCount: Int = 8
        var easing: Float = 0
        var left: [Float] = []
        var right: [Float] = []

        for (index, _) in Array(1...easingCount).enumerated() {
            easing = Float(index) * 1 / (Float(easingCount) - 1) * 2
            left.append(0 - (1 - easing))
            right.append(easing)
        }

        return left + right
    }

    func incrementSelectedRhythmIndex() {
        store.state.selectedRhythmIndex = store.state.selectedRhythmIndex + 1

        if store.state.selectedRhythmIndex == store.state.selectedRhythms.count {
            store.state.selectedRhythmIndex = 0
        }
    }

    func getLoopInterval(selectedRhythmIndex: Int) -> TimeInterval {
        store.state.selectedRhythms = [store.state.selectedInRhythm, store.state.selectedOutRhythm]
        let metricType = store.state.metricTypes[store.state.selectedMetricTypeIndex]
        let pace = store.state.valueByMetric(metric: metricType.metric)
        let isReversed = metricType.isReversed
        let selectedRhythm: Double = Double(store.state.selectedRhythms[selectedRhythmIndex]) / 10

        var loopInterval: TimeInterval = isReversed ? selectedRhythm / 1 / Double(pace) : selectedRhythm / Double(pace)
        loopInterval = loopInterval / Double(DOWN_SCALE)
        loopInterval = loopInterval <= 0 ? 1 : loopInterval

        return loopInterval
    }

    func getLoopIntervalSum() -> TimeInterval {
        let loopIntervalSum: TimeInterval = store.state.selectedRhythms.enumerated()
            .map { (index, _) in
                return getLoopInterval(selectedRhythmIndex: index)
            }
            .reduce(0, +)

        return loopIntervalSum
    }

    func fade(collectionIndex: Int, channelIndex: Int, channelCount: Int) {
        let selectedVolume = Float(store.state.selectedVolume)
        let upscaledFadeDuration = FADE_DURATION * DOWN_SCALE
        let index = collections[collectionIndex][0].channelRepeatIndex * collections[collectionIndex][0].channels[channelIndex].count + collections[collectionIndex][0].sampleIndex

        if index >= upscaledFadeDuration {
            if index % DOWN_SCALE == 0 {
                let minFadeRange = Float(0)
                let maxFadeRange = Float(1000)
                let fadeUp = convertRange(
                    value: Float(index),
                    oldRange: [Float(upscaledFadeDuration), Float(CHANNEL_REPEAT_COUNT * DOWN_SCALE)],
                    newRange: [minFadeRange, maxFadeRange]
                )
                var positiveVolume = selectedVolume / fadeUp
                var negativeVolume = selectedVolume / (maxFadeRange - fadeUp)

                positiveVolume = positiveVolume > selectedVolume / 100 ? selectedVolume / 100 : positiveVolume
                negativeVolume = negativeVolume > selectedVolume / 100 ? selectedVolume / 100 : negativeVolume

                if fadeUp >= minFadeRange && fadeUp <= maxFadeRange {
                    for forResource in collections[collectionIndex][0].forResources {
                        let playerId = getPlayerId(
                            channelIndex: channelIndex,
                            forResource: forResource
                        )
                        players[playerId]?.volume = positiveVolume
                    }

                    for forResource in collections[collectionIndex][1].forResources {
                        let playerId = getPlayerId(
                            channelIndex: channelIndex,
                            forResource: forResource
                        )

                        players[playerId]?.volume = negativeVolume
                    }

                    if fadeUp == minFadeRange {
                        pick(collectionIndex: collectionIndex, audioIndex: 1, regenerate: false)
                        collections[collectionIndex][1].channelRepeatIndex = 0
                    }

                    if fadeUp == maxFadeRange {
                        collections[collectionIndex] = collections[collectionIndex].reversed()
                    }
                }
            }
        }
    }

    func getUpdate(timestamp: Date, value: Float) -> Update {
        let update = Update()
        update.timestamp = timestamp
        update.value = value
        return update
    }

    func loopedPlay(loopInterval: TimeInterval) {
        for (collectionIndex, collection) in collections.enumerated() {
            for (audioIndex, audio) in collection.enumerated() {
                for (channelIndex, channel) in audio.channels.enumerated() {
                    if collectionIndex == 0 && audioIndex == 0 && channelIndex == 0 && (
                        audio.sampleIndex == 0 || audio.sampleIndex == DOWN_SCALE - 1) {
                        isPanningReversed = !isPanningReversed
                        incrementSelectedRhythmIndex()
                    }

                    if channel[audio.sampleIndex] != "" {
                        setPlayer(
                            collectionIndex: collectionIndex,
                            audioIndex: audioIndex,
                            channelIndex: channelIndex,
                            sampleIndex: audio.sampleIndex
                        )

                        fade(
                            collectionIndex: collectionIndex,
                            channelIndex: channelIndex,
                            channelCount: channel.count * CHANNEL_REPEAT_COUNT
                        )
                    }

                    if channelIndex == audio.channels.count - 1 {
                        audio.sampleIndex = audio.sampleIndex + 1
                    }

                    if audio.sampleIndex == channel.count {
                        audio.channelRepeatIndex = audio.channelRepeatIndex + 1
                        audio.sampleIndex = 0
                    }
                }
            }
        }
    }

    func updateGraph() {
        Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { timer in
            let loopInterval = self.getLoopIntervalSum()

            if !loopInterval.isInfinite {
                let timestamp = Date()

                self.store.state.updates["breath"]?.append(
                    self.getUpdate(
                        timestamp: timestamp,
                        value: Float(loopInterval) * Float(DOWN_SCALE)
                    )
                )
                self.store.state.updates["heart"]?.append(
                    self.getUpdate(
                        timestamp: timestamp,
                        value: self.store.state.heartRateMetric
                    )
                )
                self.store.state.updates["step"]?.append(
                    self.getUpdate(
                        timestamp: timestamp,
                        value: self.store.state.stepMetric
                    )
                )
                self.store.state.updates["speed"]?.append(
                    self.getUpdate(
                        timestamp: timestamp,
                        value: self.store.state.speedMetric
                    )
                )
            }
        }
    }

    func loop() {
        store.state.breathRateMetric = 1 / Float(getLoopIntervalSum()) / Float(DOWN_SCALE)
        store.state.sessionElapsedTime = getElapsedTime(from: store.state.sessionStartTime, to: Date())

        let loopInterval: TimeInterval = getLoopInterval(selectedRhythmIndex: store.state.selectedRhythmIndex)
        if !loopInterval.isInfinite {
            Timer.scheduledTimer(withTimeInterval: loopInterval, repeats: false) { timer in
                if self.store.state.isAudioPlaying {
                    self.loopedPlay(loopInterval: loopInterval)
                }

                self.loop()
            }
        }
        else {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { timer in
                self.loop()
            }
        }
    }

    func togglePlay() {
        store.state.isAudioPlaying ? pause() : play()
    }

    func setPlayerIndex() {
        store.state.playerIndex = store.state.playerIndex + 1
    }

    func create() {
        flushAll()
        collections = []
        let audio = Audio(
            channelRepeatIndex: FADE_DURATION / 2,
            sampleIndex: 0,
            channels: [],
            forResources: []
        )
        let audio2 = audio.copy() as! Audio
        audio2.channelRepeatIndex = 0
        let audios: [Audio] = [audio, audio2]
        collections.append(audios)
        setChannels(collectionIndex: collections.count - 1, audioIndex: 0)
        setChannels(collectionIndex: collections.count - 1, audioIndex: 1)
    }

    func play() {
        store.state.isAudioPlaying = true
    }

    func pause() {
        store.state.isAudioPlaying = false

        for collection in collections {
            for audio in collection {
                audio.forResources.forEach {
                    players[$0]?.pause()
                }
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

    func flushAll() {
        for (collectionIndex, collection) in collections.enumerated() {
            for (audioIndex, _) in collection.enumerated() {
                flush(collectionIndex: collectionIndex, audioIndex: audioIndex)
                pick(collectionIndex: collectionIndex, audioIndex: audioIndex, regenerate: true)
            }
        }

        players = [:]
    }

    func flush(collectionIndex: Int, audioIndex: Int) {
        collections[collectionIndex][audioIndex].channelRepeatIndex = 0
        collections[collectionIndex][audioIndex].sampleIndex = 0
        collections[collectionIndex][audioIndex].forResources.forEach {
            players[$0]?.stop()
            players[$0] = nil
        }
        collections[collectionIndex][audioIndex].forResources = []
    }

    func incrementQueueIndex() {
        store.state.queueIndex = store.state.queueIndex + 1

        if store.state.queueIndex == store.state.distances.count {
            store.state.queueIndex = 0
        }
    }

    func pick(collectionIndex: Int, audioIndex: Int, regenerate: Bool) {
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

            flush(collectionIndex: collectionIndex, audioIndex: audioIndex)
        }
        else {
            incrementQueueIndex()
        }

        setChannels(collectionIndex: collectionIndex, audioIndex: audioIndex)
        play()
    }
}
