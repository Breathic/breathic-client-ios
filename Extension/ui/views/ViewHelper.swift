import Foundation
import SwiftUI

func getSessionUnit(store: Store) -> String {
    if store.state.session.isActive {
        if store.state.isResumable { return "Resume" }
        else if store.state.elapsedTime.count > 0 { return store.state.elapsedTime }
        else { return " " }
    }
    else {
        return "Stopped"
    }
}

func isSessionActive(store: Store) -> Bool {
    return store.state.session.isActive && !store.state.isResumable
}

func slide(geometry: GeometryProxy, store: Store) {
    store.state.pageOptions[store.state.page]!.dragXOffset = CGFloat(-geometry.size.width - 4) * CGFloat(store.state.pageOptions[store.state.page]!.dragIndex)
}

func selectMainMenu(geometry: GeometryProxy, store: Store) {
    if store.state.tempActiveSubView == "" {
        store.state.tempActiveSubView = store.state.menuViews[store.state.page]![0]
    }

    store.state.activeSubView = store.state.tempActiveSubView
    store.state.pageOptions[store.state.page]!.dragIndex = DRAG_INDEXES[store.state.activeSubView] ?? 0

    slide(geometry: geometry, store: store)
}

func highlightFirstLogItem(store: Store) {
    let sessionLogIds = getSessionIds(sessions: store.state.sessionLogs)

    if sessionLogIds.count > 0 {
        store.state.selectedSessionId = sessionLogIds[sessionLogIds.count - 1]
    }
}

func getAverageMetricValue(
    timeseries: [String: [Reading]],
    metric: String
) -> Float {
    let metrics = (timeseries[metric] ?? [])
    let average = metrics
        .map { $0.value }
        .reduce(0, +) / Float(metrics.count)

    return average
}

func getSeriesData(store: Store) -> ([SeriesData], ChartDomain) {
    let chartXAxisRightSpacingPct: Float = 5
    var _timeseries: [String: [ProgressData]] = [:]
    let chartDomain = ChartDomain()

    store.state.timeseries.keys.forEach {
        let progressData = parseProgressData(
            timeseries: store.state.timeseries[$0] ?? [],
            startTime: store.state.selectedSession.startTime
        )

        _timeseries[$0] = progressData

        if progressData.count > 0 {
            chartDomain.xMin = Float(progressData[0].timestamp)
            chartDomain.xMax = Float(progressData[progressData.count - 1].timestamp) + Float(progressData[progressData.count - 1].timestamp) * chartXAxisRightSpacingPct / 100
        }
    }

    var result: [SeriesData] = []
    for metric in _timeseries.keys {
        let progressData: [ProgressData] = _timeseries[metric] ?? []
            if store.state.chartedMetricsVisivbility[metric] != nil && store.state.chartedMetricsVisivbility[metric]! {
                for timeserie in progressData {
                    if timeserie.value > chartDomain.yMax {
                        chartDomain.yMax = timeserie.value
                    }
                }

                result.append(.init(metric: metric, data: progressData, color: getMetric(metric).color))
            }
    }

    return (result, chartDomain)
}

func getChartableMetrics(store: Store) -> [String: Float] {
    var chartedMetrics: [String: Float] = [:]

    store.state.timeseries.keys.forEach {
        let avgValue = getAverageMetricValue(timeseries: store.state.timeseries, metric: $0)

        if avgValue > 0 {
            chartedMetrics[$0] = avgValue
        }
    }

    return chartedMetrics
}

func onLogSelect(store: Store) {
    let index = store.state.sessionLogIds
        .firstIndex(where: { $0 == store.state.selectedSessionId }) ?? -1

    if index > -1 {
        store.state.selectedSession = store.state.sessionLogs[index]
        clearTimeseries(store: store)

        var addedMinutes = 0
        while(store.state.selectedSession.startTime.adding(minutes: addedMinutes) <= store.state.selectedSession.endTime) {
            let id = getTimeseriesUpdateId(uuid: store.state.selectedSession.uuid, date: store.state.selectedSession.startTime.adding(minutes: addedMinutes)) + "|" + DEFAULT_TIME_RESOLUTION
            let data = readFromFile(key: id)

            do {
                let _timeseries = try JSONDecoder().decode([String: [Reading]].self, from: data)

                _timeseries.keys.forEach {
                    if store.state.timeseries[$0] == nil {
                        store.state.timeseries[$0] = []
                    }

                    store.state.timeseries[$0] = store.state.timeseries[$0]! + _timeseries[$0]!
                }
            }
            catch {}

            addedMinutes = addedMinutes + 1
        }

        let result = getSeriesData(store: store)
        store.state.seriesData = result.0
        store.state.chartDomain = result.1
        store.state.chartedMetrics = getChartableMetrics(store: store)
        store.state.activeSubView = store.state.selectedSessionId
    }
}

func hasSessionLogs(store: Store) -> Bool {
    return store.state.sessionLogs.count > 0
}

func clearTimeseries(store: Store) {
    store.state.timeseries.keys.forEach {
        store.state.timeseries[$0] = []
    }
}

func deleteSession(store: Store, sessionId: String) {
    var sessionIndex = -1

    for (index, item) in getSessionIds(sessions: store.state.sessionLogs).enumerated() {
        if item == sessionId {
            sessionIndex = index
        }
    }

    if sessionIndex > -1 {
        store.state.sessionLogs.remove(at: sessionIndex)
        saveSessionLogs(sessionLogs: store.state.sessionLogs)
        store.state.sessionLogIds = getSessionIds(sessions: store.state.sessionLogs)
    }

    if !hasSessionLogs(store: store) {
        store.state.activeSubView = store.state.menuViews[store.state.page]![0]
    }
    else {
        store.state.activeSubView = "Log"
        highlightFirstLogItem(store: store)
    }
}

func isOverviewSelected(store: Store) -> Bool {
    return store.state.activeSubView == store.state.selectedSessionId
}

func graphColors(for input: [SeriesData]) -> [Color] {
    var returnColors = [Color]()
    for item in input {
        returnColors.append(item.color)
    }
    return returnColors
}
