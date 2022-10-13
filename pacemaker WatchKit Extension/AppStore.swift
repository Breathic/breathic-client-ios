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
    var activeSubView: String = "Controller"
    var startHour = 0
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
    var isSessionActive: Bool = false
    var isAudioSessionLoaded: Bool = false
    var isAudioPlaying: Bool = false
    var lastDataChangeTime: DispatchTime = .now()
    var selectedVolume: Int = 50
    var playerIndex: Int = -1
    var rhythmRange: [Int] = Array(10...50)
    var selectedInRhythm: Int = 20
    var selectedOutRhythm: Int = 20
    var selectedRhythms: [Int] = []
    var selectedRhythmIndex: Int = 0
    var metricTypes: [MetricType] = [
        MetricType(
            metric: "heartRateMetric",
            label: "pulse",
            unit: "minute",
            isReversed: false
        ),
        MetricType(
            metric: "stepMetric",
            label: "step",
            unit: "minute",
            isReversed: true
        )/*,
        MetricType(
            metric: "speedMetric",
            unit: "m / s",
            isReversed: true
        )*/
    ]
    var selectedMetricTypeIndex = 0
    var breathRateMetric: Float = Platform.isSimulator ? 1 : 0
    var heartRateMetric: Float = Platform.isSimulator ? 1 : 0
    var stepMetric: Float = Platform.isSimulator ? 1 : 0
    var speedMetric: Float = Platform.isSimulator ? 1 : 0
    var updates: [String: [Update]] = [
        "breath": [],
        "heartRate": [],
        "step": [],
        "speed": []
    ]

    func valueByMetric(metric: String) -> Float {
        switch metric {
            case "breathRateMetric": return breathRateMetric
            case "heartRateMetric": return heartRateMetric
            case "stepMetric": return stepMetric
            case "speedMetric": return speedMetric
            default: fatalError("metric is undefined")
        }
    }
}

final class AppStore: ObservableObject {
    static let shared: AppStore = AppStore()

    @Published var state = AppState()
}
