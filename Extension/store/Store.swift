import Foundation
import SwiftUI

struct AppState {
    var renderIncrement: Int = 0
    var pageOptions: [String: PageOption] = Dictionary(uniqueKeysWithValues: MENU_VIEWS.keys.map { ($0, PageOption()) })
    var page: String = DEFAULT_PAGE
    var activeSubView: String = DEFAULT_ACTIVE_SUB_VIEW
    var tempActiveSubView: String = ""
    var session: Session = Session()
    var selectedSessionId: String = ""
    var isResumable: Bool = false
    var seeds: [Seed] = []
    var rhythms: [Track] = []
    var distances: [Int: [Distance]] = readDistances(path: "data/distances.json")
    var ui: UI = UI()
    var sessions: [Session] = []
    var isAudioSessionLoaded: Bool = false
    var isAudioPlaying: Bool = false
    var elapsedTime: String = ""
    var playerIndex: Int = -1
    var queueIndex: Int = 0
    var selectedRhythmIndex: Int = 0
    var audioPanningMode: String = AUDIO_PANNING_MODES[0]
    var activity: Activity = ACTIVITIES[0]
    var metrics: [String: Float] = [:]
    var readings: [TimeUnit: ReadingContainer] = [
        TimeUnit.Second: ReadingContainer(),
        TimeUnit.Minute: ReadingContainer()
    ]
    var timeseries: ReadingContainer = [:]
    var seriesData: [SeriesData] = []
    var selectedSession = Session()
    //var selectedSessionIndex: Int = 0
    var chartDomain = ChartDomain()
    var chartableMetrics: [String: Float] = [:]
    var chartedMetricsVisibility: [String: Bool] = [:]
    var chartScales: [String: Bool] = DEFAULT_CHART_SCALES
    var isSyncInProgress: Bool = false

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
    }

    mutating func render() {
        self.renderIncrement = self.renderIncrement + 1
    }
}

final class Store: ObservableObject {
    static let shared: Store = Store()

    @Published var state: AppState = AppState()
}
