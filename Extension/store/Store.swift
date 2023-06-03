import Foundation
import SwiftUI

struct AppState {
    var renderIncrement: Int = 0
    var pageOptions: [String: PageOption] = [
        Page.Main.rawValue: PageOption()
    ]
    var page: String = DEFAULT_PAGE
    var activeSubView: String = DEFAULT_ACTIVE_SUB_VIEW
    var tempActiveSubView: String = ""
    var activeSession: Session = Session()
    var selectedSessionId: String = ""
    var selectedActivityId: String = ""
    var selectedDurationId: String = DEFAULT_DURATION_OPTIONS[0]
    var ui: UI = UI()
    var sessions: [Session] = []
    var activity: Activity = ACTIVITIES[0]
    var metrics: [String: Float] = [:]
    var readings: [TimeUnit: ReadingContainer] = [
        TimeUnit.Second: ReadingContainer(),
        TimeUnit.Minute: ReadingContainer()
    ]
    var timeseries: ReadingContainer = [:]
    var seriesData: [SeriesData] = []
    var selectedSession = Session()
    var chartDomain = ChartDomain()
    var overviewMetrics: Overview = [:]
    var overviewMetricsVisibility: [String: Bool] = [:]
    var chartScales: [ChartScale: Bool] = DEFAULT_CHART_SCALES
    var isSyncInProgress: Bool = false
    var isTermsApproved: Bool? = nil
    var isGuideSeen: Bool? = nil
    var deviceToken: String = ""

    func getMetricValue(_ metric: String) -> Float {
        self.metrics[metric] ?? 0
    }

    mutating func setMetricValue(_ metric: String, _ value: Float) {
        self.metrics[metric] = value
    }

    mutating func setMetricValuesToDefault() {
        if !Platform.isSimulator {
            self.metrics = [:]
        }
        else {
            METRIC_TYPES.keys.forEach {
                if METRIC_TYPES[$0]!.isChartable {
                    self.metrics[$0] = METRIC_TYPES[$0]?.defaultValue
                }
            }
        }
    }

    mutating func render() {
        self.renderIncrement = self.renderIncrement + 1
    }
}

final class Store: ObservableObject {
    static let shared: Store = Store()

    @Published var state: AppState = AppState()
}
