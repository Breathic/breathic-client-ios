import Foundation
import SwiftUI
import AVFAudio
import Easing

class Player {
    @ObservedObject private var store: AppStore = .shared
    
    let coordinator = SessionCoordinator()
    let pedometer = Pedometer()
    //var location = Location()
    var heartRate = HeartRate()
    var isPanningReversed: Bool = true
    var panScaleLeft: [Float] = []
    var panScaleRight: [Float] = []
    var audios: [Audio] = []
    
    init() {
        store.state.seeds = getAllSeeds(seedInputs: store.state.seedInputs)
        //UserDefaults.standard.set("", forKey: "likes")
        store.state.likes = getLikes()
        store.state.likesIds = parseLikes(likes: store.state.likes)
        
        for (audioIndex, _) in audios.enumerated() {
            flush(audioIndex: audioIndex)
            next(audioIndex: audioIndex)
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
            seed.isPanning = seedInput.isPanning
            seeds.append(seed)
        }
        
        return seeds
    }
    
    func setChannels(audioIndex: Int) {
        audios[audioIndex].channels = []

        for seed in store.state.seeds {
            let samples: [String] = seed.rhythms[0].samples
            var channel: [String] = []

            for sample in samples {
                channel.append(sample)
            }

            audios[audioIndex].channels.append(channel)
        }
    }
    
    func setPlayer(audioIndex: Int, channelIndex: Int, sampleIndex: Int) {
        let channel = audios[audioIndex].channels[channelIndex]
        let forResource = channel[sampleIndex]

        if forResource.count > 0 {
            if audios[audioIndex].playerLabels[forResource] == nil {
                let player = load(forResource: forResource, withExtension: SAMPLE_EXTENSION)
                player?.prepareToPlay()
                player?.volume = 0
                audios[audioIndex].playerLabels[forResource] = player
            }

            if audios[audioIndex].playerLabels[forResource] != nil {
                audios[audioIndex].players.insert(audios[audioIndex].playerLabels[forResource]!, at: channelIndex)
                audios[audioIndex].players[channelIndex]?.currentTime = 0
                audios[audioIndex].players[channelIndex]?.play()
            }
        }
    }

    func ease(loopInterval: TimeInterval, channelIndex: Int) {
        if panScaleLeft.count == 0 || panScaleRight.count == 0 {
            let easingCount: Int = 8
            var easing: Float = 0.001
            var left: [Float] = []
            var right: [Float] = []

            for _ in Array(0...easingCount) {
                easing = Curve.exponential.easeOut(easing)
                left.append(0 - (1 - easing))
                right.append(easing)
            }

            let panScale: [Float] = left + right
            panScaleLeft = panScale
            panScaleRight = panScale.reversed()
        }

        let panScale = isPanningReversed ? panScaleRight : panScaleLeft

        var timerIndex = 0
        Timer.scheduledTimer(withTimeInterval: loopInterval, repeats: true) { timer in
            for (audioIndex, audio) in self.audios.enumerated() {
                if self.audios[audioIndex].players.count > 0 {
                    audio.players[channelIndex]?.pan = panScale[timerIndex]
                }

                timerIndex = timerIndex + 1

                if timerIndex == panScale.count {
                    timer.invalidate()
                }
            }
        }
    }

    func getLoopInterval() -> TimeInterval {
        let pace = store.state.valueByKey(key: store.state.rhythmTypes[store.state.selectedRhythmTypeIndex].key)
        let selectedRhythms: [Int] = [store.state.selectedInRhythm, store.state.selectedOutRhythm]
        let selectedRhythm: Int = selectedRhythms[store.state.selectedRhythmIndex]

        store.state.selectedRhythmIndex = store.state.selectedRhythmIndex + 1
        if store.state.selectedRhythmIndex == selectedRhythms.count {
            store.state.selectedRhythmIndex = 0
        }

        var loopInterval: TimeInterval = Double(selectedRhythm) / pace / 10
        loopInterval = loopInterval / Double(DOWN_SCALE)
        loopInterval = loopInterval > 0 ? loopInterval : 1

        return loopInterval
    }

