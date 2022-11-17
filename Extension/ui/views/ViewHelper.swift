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

func getAllProgressData(store: Store) -> [String: [ProgressData]] {
    var result: [String: [ProgressData]] = [:]

    for metric in store.state.timeseries.keys {
        let isVisible = store.state.chartedMetricsVisivbility[metric] != nil && store.state.chartedMetricsVisivbility[metric]!
        if !isVisible {
            continue
        }

        let progressData = parseProgressData(
            timeseries: store.state.timeseries[metric] ?? [],
            startTime: store.state.selectedSession.startTime
        )

        result[metric] = progressData
    }

    return result
}

func getSeriesData(store: Store, allProgressData: [String: [ProgressData]]) -> [SeriesData] {
    allProgressData.keys.map {
        .init(metric: $0, data: allProgressData[$0] ?? [], color: getMetric($0).color)
    }
}

func getChartDomain(timeseries: [String: [Reading]], allProgressData: [String: [ProgressData]]) -> ChartDomain {
    let chartDomain = ChartDomain()

    for metric in timeseries.keys {
        let progressData = allProgressData[metric] ?? []

        for (timeserieIndex, timeserie) in progressData.enumerated() {
            if timeserieIndex == 0 {
                chartDomain.xMin = Float(progressData[0].timestamp)
                chartDomain.xMax = Float(progressData[progressData.count - 1].timestamp) + Float(progressData[progressData.count - 1].timestamp) * CHART_X_AXIS_RIGHT_AXIS_PADDING_PCT / 100
            }

            if timeserie.value > chartDomain.yMax {
                chartDomain.yMax = timeserie.value
            }
        }
    }

    return chartDomain
}

func getChartableMetrics(timeseries: [String: [Reading]]) -> [String: Float] {
    var chartableMetrics: [String: Float] = [:]

    timeseries.keys.forEach {
        let avgValue = getAverageMetricValue(timeseries: timeseries, metric: $0)

        if avgValue > 0 {
            chartableMetrics[$0] = avgValue
        }
    }

    return chartableMetrics
}

func getTimeseriesData(store: Store) -> [String: [Reading]] {
    var result: [String: [Reading]] = [:]
    var addedMinutes = 0

    while (store.state.selectedSession.startTime.adding(minutes: addedMinutes) <= store.state.selectedSession.endTime) {
        let id = getTimeseriesUpdateId(uuid: store.state.selectedSession.uuid, date: store.state.selectedSession.startTime.adding(minutes: addedMinutes)) + "|" + DEFAULT_TIME_RESOLUTION
        let data = readFromFile(key: id)

        do {
            let timeseries = try JSONDecoder().decode([String: [Reading]].self, from: data)

            timeseries.keys.forEach {
                if result[$0] == nil {
                    result[$0] = []
                }

                result[$0] = result[$0]! + timeseries[$0]!
            }
        }
        catch {}

        addedMinutes = addedMinutes + 1
    }

    return result
}

func onLogSelect(store: Store) {
    let index = store.state.sessionLogIds
        .firstIndex(where: { $0 == store.state.selectedSessionId }) ?? -1

    if index > -1 {
        store.state.selectedSession = store.state.sessionLogs[index]
        clearTimeseries(store: store)

        store.state.timeseries = getTimeseriesData(store: store)
        let allProgressData: [String: [ProgressData]] = getAllProgressData(store: store)
        store.state.seriesData = getSeriesData(store: store, allProgressData: allProgressData)
        store.state.chartDomain = getChartDomain(timeseries: store.state.timeseries, allProgressData: allProgressData)
        store.state.chartableMetrics = getChartableMetrics(timeseries: store.state.timeseries)
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
