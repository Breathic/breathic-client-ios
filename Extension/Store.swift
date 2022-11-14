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
    var pageOptions: [String: PageOption] = Dictionary(uniqueKeysWithValues: DEFAULT_MENU_VIEWS.keys.map { ($0, PageOption()) })
    var page: String = DEFAULT_PAGE
    var activeSubView: String = DEFAULT_ACTIVE_SUB_VIEW
    var menuViews = DEFAULT_MENU_VIEWS
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
    var metrics = DEFAULT_METRICS
    var readings: [String: [Reading]] = [:]
    var timeseries: [String: [Reading]] = [:]
    var seriesData: [SeriesData] = []
    var selectedSession = Session()
    var chartDomain = ChartDomain()

    func getMetricValue(_ metric: String) -> Float {
        metrics[metric] ?? 0
    }

    mutating func setMetricValue(_ metric: String, _ value: Float) {
        if metrics[metric] == nil {
            metrics[metric] = 0
        }

        metrics[metric] = value
    }
}

final class Store: ObservableObject {
    static let shared: Store = Store()

    @Published var state = AppState()
}
