import Foundation
import SwiftUI

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
    var tempActiveSubView: String = ""
    var session: Session = readActiveSession()
    var selectedSessionId: String = ""
    var seeds: [Seed] = []
    var rhythms: [Rhythm] = []
    var distances: [Int: [Distance]] = readDistances(path: "data/distances.json")
    var ui: UI = UI()
    var sessionLogs: [Session] = []
    var sessionLogIds: [String] = []
    var isAudioSessionLoaded: Bool = false
    var isAudioPlaying: Bool = false
    var lastDataChangeTime: DispatchTime = .now()
    var playerIndex: Int = -1
    var queueIndex: Int = 0
    var selectedRhythmIndex: Int = 0
    var metricType: MetricType = METRIC_TYPES[0]
    var breathRateMetric: Float = Platform.isSimulator ? 1 : 0
    var heartRateMetric: Float = Platform.isSimulator ? 1 : 0
    var stepMetric: Float = Platform.isSimulator ? 1 : 0
    var speedMetric: Float = Platform.isSimulator ? 1 : 0
    var updates: [String: [Update]] = [
        "breath": [],
        "heart": [],
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
