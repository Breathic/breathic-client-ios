import Foundation

/*
import Sentry

let SENTRY_DSN = "https://104bfdd0d1f9498bba4cbaca12988611@o1399372.ingest.sentry.io/6726680"

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
        SeedInput(durationRange: [0.25, 0.5], interval: [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0]),
        SeedInput(durationRange: [0, 0.25], interval: [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]),
    ]
    var likes: [[Seed]] = []
    var likesIds: [String] = []
    var isAudioSessionLoaded: Bool = false
    var isAudioPlaying: Bool = false
    var selectedVolume: Int = 100
    var playerIndex: Int = -1
    var rhythmRange: [Int] = Array(1...50)
    var selectedInRhythm: Int = 15
    var selectedOutRhythm: Int = 15
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
