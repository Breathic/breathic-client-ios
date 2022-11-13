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
    var session: Session = Session()
    var selectedSessionId: String = ""
    var isResumable: Bool = false
    var seeds: [Seed] = []
    var rhythms: [Rhythm] = []
    var distances: [Int: [Distance]] = readDistances(path: "data/distances.json")
    var ui: UI = UI()
    var sessionLogs: [Session] = []
    var sessionLogIds: [String] = []
    var isAudioSessionLoaded: Bool = false
    var lastDataChangeTime: DispatchTime = .now()
    var elapsedTime: String = ""
    var playerIndex: Int = -1
    var queueIndex: Int = 0
    var selectedRhythmIndex: Int = 0
    var metricType: MetricType = METRIC_TYPES[0]
    var breath: Float = DEFAULT_BREATH
    var heart: Float = DEFAULT_HEART
    var step: Float = DEFAULT_STEP
    var speed: Float = DEFAULT_SPEED
    var readings: [String: [Reading]] = [
        "breath": [],
        "heart": [],
        "step": [],
        "speed": []
    ]
    var timeseries: [String: [Reading]] = [:]
    var seriesData: [SeriesData] = []
    var selectedSession = Session()
    var dragIndex: Int = 0
    let chartDomain = ChartDomain()
    var dragXOffset = CGSize.zero
    var wasDragged = false

    func getMetricValue(_ metric: String) -> Float {
        switch metric {
            case "breath": return breath
            case "heart": return heart
            case "step": return step
            case "speed": return speed
            default: fatalError("metric is undefined")
        }
    }

    mutating func setMetricValue(_ metric: String, _ value: Float?) {
        switch metric {
            case "breath": breath = value ?? DEFAULT_BREATH
            case "heart": heart = value ?? DEFAULT_HEART
            case "step": step = value ?? DEFAULT_STEP
            case "speed": speed = value ?? DEFAULT_SPEED
            default: fatalError("metric is undefined")
        }
    }

    mutating func setMetricsToDefault() {
        readings.keys.forEach {
            setMetricValue($0, nil)
        }
    }
}

final class Store: ObservableObject {
    static let shared: Store = Store()

    @Published var state = AppState()
}
