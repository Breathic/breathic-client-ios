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
    var audios: [Audio] = []
    var players: [String: AVAudioPlayer] = [:]
    var coordinator = WKExtendedRuntimeSession()
    
    init() {
        /*
         SentrySDK.start { options in
         options.dsn = SENTRY_DSN
         options.debug = true
         options.tracesSampleRate = 1.0
         }
         */
        Task {
            store.state.deviceToken = await generateToken()
        }
        store.state.setMetricValuesToDefault()
        store.state.instruments = listInstruments(DISTANCE_PATH)
        store.state.channels = getChannelsFromSequences(SEQUENCES)
        fadeScale = getFadeScale()
        store.state.sessions = readSessions()
        store.state.activeSession = readActiveSession()
        store.state.isTermsApproved = readBoolean(name: TERMS_APPROVAL_NAME)
        store.state.isGuideSeen = readBoolean(name: GUIDE_SEEN_NAME)
        store.state.activeSession.isPlaying = false
        initIntervals()
        startElapsedTimer()
        cachePlayers()
        sync(store.state.sessions.shuffled())
        loop()
        create()
        //pick(audioIndex: 0)
        print(API_URL)
    }
    
    func initIntervals() {
        Timer.scheduledTimer(withTimeInterval: TIMESERIES_SAVER_INTERVAL_SECONDLY, repeats: true) { timer in
            if self.store.state.activeSession.isPlaying {
                self.saveReadings(TimeUnit.Second)
            }
        }
        
        Timer.scheduledTimer(withTimeInterval: TIMESERIES_SAVER_INTERVAL_MINUTELY, repeats: true) { timer in
            if self.store.state.activeSession.isPlaying {
                self.saveReadings(TimeUnit.Minute)
            }
        }
        
        Timer.scheduledTimer(withTimeInterval: SYNC_INTERVAL_S, repeats: true) { timer in
            self.sync(self.store.state.sessions.shuffled())
        }
    }
    
    func sync(_ sessions: [Session]) {
        func _update(session: Session, status: SyncStatus) {
            session.syncStatus = status
            saveSession(session)
            store.state.sessions = readSessions()
        }
        
        if store.state.isSyncInProgress {
            return
        }
        
        store.state.isSyncInProgress = true
        
        Task {
            let sessions = sessions.filter { session in
                if session.endTime != nil && session.syncStatus != SyncStatus.Synced {
                    return true
                }
                
                return false
            }
            
            if sessions.count > 0 {
                let session = sessions[0]
                
                do {
                    _update(session: session, status: SyncStatus.Syncing)
                    
                    let success = try await uploadSession(
                        session: session,
                        deviceToken: store.state.deviceToken
                    )
                    
                    if success {
                        _update(session: session, status: SyncStatus.Synced)
                    }
                    else {
                        _update(session: session, status: SyncStatus.Syncable)
                    }
                }
                catch {
                    print("sync()", error)
                    _update(session: session, status: SyncStatus.Syncable)
                }
            }
            
            store.state.isSyncInProgress = false
        }
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
    
    func startElapsedTimer() {
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if self.store.state.activeSession.isPlaying {
                self.store.state.activeSession.elapsedSeconds = self.store.state.activeSession.elapsedSeconds + 1
            }
        }
    }
    
    func load(_ resource: String) -> AVAudioPlayer? {
        do {
            guard let url: URL = Bundle.main.url(
                forResource: resource,
                withExtension: nil
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
        sampleIndex: Int,
        isBreathingChannel: Bool
    ) {
        let channel = audios[audioIndex].samples[sampleIndex]
        
        let breathType = sampleIndex == 0
            ? isPanningReversed
                ? "-" + Breathe.BreatheIn.rawValue
                : "-" + Breathe.BreatheOut.rawValue
            : ""
        
        let separator = "." + SAMPLE_EXTENSION
        let resource = String(channel[sampleIndex].split(separator: separator)[0]) + breathType + separator
        if Platform.isSimulator {
            print(resource)
        }
        let hasResources: Bool = resource.count > 0
        if hasResources {
            let playerId = resource
            
            players[playerId]?.currentTime = 0
            let fade = audios[audioIndex].fadeIndex > -1
            ? fadeScale[audios[audioIndex].fadeIndex]
            : 0
            
            var volume = store.state.activeSession.volume / 100 * Float(fade)
            if !isBreathingChannel {
                volume = volume * MUSIC_VOLUME_PCT
            }
            
            players[playerId]?.volume = volume
            players[playerId]?.play()
            players[playerId]?.numberOfLoops = isBreathingChannel
                ? 0
                : -1
            
            let sampleId = channel[sampleIndex]
                .split(separator: "-")[0]
                .split(separator: ".")[0]
            store.state.setMetricValue("sample-id", Float(sampleId)!)
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
            for (sampleIndex, sample) in audio.samples.enumerated() {
                let isAudioHaptic = FEEDBACK_MODES[store.state.activeSession.feedbackModeIndex] == Feedback.AudioHaptic
                let isAudio = isAudioHaptic || FEEDBACK_MODES[store.state.activeSession.feedbackModeIndex] == Feedback.Audio
                let isHaptic = isAudioHaptic || FEEDBACK_MODES[store.state.activeSession.feedbackModeIndex] == Feedback.Haptic
                let isMuted = !(Float(store.state.activeSession.volume) > 0)
                let isBreathingChannel: Bool = sampleIndex == 0
                
                if audioIndex == 0 && isBreathingChannel {
                    incrementSelectedRhythmIndex()
                    isPanningReversed = !isPanningReversed

                    if isHaptic {
                        setHaptic()
                    }
                }

                if sampleIndex == audio.samples.count - 1 {
                    audio.sampleIndex = audio.sampleIndex + 1
                }

                if audio.sampleIndex == sample.count {
                    audio.sampleIndex = 0
                }

                audio.fadeIndex = audio.fadeIndex + 1

                let islastQuarter = audio.fadeIndex == FADE_DURATION * 3 - 1
                if islastQuarter {
                    pick(audioIndex: 1)
                    audios[1].fadeIndex = 0
                }

                let isTransitioning = audio.fadeIndex == CHANNEL_REPEAT_COUNT
                if isTransitioning {
                    audios[0].fadeIndex = -FADE_DURATION * 2 + 1
                    audios = audios.reversed()
                }

                if !isMuted && isAudio && sample[audio.sampleIndex] != "" {
                    setAudio(
                        audioIndex: audioIndex,
                        sampleIndex: sampleIndex,
                        isBreathingChannel: isBreathingChannel
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
        
        store.state.setMetricValue("breath", 1 / Float(loopIntervalSum) / Float(DOWN_SCALE) * 60)
        
        ACTIVITIES[store.state.activeSession.activityIndex].presets[store.state.activeSession.presetIndex].breathingTypes.forEach {
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
    
    func start() {
        store.state.setMetricValuesToDefault()
        putToBackground(store: store)
        playAudio()
        store.state.activeSession.start()
        sessionPlay()
        store.state.render()
    }
    
    func stop() {
        pause()
        saveReadings(TimeUnit.Second)
        saveReadings(TimeUnit.Minute)
        store.state.setMetricValuesToDefault()
        sessionPause()
        store.state.activeSession.stop()
        store.state.activeSession.distance = getDistance(store.state.activeSession)
        store.state.sessions.append(store.state.activeSession)
        store.state.activeSession = store.state.activeSession.copy()
        saveActiveSession(store.state.activeSession)
        coordinator.invalidate()
        sync([store.state.sessions[store.state.sessions.count - 1]])
        create()
    }
    
    func togglePlay() {
        if store.state.activeSession.isPlaying { sessionPause() }
        else { start() }
    }
    
    func sessionPlay() {
        startReaders()
        store.state.activeSession.isPlaying = true
        store.state.render()
    }
    
    func sessionPause() {
        players.keys.forEach {
            players[$0]?.pause()
        }
        stopReaders()
        store.state.activeSession.isPlaying = false
        store.state.render()
    }
    
    func startReaders() {
        stopReaders()
        heart.start()
        step.start()
        location.start()
    }
    
    func stopReaders() {
        heart.stop()
        step.stop()
        location.stop()
    }
    
    func create() {
        audios = []
        shuffle()
        flushAll()
        
        let audio = Audio(
            fadeIndex: 0,
            sampleIndex: 0,
            samples: [],
            resources: []
        )
        let audio2 = audio.copy() as! Audio
        audio2.fadeIndex = -FADE_DURATION * 3 + 1
        
        audios.append(audio)
        audios.append(audio2)
        
        setSamplesToChannels(audioIndex: 0)
        setSamplesToChannels(audioIndex: 1)
        resetFadeIndexes()
    }
    
    func playAudio() {
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
            audio.resources.forEach {
                players[$0]?.pause()
            }
        }
    }
    
    func putToBackground(store: Store) {
        takeFromBackground()
        coordinator.start()
    }
    
    func takeFromBackground() {
        if coordinator.state == .running {
            coordinator.invalidate()
        }
    }
    
    func shuffle() {
        var channels: [Channel] = []
        for channel in store.state.channels {
            channel.tracks = channel.tracks.shuffled()
            channels.append(channel)
        }
        store.state.channels = channels
    }
    
    func resetFadeIndexes() {
        audios[0].fadeIndex = FADE_DURATION - 1
        audios[1].fadeIndex = -FADE_DURATION * 2 + 1
    }
    
    func flushAll() {
        for (audioIndex, _) in audios.enumerated() {
            flush(audioIndex: audioIndex)
            pick(audioIndex: audioIndex)
        }
    }
    
    func flush(audioIndex: Int) {
        audios[audioIndex].sampleIndex = 0
        audios[audioIndex].resources = []
    }
    
    func cachePlayers() {
        listAllFiles(SAMPLE_PATH)
            .forEach { file in
                let resource = String(
                    file.split(separator: "/")[
                        file.split(separator: "/").count - 1
                    ]
                )
                let player = load(SAMPLE_PATH + "/" + String(resource))
                player?.prepareToPlay()
                players[resource] = player
            }
    }
    
    func setSamplesToChannels(audioIndex: Int) {
        audios[audioIndex].samples = []
        
        for channel in store.state.channels {
            let audioIndexExtra = audioIndex % 2 == 0
                ? 0
                : 1
            audios[audioIndex].samples.append(
                channel.tracks[audioIndexExtra].samples
            )
        }
    }
    
    func getTrack(id: Int, sequence: Sequence) -> Track {
        let track = Track()
        track.id = id
        
        sequence.pattern.forEach {
            track.samples.append(
                $0 > 0
                ? String(id) + "." + SAMPLE_EXTENSION
                : ""
            )
        }
        
        return track
    }
    
    func getChannelsFromSequences(_ sequences: [Sequence]) -> [Channel] {
        var channels: [Channel] = []
        
        for sequence in sequences {
            let channel = Channel()
            channel.tracks = store.state.instruments[sequence.instrument]?.keys.map {
                getTrack(
                    id: Int($0), sequence: sequence
                )
            } ?? []
            
            channels.append(channel)
        }
        
        return channels
    }
    
    func incrementQueueIndex() {
        /*
         store.state.channels = store.state.channels.map { channel in
         channel.queueIndex = channel.queueIndex + 1
         
         if channel.queueIndex == channel.tracks.count - 1 {
         channel.queueIndex = 0
         }
         
         return channel
         }
         */
    }
    
    func getTrackIndex(instrumentIndex: Int, id: Int) -> Int {
        store.state.channels[instrumentIndex].tracks
            .firstIndex(where: { $0.id == id }) ?? 0
    }

    func pick(audioIndex: Int) {
        return
        
        for (instrumentIndex, instrumentKey) in store.state.instruments.keys.enumerated() {
            store.state.channels[instrumentIndex].queueIndex = 0

            let lastTrackIndex = 0
            let lastTrack = store.state.channels[instrumentIndex].tracks[lastTrackIndex]

            store.state.channels[instrumentIndex].tracks.remove(at: lastTrackIndex)

            let distances = store.state.instruments[instrumentKey]?[lastTrack.id] ?? []
            print("store.state.instruments", store.state.instruments)
            print("store.state.instruments[instrumentKey]", store.state.instruments[instrumentKey])

            var summary: [Int: Double] = [:]
            for distance in distances {
                let nextDistances: [Distance] = store.state.instruments[instrumentKey]?[distance.rightId] ?? []

                for nextDistance in nextDistances {
                    summary[nextDistance.rightId] = distance.value + nextDistance.value
                }
            }
            //print(summary)

            summary.removeValue(forKey: lastTrack.id)
  
            let sortedSummary = summary.sorted { $0.1 < $1.1 }
            //print("sortedSummary", sortedSummary)

            // Introduce some randomness to the audio picker.
            let shuffledSummary: [Dictionary<Int, Double>.Element] = Array(sortedSummary[0...3])
                .shuffled()
            print("shuffledSummary", shuffledSummary)
            
            let index = getTrackIndex(instrumentIndex: instrumentIndex, id: shuffledSummary[0].key)
            //print("index", index)

            let element = store.state.channels[instrumentIndex].tracks
                .remove(at: index)
            //print("element.id", element.id)
            
            store.state.channels[instrumentIndex].tracks
                .insert(element, at: 0)
            
            store.state.channels[instrumentIndex].tracks.append(lastTrack)
        }

        flush(audioIndex: audioIndex)
        setSamplesToChannels(audioIndex: audioIndex)
        //playAudio()
    }
}
