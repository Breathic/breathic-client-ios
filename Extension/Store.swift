import Foundation
import SwiftUI

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
    var rhythms: [Track] = []
    var distances: [Int: [Distance]] = readDistances(path: "data/distances.json")
    var ui: UI = UI()
    var sessionLogs: [Session] = []
    var sessionLogIds: [String] = []
    var isAudioSessionLoaded: Bool = false
    var isAudioPlaying: Bool = false
    var lastDataChangeTime: DispatchTime = .now()
    var elapsedTime: String = ""
    var playerIndex: Int = -1
    var queueIndex: Int = 0
    var selectedRhythmIndex: Int = 0
    var metricType: MetricType = METRIC_TYPES["heart"]!
    var metrics: [String: Float] = [:]
    var readings: [String: [Reading]] = [:]
    var timeseries: [String: [Reading]] = [:]
    var seriesData: [SeriesData] = []
    var selectedSession = Session()
    var chartDomain = ChartDomain()
    var chartableMetrics: [String: Float] = [:]
    var chartedMetricsVisibility: [String: Bool] = [:]
    var chartScales: [String: Bool] = DEFAULT_CHART_SCALES

    func getMetricValue(_ metric: String) -> Float {
        metrics[metric] ?? 0
    }

    mutating func setMetricValue(_ metric: String, _ value: Float) {
        if metrics[metric] == nil {
            metrics[metric] = 0
        }

        metrics[metric] = value
    }

    mutating func setMetricValuesToDefault() {
        METRIC_TYPES.keys.forEach {
            self.metrics[$0] = METRIC_TYPES[$0]?.defaultValue
        }

        self.metrics["rhythm-in"] = Float(self.session.getRhythms()[0]) / 10
        self.metrics["rhythm-out"] = Float(self.session.getRhythms()[1]) / 10
    }
}

final class Store: ObservableObject {
    static let shared: Store = Store()

    @Published var state: AppState = AppState()
}
