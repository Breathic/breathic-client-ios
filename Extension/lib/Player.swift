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
    var instruments: Instruments = [:]
    var channels: [Channel] = []
    var audios: [Audio] = []
    var players: [String: AVAudioPlayer] = [:]
    var coordinator = WKExtendedRuntimeSession()
    var playback: [[Int]] = []
    
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
        instruments = listInstruments(DISTANCE_PATH)
        channels = getChannelsFromSequences(SEQUENCES)
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
                    store.state.isSyncInProgress = false
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
    
    func setAudio(
        sampleId: String,
        playerId: String,
        audioIndex: Int,
        hasSample: Bool,
        isBreathing: Bool
    ) {
        if hasSample {
            players[playerId]?.currentTime = 0
            players[playerId]?.numberOfLoops = isBreathing
                ? 0
                : -1
        }

        let fade = audios[audioIndex].fadeIndex > -1
            ? fadeScale[audios[audioIndex].fadeIndex]
            : 0
        
        var volume = store.state.activeSession.volume / 100
        volume = isBreathing
            ? volume * Float(fade)
            : volume * MUSIC_VOLUME_PCT * Float(fade)
        players[playerId]?.volume = volume

        if volume > 0 {
            players[playerId]?.play()
            store.state.setMetricValue("sample-id", Float(sampleId)!)
            
            if Platform.isSimulator {
                print(audioIndex, playerId, volume)
            }
        }
    }
    
    func updateFeedback() {
        let isMusic = FEEDBACK_MODES[store.state.activeSession.feedbackModeIndex] == Feedback.Music
        let isAudio = isMusic || FEEDBACK_MODES[store.state.activeSession.feedbackModeIndex] == Feedback.Audio
        let isHaptic = FEEDBACK_MODES[store.state.activeSession.feedbackModeIndex] == Feedback.Haptic
        let isMuted = !(Float(store.state.activeSession.volume) > 0)
        
        incrementSelectedRhythmIndex()
        isPanningReversed = !isPanningReversed
        
        if isHaptic {
            setHaptic()
        }

        for (audioIndex, audio) in audios.enumerated() {
            audios[audioIndex].fadeIndex = audio.fadeIndex + 1
            
            let isTransitioning = audio.fadeIndex == CHANNEL_REPEAT_COUNT
            if isTransitioning {
                let isLeftAudio = audioIndex == 0

                if isLeftAudio {
                    pick(audioIndex: 1)
                    resetFadeIndices()
                }
            }
            
            for (sequenceIndex, sequence) in SEQUENCES.enumerated() {
                let isAudible = sequence.isBreathing || isMusic

                if !isMuted && isAudio && isAudible {
                    let sampleId = String(
                        playback[sequenceIndex][
                            playback[sequenceIndex].count - 2 + audioIndex
                        ]
                    )
                    let separator = "." + SAMPLE_EXTENSION
                    let breathType = sequence.isBreathing
                        ? !isPanningReversed
                            ? "-" + Breathe.BreatheIn.rawValue
                            : "-" + Breathe.BreatheOut.rawValue
                        : ""
                    let playerId = sampleId + breathType + separator
                    let isSampleStillPlaying = detectSamplePlayingStatus(
                        sequence: sequence,
                        sampleIndex: audio.sampleIndex
                    )
                    
                    if isSampleStillPlaying {
                        setAudio(
                            sampleId: sampleId,
                            playerId: playerId,
                            audioIndex: audioIndex,
                            hasSample: sequence.pattern[audio.sampleIndex] > 0,
                            isBreathing: sequence.isBreathing
                        )
                    }
                    else {
                        players[playerId]?.pause()
                    }
                }
            }
            
            audios[audioIndex].sampleIndex = audios[audioIndex].sampleIndex + 1
            
            if audio.sampleIndex == CHANNEL_REPEAT_COUNT {
                audios[audioIndex].sampleIndex = 0
            }
        }
    }
    
    func detectSamplePlayingStatus(
        sequence: Sequence,
        sampleIndex: Int
    ) -> Bool {
        var pattern: [Int] = sequence.pattern.reversed()
        let sampleArray = Array(0...sampleIndex)
        
        sampleArray.forEach { _ in
            let last = pattern.removeLast()
            pattern.insert(last, at: 0)
        }
        
        var patternIndex = 0
        for (index, _) in pattern.enumerated() {
            if pattern[index] > 0 {
                patternIndex = index
                break
            }
        }
        
        let sampleLength = pattern[patternIndex]
        
        var sampleLengths = Array(0...sampleLength)
        sampleLengths.removeFirst()
        
        var found = false
        for (index, _) in sampleLengths.enumerated() {
            if pattern[index] > 0 {
                found = true
                break
            }
        }

        return found
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
    
    func pauseAllAudio() {
        players.keys.forEach {
            players[$0]?.pause()
        }
    }
    
    func sessionPause() {
        pauseAllAudio()
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

    func clearHistory() {
        playback = getInstruments().map { _ in
            return []
        }
    }
    
    func create() {
        audios = []
        shuffle()
        flushAll()
        clearHistory()
        
        let audio = Audio(
            fadeIndex: 0,
            sampleIndex: 0,
            resources: []
        )
        let audio2 = audio.copy() as! Audio
        
        audios.append(audio)
        audios.append(audio2)

        pick(audioIndex: 0)
        pick(audioIndex: 1)
        
        resetFadeIndices()
    }
    
    func resetFadeIndices() {
        audios[0].fadeIndex = FADE_DURATION + 1
        audios[1].fadeIndex = -FADE_DURATION * 2
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
        channels = channels.map {
            $0.tracks = $0.tracks.shuffled()
            return $0
        }
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
    
    func getInstruments() -> [Distances] {
        var res: [Distances] = []
                                    
        SEQUENCES.forEach {
            if instruments[$0.instrument] != nil {
                res.append(instruments[$0.instrument]!)
            }
        }
        
        return res
    }
    
    func getTrackIndex(instrumentIndex: Int, id: Int) -> Int {
        channels[instrumentIndex].tracks
            .firstIndex(where: { $0.id == id }) ?? 0
    }

    func pick(audioIndex: Int) {
        getInstruments().enumerated().forEach { (instrumentIndex, instrument) in
            let hasPreviousIndex = playback[instrumentIndex].count > 1 && playback[instrumentIndex].count < channels[instrumentIndex].tracks.count
            let lastIndex = hasPreviousIndex
                ? playback[instrumentIndex].count
                : Int.random(in: 0 ... channels[instrumentIndex].tracks.count - 1)
            let lastTrack = channels[instrumentIndex].tracks[lastIndex]
            let distances = instrument[lastTrack.id] ?? []
            var summary: [Int: Double] = [:]

            distances.enumerated().forEach { distanceIndex, distance in
                let nextDistances: [Distance] = instrument[distance.rightId] ?? []
                for nextDistance in nextDistances {
                    if !playback[instrumentIndex].contains(nextDistance.rightId) {
                        summary[nextDistance.rightId] = distance.value + nextDistance.value
                    }
                }
            }

            if summary.isEmpty {
                playback[instrumentIndex] = []
                playback[instrumentIndex].append(lastTrack.id)
                pick(audioIndex: audioIndex)
                return
            }
  
            var sortedSummary = Array(
                summary.sorted { $0.1 < $1.1 }
            )
                        
            // Introduce some randomness to the audio picker.
            if sortedSummary.count >= PICKER_RANDOM_COUNT {
                sortedSummary = sortedSummary[0...(PICKER_RANDOM_COUNT - 1)]
                    .shuffled()
            }

            let id = sortedSummary[0].key
            playback[instrumentIndex].append(id)
        }

        playAudio()
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
        
        for (sequenceIndex, sequence) in sequences.enumerated() {
            let channel = Channel()
            channel.tracks = getInstruments()[sequenceIndex].keys.map {
                getTrack(
                    id: Int($0), sequence: sequence
                )
            }
            channels.append(channel)
        }
        
        return channels
    }
}
