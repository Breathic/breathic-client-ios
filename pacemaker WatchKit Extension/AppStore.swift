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
    var activeSubView: String = "Pacemaker"
    var seeds: [Seed] = []
    var distances: [Int: [Distance]] = readDistances(path: "data/distances.json")
    var ui: UI = UI()
    var history: [Int] = []
    var seedInputs: [SeedInput] = [
        SeedInput(durationRange: [0, 8], interval: [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0]),
        //SeedInput(durationRange: [0, 0.25], interval: [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]),
    ]
    var likes: [[Seed]] = []
    var likesIds: [String] = []
    var isAudioSessionLoaded: Bool = false
    var isAudioPlaying: Bool = false
    var lastDataChangeTime: DispatchTime = .now()
    var selectedVolume: Int = 50
    var playerIndex: Int = -1
    var rhythmRange: [Int] = Array(1...50)
    var selectedInRhythm: Int = 20
    var selectedOutRhythm: Int = 20
    var selectedRhythmIndex: Int = 0
    var rhythmTypes: [RhythmType] = [
        RhythmType(
            metric: "averageHeartRatePerSecond",
            unit: "heartbeats / s",
            isReversed: false
        ),
        RhythmType(
            metric: "averageStepsPerSecond",
            unit: "steps / s",
            isReversed: true
        ),
        RhythmType(
            metric: "averageMeterPerSecond",
            unit: "m / s",
            isReversed: true
        )
    ]
    var selectedRhythmTypeIndex = 2
    var averageHeartRatePerSecond: Float = 1
    var averageStepsPerSecond: Float = 1
    var averageMeterPerSecond: Float = 1
    var averageHeartRatesPerMinute: [Update] = []
    var averageBreathIntervalPerMinute: [Update] = []
    var averageMetersPerSecond: [Update] = []

    func valueByMetric(metric: String) -> Float {
        switch metric {
            case "averageHeartRatePerSecond": return averageHeartRatePerSecond
            case "averageStepsPerSecond": return averageStepsPerSecond
            case "averageMeterPerSecond": return averageMeterPerSecond
            default: fatalError("Key is undefined")
        }
    }
}

final class AppStore: ObservableObject {
    static let shared: AppStore = AppStore()

    @Published var state = AppState()
}