    func convertRange(value: Int, oldRange: [Int], newRange: [Int]) -> Int {
       return ((value - oldRange[0]) * (newRange[1] - newRange[0])) / (oldRange[1] - oldRange[0]) + newRange[0];
     }

    func fade(channelCount: Int) {
        let selectedVolume = Float(store.state.selectedVolume)
        let upscaledFadeDuration = FADE_DURATION * DOWN_SCALE

        if audios[0].sampleIndex >= channelCount - upscaledFadeDuration {
            if audios[0].sampleIndex % DOWN_SCALE == 0 {
                let minFadeRange = Float(0)
                let maxFadeRange = Float(1000)
                let fadeUp = Float(convertRange(
                    value: audios[0].sampleIndex,
                    oldRange: [upscaledFadeDuration, channelCount - DOWN_SCALE],
                    newRange: [Int(minFadeRange), Int(maxFadeRange)]
                ))
                var positiveVolume = selectedVolume / fadeUp
                var negativeVolume = selectedVolume / (maxFadeRange - fadeUp)

                positiveVolume = positiveVolume > selectedVolume / 100 ? selectedVolume / 100 : positiveVolume
                negativeVolume = negativeVolume > selectedVolume / 100 ? selectedVolume / 100 : negativeVolume

                if fadeUp == minFadeRange {
                    next(audioIndex: 1)
                    audios[1].sampleIndex = 0
                }

                if fadeUp >= minFadeRange && fadeUp <= maxFadeRange {
                    for player in audios[0].players {
                        if audios[0].sampleIndex > -1 {
                            player?.volume = positiveVolume
                        }
                    }

                    for player in audios[1].players {
                        if audios[1].sampleIndex > -1 {
                            player?.volume = negativeVolume
                        }
                    }
                }

                if fadeUp == maxFadeRange {
                    audios = audios.reversed()
                }
            }
        }
    }

    func loopedPlay(loopInterval: TimeInterval) {
        for (audioIndex, audio) in self.audios.enumerated() {
            for (channelIndex, channel) in audio.channels.enumerated() {
                if channel.count - 1 >= audio.sampleIndex && audio.sampleIndex > -1 && channel[audio.sampleIndex] != "" {
                    self.setPlayer(
                        audioIndex: audioIndex,
                        channelIndex: channelIndex,
                        sampleIndex: audio.sampleIndex
                    )

                    if audioIndex == 0 && channelIndex == 0 {
                        self.isPanningReversed = !self.isPanningReversed
                    }

                    fade(channelCount: channel.count)

                    if self.store.state.seeds[channelIndex].isPanning {
                        self.ease(loopInterval: loopInterval, channelIndex: channelIndex)
                    }
                }

                if channelIndex == audio.channels.count - 1 && audio.sampleIndex > -1 {
                    audio.sampleIndex = audio.sampleIndex + 1
                }
            }
        }
    }

    func loop() {
        let loopInterval: TimeInterval = getLoopInterval()

        Timer.scheduledTimer(withTimeInterval: loopInterval, repeats: false) { timer in
            if self.store.state.isAudioPlaying {
                self.loopedPlay(loopInterval: loopInterval)
            }

            self.loop()
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
        let firstAudio = Audio(
            sampleIndex: FADE_DURATION * DOWN_SCALE,
            channels: [],
            playerLabels: [:],
            players: []
        )
        audios.append(firstAudio)
        let secondAudio = audios[0].copy() as! Audio
        secondAudio.sampleIndex = 0
        audios = [firstAudio, secondAudio]
        setChannels(audioIndex: 0)
        setChannels(audioIndex: 1)
    }

    func play() {
        if !store.state.isAudioSessionLoaded {
            store.state.isAudioSessionLoaded = true
            Task {
                await startAudioSession()
            }
            coordinator.start()
            pedometer.start()
            heartRate.start()
            //location.start()
            create()
            loop()
        }

        store.state.isAudioPlaying = true
    }

    func pause() {
        store.state.isAudioPlaying = false

        for audio in audios {
            for player in audio.players {
                player?.pause()
            }
        }
    }

    func flush(audioIndex: Int) {
        let audio = audios[audioIndex]
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

    func next(audioIndex: Int) {
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

        flush(audioIndex: audioIndex)
        setChannels(audioIndex: audioIndex)
        play()
    }
}
