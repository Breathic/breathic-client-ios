import Foundation
import SwiftUI

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
        let isVisible = store.state.chartedMetricsVisibility[metric] != nil && store.state.chartedMetricsVisibility[metric]!

        if isVisible {
            result[metric] = parseProgressData(
                timeseries: store.state.timeseries[metric] ?? [],
                startTime: store.state.selectedSession.startTime
            )
        }
    }

    return result
}

func getSeriesData(store: Store, allProgressData: [String: [ProgressData]]) -> [SeriesData] {
    METRIC_ORDER
        .filter { allProgressData[$0] != nil }
        .filter { store.state.chartableMetrics[$0] != nil }
        .map {
            .init(metric: $0, data: allProgressData[$0] ?? [], color: getMetric($0).color)
        }
}

func getChartDomain(timeseries: [String: [Reading]], allProgressData: [String: [ProgressData]]) -> ChartDomain {
    let chartDomain = ChartDomain()

    for metric in timeseries.keys {
        let progressData = allProgressData[metric] ?? []

        if progressData.count > 0 {
            chartDomain.xMin = Float(progressData[0].timestamp)
            chartDomain.xMax = Float(progressData[progressData.count - 1].timestamp)
        }

        for timeserie in progressData {
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
                let readings = timeseries[$0]!

                if result[$0] == nil {
                    result[$0] = []
                }

                result[$0] = result[$0]! + readings
            }
        }
        catch {}

        addedMinutes = addedMinutes + 1
    }

    return result
}

func parseScale(
    timeseries: [String: [Reading]],
    chartScales: [String: Bool]
) -> [String: [Reading]] {
    var result = timeseries

    if chartScales["Percentage"] == true {
        timeseries.keys.forEach {
            let readings = timeseries[$0]!
            let min: Float = (readings.map { $0.value }).min() ?? 0
            let max: Float = (readings.map { $0.value }).max() ?? 0

            result[$0] = readings.map() {
                let reading = $0
                let value = convertRange(
                    value: reading.value,
                    oldRange: [min, max],
                    newRange: [0, 100]
                )

                if canUpdate(value) {
                    reading.value = value
                }

                return reading
            }
        }
    }

    return result
}

func onLogSelect(store: Store) {
    let index = store.state.sessionLogIds.reversed()
        .firstIndex(where: { $0 == store.state.selectedSessionId }) ?? -1

    if index > -1 {
        store.state.selectedSession = store.state.sessionLogs.reversed()[index]
        clearTimeseries(store: store)

        store.state.timeseries = getTimeseriesData(store: store)
        store.state.timeseries = parseScale(timeseries: store.state.timeseries, chartScales: store.state.chartScales)

        let allProgressData: [String: [ProgressData]] = getAllProgressData(store: store)
        store.state.chartDomain = getChartDomain(timeseries: store.state.timeseries, allProgressData: allProgressData)
        store.state.chartableMetrics = getChartableMetrics(timeseries: getTimeseriesData(store: store))

        store.state.seriesData = getSeriesData(store: store, allProgressData: allProgressData)

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
