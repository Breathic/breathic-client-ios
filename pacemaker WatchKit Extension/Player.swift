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
    var channels: [[String]] = []
    var playerLabels: [String: AVAudioPlayer] = [:]
    var players: [AVAudioPlayer?] = []
    var isPanningReversed: Bool = true
    var panScaleLeft: [Float] = []
    var panScaleRight: [Float] = []
    var tracks: [Track] = []
    
    init() {
        flush()
        store.state.seeds = getAllSeeds(seedInputs: store.state.seedInputs)
        //UserDefaults.standard.set("", forKey: "likes")
        store.state.likes = getLikes()
        store.state.likesIds = parseLikes(likes: store.state.likes)
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
    
    func setChannels() {
        channels = []

        for seed in store.state.seeds {
            let samples: [String] = seed.rhythms[0].samples
            var channel: [String] = []

            for sample in samples {
                channel.append(sample)
            }

            channels.append(channel)
        }

        //let track = Track()
        //track.channels = channels
        //self.tracks.append(track)
    }
    
    func setPlayer(channelIndex: Int, sampleIndex: Int) {
        let channel = channels[channelIndex]
        let forResource = channel[sampleIndex]
        
        if forResource.count > 0 {
            if playerLabels[forResource] == nil {
                let player = load(forResource: forResource, withExtension: SAMPLE_EXTENSION)
                player?.prepareToPlay()
                player?.volume = Float(store.state.selectedVolume) / 10
                playerLabels[forResource] = player
            }
            
            if playerLabels[forResource] != nil {
                players.insert(playerLabels[forResource]!, at: channelIndex)
                players[channelIndex]?.currentTime = 0
                players[channelIndex]?.play()
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
            self.players[channelIndex]?.pan = panScale[timerIndex]
            
            timerIndex = timerIndex + 1
            
            if timerIndex == panScale.count {
                timer.invalidate()
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
        loopInterval = loopInterval / 8
        loopInterval = loopInterval > 0 ? loopInterval : 1

        return loopInterval
    }

    func loopedPlay(loopInterval: TimeInterval) {
        for (channelIndex, channel) in self.channels.enumerated() {
            if channel.count - 1 >= self.store.state.currentSampleIndex && channel[self.store.state.currentSampleIndex] != "" {
                if channelIndex == 0 {
                    self.isPanningReversed = !self.isPanningReversed
                }

                self.setPlayer(channelIndex: channelIndex, sampleIndex: self.store.state.currentSampleIndex)

                if self.store.state.seeds[channelIndex].isPanning {
                    self.ease(loopInterval: loopInterval, channelIndex: channelIndex)
                }
            }

            if channelIndex == self.channels.count - 1 {
                self.store.state.currentSampleIndex = self.store.state.currentSampleIndex + 1
            }

            if self.store.state.currentSampleIndex == channel.count - 1 {
                self.next()
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
    
    func setVolume(volume: Float) {
        for player in players {
            player?.volume = volume / 10
        }
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
            loop()
            setChannels()
        }

        store.state.isAudioPlaying = true
    }

    func pause() {
        store.state.isAudioPlaying = false

        for player in players {
            player?.pause()
        }
    }

    func stop() {
        for player in players {
            player?.stop()
        }
    }

    func flush() {
        stop()
        playerLabels = [:]
        players = []
        for _ in store.state.seeds {
            players.append(nil)
        }
        store.state.currentSampleIndex = 0
    }

    func next() {
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

        flush()
        setChannels()
        play()
    }
}
