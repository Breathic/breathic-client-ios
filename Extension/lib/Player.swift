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
        store.state.channels = getChannelsFromSequences(SEQUENCES)
        create()
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
        channelIndex: Int,
        sampleIndex: Int,
        isBreathingChannel: Bool
    ) {
        let channel = audios[audioIndex].channels[channelIndex]

        let breathType = channelIndex == 0
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
            for (channelIndex, channel) in audio.channels.enumerated() {
                let isAudioHaptic = FEEDBACK_MODES[store.state.activeSession.feedbackModeIndex] == Feedback.AudioHaptic
                let isAudio = isAudioHaptic || FEEDBACK_MODES[store.state.activeSession.feedbackModeIndex] == Feedback.Audio
                let isHaptic = isAudioHaptic || FEEDBACK_MODES[store.state.activeSession.feedbackModeIndex] == Feedback.Haptic
                let isMuted = !(Float(store.state.activeSession.volume) > 0)
                let isBreathingChannel: Bool = channelIndex == 0

                if audioIndex == 0 && isBreathingChannel {
                    incrementSelectedRhythmIndex()
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

                let islastQuarter = audio.fadeIndex == FADE_DURATION * 3 - 1
                if islastQuarter {
                    pick(audioIndex: 1, regenerate: false)
                    audios[1].fadeIndex = 0
                }

                let isTransitioning = audio.fadeIndex == CHANNEL_REPEAT_COUNT
                if isTransitioning {
                    audios[0].fadeIndex = -FADE_DURATION * 2 + 1
                    audios = audios.reversed()
                }

                if !isMuted && isAudio && channel[audio.sampleIndex] != "" {
                    setAudio(
                        audioIndex: audioIndex,
                        channelIndex: channelIndex,
                        sampleIndex: audio.sampleIndex,
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
            channels: [],
            resources: []
        )
        let audio2 = audio.copy() as! Audio
        audio2.fadeIndex = -FADE_DURATION * 3 + 1

        audios.append(audio)
        audios.append(audio2)

        setSamplesToChannels(audioIndex: 0)
        setSamplesToChannels(audioIndex: 1)
        resetFadeIndexes()
        //pick(audioIndex: 0, regenerate: true)
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
            pick(audioIndex: audioIndex, regenerate: true)
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
        audios[audioIndex].channels = []

        for channel in store.state.channels {
            let audioIndexExtra = audioIndex % 2 == 0
                ? 0
                : 1
            audios[audioIndex].channels.append(
                channel.tracks[channel.queueIndex + audioIndexExtra].samples
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

    func pickOld(audioIndex: Int, regenerate: Bool) {
        if regenerate {
            /*
            shuffle()

            for (instrumentIndex, _) in store.state.instruments.enumerated() {
                for (channelIndex, _) in store.state.channels.enumerated() {
                    for (trackIndex, _) in store.state.channels[channelIndex].tracks.enumerated() {
                        let lastTrack = store.state.channels[channelIndex].tracks[trackIndex]
                        print("trackIndex", trackIndex)
                        print("lastTrack.id", lastTrack.id)
                        print(
                            "store.state.instruments[instrumentIndex].distances[lastTrack.id]",
                            store.state.instruments[instrumentIndex].distances[lastTrack.id]
                        )
                        let distances: [Distance] = store.state.instruments[instrumentIndex].distances[lastTrack.id] ?? []
                        var summary: [Int: Double] = [:]

                        for distance in distances {
                            let nextDistances: [Distance] = store.state.instruments[instrumentIndex].distances[distance.rightId] ?? []

                            for nextDistance in nextDistances {
                                summary[nextDistance.rightId] = distance.value + nextDistance.value
                            }
                        }

                        let sortedSummary: [Dictionary<Int, Double>.Element] = summary
                            .sorted { Double($0.value) < Double($1.value) }

                        // Introduce some randomness to the audio picker.
                        let shuffledSummary: [Dictionary<Int, Double>.Element] = Array(sortedSummary[0...1])
                            .shuffled()

                        let index = store.state.channels[channelIndex].tracks
                            .firstIndex(where: { $0.id == shuffledSummary[0].key }) ?? 0

                        let element = store.state.channels[channelIndex].tracks
                            .remove(at: index)

                        store.state.channels[channelIndex].tracks
                            .insert(element, at: trackIndex)
                    }
                }
            }

            flush(audioIndex: audioIndex)
             */
        }
        else {
            incrementQueueIndex()
        }

        setSamplesToChannels(audioIndex: audioIndex)
        playAudio()
    }

    func incrementQueueIndex() {
        store.state.channels = store.state.channels.map { channel in
            channel.queueIndex = channel.queueIndex + 1

            if channel.queueIndex == channel.tracks.count - 1 {
                channel.queueIndex = 0
            }

            return channel
        }
    }

    func pick(audioIndex: Int, regenerate: Bool) {
        if regenerate {
            
            
            
            
            
            return
            
            /*
            for (instrumentIndex, _) in store.state.instruments.enumerated() {
                for (channelIndex, _) in store.state.channels.enumerated() {
                    store.state.channels[channelIndex].queueIndex = 0

                    for (trackIndex, _) in store.state.channels[channelIndex].tracks.enumerated() {
                        let lastTrack = store.state.channels[channelIndex].tracks[trackIndex]
                        print("trackIndex", trackIndex)
                        print("lastTrack.id", lastTrack.id)
                        print(
                            "store.state.instruments[instrumentIndex].distances[lastTrack.id]",
                            store.state.instruments[instrumentIndex].distances[lastTrack.id]
                        )
                        let distances: [Distance] = store.state.instruments[instrumentIndex].distances[lastTrack.id] ?? []
                        var summary: [Int: Double] = [:]

                        for distance in distances {
                            let nextDistances: [Distance] = store.state.instruments[instrumentIndex].distances[distance.rightId] ?? []

                            for nextDistance in nextDistances {
                                summary[nextDistance.rightId] = distance.value + nextDistance.value
                            }
                        }

                        let sortedSummary: [Dictionary<Int, Double>.Element] = summary
                            .sorted { Double($0.value) < Double($1.value) }

                        // Introduce some randomness to the audio picker.
                        let shuffledSummary: [Dictionary<Int, Double>.Element] = Array(sortedSummary[0...1])
                            .shuffled()

                        let index = store.state.channels[channelIndex].tracks
                            .firstIndex(where: { $0.id == shuffledSummary[0].key }) ?? 0

                        let element = store.state.channels[channelIndex].tracks
                            .remove(at: index)

                        store.state.channels[channelIndex].tracks
                            .insert(element, at: trackIndex)
                    }
                }
            }

            flush(audioIndex: audioIndex)
             */
        }
        else {
            incrementQueueIndex()
        }

        setSamplesToChannels(audioIndex: audioIndex)
        playAudio()
    }
}
