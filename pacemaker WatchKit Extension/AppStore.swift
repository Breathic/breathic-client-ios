import Foundation

/*
import Sentry

SentrySDK.start { options in
     options.dsn = SENTRY_DSN
     options.debug = true
     options.tracesSampleRate = 1.0
 }
 */

struct AppState {
    var activeSubView: SubView = .main
    var seeds: [Seed] = []
    var distances: [Int: [Distance]] = readDistances(path: "data/distances.json")
    var ui: UI = UI()
    var history: [Int] = []
    var seedInputs: [SeedInput] = [
        SeedInput(durationRange: [0, 8], interval: [1, 1, 1, 1, 1, 1, 1, 1] ** 8, isPanning: true),
    ]
    var likes: [[Seed]] = []
    var likesIds: [String] = []
    var isAudioSessionLoaded: Bool = false
    var isAudioPlaying: Bool = false
    var selectedVolume: Int = 25
    var isDiscoveryEnabled = true
    var playerIndex: Int = -1
    var currentSampleIndex = 0
    var rhythmRange: [Int] = Array(1...50)
    var selectedInRhythm: Int = 10
    var selectedOutRhythm: Int = 10
    var selectedRhythmIndex: Int = 0
    var rhythmTypes: [RhythmType] = [
        RhythmType(unit: "heartbeat / s", key: "averageHeartRatePerSecond"),
        RhythmType(unit: "step / s", key: "averageStepsPerSecond"),
        //RhythmType(unit: "m / s", key: "averageMetersPerSecond"),
    ]
    var selectedRhythmTypeIndex = 0
    var averageHeartRatePerSecond: Double = 1
    var averageStepsPerSecond: Double = 1
    var averageMetersPerSecond: Double = 1
    
    func valueByKey(key: String) -> Double {
        switch key {
            case "averageHeartRatePerSecond": return averageHeartRatePerSecond
            case "averageStepsPerSecond": return averageStepsPerSecond
            case "averageMetersPerSecond": return averageMetersPerSecond
            default: fatalError("Key is undefined")
        }
    }
}

final class AppStore: ObservableObject {
    static let shared: AppStore = AppStore()

    @Published var state = AppState(activeSubView: .main)
}
