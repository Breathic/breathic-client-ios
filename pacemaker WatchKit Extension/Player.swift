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
    
    init() {
        store.state.seeds = getAllSeeds(seedInputs: store.state.seedInputs)
        panScale = getPanScale()
        //UserDefaults.standard.set("", forKey: "likes")
        store.state.likes = getLikes()
        store.state.likesIds = parseLikes(likes: store.state.likes)

        for (collectionIndex, collection) in collections.enumerated() {
            for (audioIndex, _) in collection.enumerated() {
                flush(collectionIndex: collectionIndex, audioIndex: audioIndex)
                pick(collectionIndex: collectionIndex, audioIndex: audioIndex)
            }
        }

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
            self.next()
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
        let durationRange = seedInput.durationRange
        let interval = seedInput.interval
        let sampleDir = "/" + SAMPLE_PATH
        let rhythm = Rhythm()
        rhythm.id = Int(sample.split(separator: ".")[0])!
        rhythm.durationRange = durationRange
        
        for space in interval {
            rhythm.samples.append(space > 0 ? sampleDir + "/" + sample : "")
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
            let samples: [String] = seed.rhythms[0].samples
            var channel: [String] = []

            for sample in samples {
                channel.append(sample)
            }

            collections[collectionIndex][audioIndex].channels.append(channel)
        }
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

        if forResource.count > 0 {
            if collections[collectionIndex][audioIndex].playerLabels[forResource] == nil {
                let player = load(forResource: forResource, withExtension: SAMPLE_EXTENSION)
                player?.prepareToPlay()
                player?.volume = 0
                collections[collectionIndex][audioIndex].playerLabels[forResource] = player
            }

            if collections[collectionIndex][audioIndex].playerLabels[forResource] != nil {
                // Fill previously unfilled channel.
                while collections[collectionIndex][audioIndex].players.count < channelIndex {
                    collections[collectionIndex][audioIndex].players.append(nil)
                }

                collections[collectionIndex][audioIndex].players.insert(collections[collectionIndex][audioIndex].playerLabels[forResource], at: channelIndex)
                collections[collectionIndex][audioIndex].players[channelIndex]?.currentTime = 0
                collections[collectionIndex][audioIndex].players[channelIndex]?.pan = panScale[pansScaleIndex]
                collections[collectionIndex][audioIndex].players[channelIndex]?.play()
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

    func getLoopInterval() -> TimeInterval {
        let metricType = store.state.metricTypes[store.state.selectedMetricTypeIndex]
        let pace = store.state.valueByMetric(metric: metricType.metric)
        let isReversed = metricType.isReversed
        let selectedRhythms: [Int] = [store.state.selectedInRhythm, store.state.selectedOutRhythm]
        let selectedRhythm: Double = Double(selectedRhythms[store.state.selectedRhythmIndex]) / 10

        store.state.selectedRhythmIndex = store.state.selectedRhythmIndex + 1
        if store.state.selectedRhythmIndex == selectedRhythms.count {
            store.state.selectedRhythmIndex = 0
        }

        var loopInterval: TimeInterval = isReversed ? selectedRhythm / 1 / Double(pace) : selectedRhythm / Double(pace)
        loopInterval = loopInterval / Double(DOWN_SCALE)
        loopInterval = loopInterval <= 0 ? 1 : loopInterval

        return loopInterval
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
                    for player in collections[collectionIndex][0].players {
                        player?.volume = positiveVolume
                    }

                    for player in collections[collectionIndex][1].players {
                        player?.volume = negativeVolume
                    }

                    if fadeUp == minFadeRange {
                        pick(collectionIndex: collectionIndex, audioIndex: 1)
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

                        let timestamp = Date()

                        store.state.updates["breath"]?.append(
                            getUpdate(
                                timestamp: timestamp,
                                value: Float(loopInterval) * Float(DOWN_SCALE)
                            )
                        )
                        store.state.updates["heartRate"]?.append(
                            getUpdate(
                                timestamp: timestamp,
                                value: store.state.heartRateMetric
                            )
                        )
                        store.state.updates["step"]?.append(
                            getUpdate(
                                timestamp: timestamp,
                                value: store.state.stepMetric
                            )
                        )
                        store.state.updates["speed"]?.append(
                            getUpdate(
                                timestamp: timestamp,
                                value: store.state.speedMetric
                            )
                        )
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

    func loop() {
        let loopInterval: TimeInterval = getLoopInterval()

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

    func setLikedPlay(playerIndex: Int) {
        if store.state.likes.count >= playerIndex {
            store.state.seeds = store.state.likes[playerIndex]
        }
    }

    func setLikes(likes: [[Seed]]) {
        let data = try! JSONEncoder().encode(likes)
        let json = String(data: data, encoding: .utf8) ?? ""
        UserDefaults.standard.set(json, forKey: "likes")
    }

    func getLikes() -> [[Seed]] {
        do {
            let outData = UserDefaults.standard.string(forKey: "likes") ?? ""
            let jsonData = outData.data(using: .utf8)!
            return try JSONDecoder().decode([[Seed]].self, from: jsonData)
        }
        catch {
            return []
        }
    }

    func setPlayerIndex() {
        if store.state.playerIndex + 1 == store.state.likes.count {
            store.state.playerIndex = 0
        }
        else {
            store.state.playerIndex = store.state.playerIndex + 1
        }

        setLikedPlay(playerIndex: store.state.playerIndex)
    }

    func parseLikes(likes: [[Seed]]) -> [String] {
        var res: [String] = []

        likes
            .forEach {
                var track: [String] = []
                
                $0.forEach {
                    $0.rhythms.forEach {
                        $0.samples.forEach {
                            if $0 != "" {
                                let partial = String($0.split(separator: "/")[2])
                                let id = String(partial.split(separator: ".")[0])
                                
                                if !track.contains(id) {
                                    track.append(id)
                                }
                            }
                        }
                    }
                }

                res.append(track.joined(separator: "."))
            }

        return res
    }

    func like() {
        var likes: [[Seed]] = getLikes()
        var like: [Seed] = []
        
        for seed in store.state.seeds {
            let tempSeed = seed
            tempSeed.rhythms = [seed.rhythms[0]]
            like.append(tempSeed)
        }

        likes.append(like)
        setLikes(likes: likes)
        store.state.likes = likes
        store.state.likesIds = parseLikes(likes: likes)
    }

    func create() {
        collections = []
        let audio = Audio(
            channelRepeatIndex: FADE_DURATION / 2,
            sampleIndex: 0,
            channels: [],
            playerLabels: [:],
            players: []
        )
        let audio2 = audio.copy() as! Audio
        audio2.channelRepeatIndex = 0
        let audios: [Audio] = [audio, audio2]
        collections.append(audios)
        setChannels(collectionIndex: collections.count - 1, audioIndex: 0)
        setChannels(collectionIndex: collections.count - 1, audioIndex: 1)
    }

    func play() {
        if !store.state.isAudioSessionLoaded {
            store.state.isAudioSessionLoaded = true
            Task {
                await startAudioSession()
            }
            //location.start()
            create()
            loop()
            initInactivityTimer()
        }

        coordinator.start()
        heartRate.start()
        pedometer.start()
        location.start()

        store.state.isAudioPlaying = true
    }

    func pause() {
        next()
        store.state.isAudioPlaying = false

        for collection in collections {
            for audio in collection {
                for player in audio.players {
                    player?.pause()
                }
            }
        }

        heartRate.stop()
        pedometer.stop()
        location.stop()
    }

    func next() {
        play()
        var channels: [Seed] = []
        for channel in store.state.seeds {
            channel.rhythms = channel.rhythms.shuffled()
            channels.append(channel)
        }
        store.state.seeds = channels
        create()
    }

    func flush(collectionIndex: Int, audioIndex: Int) {
        let audio = collections[collectionIndex][audioIndex]
        for player in audio.players {
            player?.stop()
        }

        audio.playerLabels = [:]
        audio.players = []
        audio.sampleIndex = 0

        for _ in store.state.seeds {
            audio.players.append(nil)
        }
    }

    func pick(collectionIndex: Int, audioIndex: Int) {
        for (channelIndex, _) in store.state.seeds.enumerated() {
            let lastRhythm = store.state.seeds[channelIndex].rhythms[0]
            store.state.history.append(lastRhythm.id)
            let distances: [Distance] = store.state.distances[lastRhythm.id] ?? []
            var summary: [Int: Double] = [:]

            for distance in distances {
                let nextDistances: [Distance] = (store.state.distances[distance.rightId] ?? [])
                    .filter { $0.duration > lastRhythm.durationRange[0] && $0.duration < lastRhythm.durationRange[1] }

                for nextDistance in nextDistances {
                    summary[nextDistance.rightId] = distance.value + nextDistance.value
                }
            }

            let sortedSummary = summary
                .filter { !store.state.history.contains($0.key) }
                .sorted { Double($0.value) < Double($1.value) }

            if sortedSummary.count == 0 {
                let element = store.state.seeds[channelIndex].rhythms
                    .remove(at: 0)
                store.state.seeds[channelIndex].rhythms.append(element)
            }
            else {
                let index = store.state.seeds[channelIndex].rhythms
                    .firstIndex(where: {$0.id == sortedSummary[0].key}) ?? 0
                let element = store.state.seeds[channelIndex].rhythms
                    .remove(at: index)
                store.state.seeds[channelIndex].rhythms
                    .insert(element, at: 0)
                print(sortedSummary[0].value)
            }
        }

        flush(collectionIndex: collectionIndex, audioIndex: audioIndex)
        setChannels(collectionIndex: collectionIndex, audioIndex: audioIndex)
        play()
    }
}
