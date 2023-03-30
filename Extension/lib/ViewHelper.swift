import Foundation
import SwiftUI

func isSessionActive(store: Store) -> Bool {
    store.state.activeSession.isStarted() && store.state.activeSession.isPlaying
}

func slide(geometry: GeometryProxy, store: Store) {
    store.state.pageOptions[store.state.page]!.dragXOffset = CGFloat(-geometry.size.width - 4) * CGFloat(store.state.pageOptions[store.state.page]!.dragIndex)
}

func selectMainMenu(geometry: GeometryProxy, store: Store) {
    if store.state.tempActiveSubView == "" {
        store.state.tempActiveSubView = MENU_VIEWS[store.state.page]![0]
    }

    store.state.activeSubView = store.state.tempActiveSubView
    store.state.pageOptions[store.state.page]!.dragIndex = DRAG_INDEXES[store.state.activeSubView] ?? 0

    slide(geometry: geometry, store: store)
}

func highlightFirstLogItem(store: Store) {
    let sessionIds = getSessionIds(sessions: store.state.sessions)

    if sessionIds.count > 0 {
        store.state.selectedSessionId = sessionIds[sessionIds.count - 1]
    }
}

func getAverageMetricValue(
    timeseries: ReadingContainer,
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

func getChartDomain(
    timeseries: ReadingContainer,
    allProgressData: [String: [ProgressData]]
) -> ChartDomain {
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

func getChartableMetrics(timeseries: ReadingContainer) -> [String: Float] {
    var chartableMetrics: [String: Float] = [:]

    timeseries.keys.forEach {
        let avgValue = getAverageMetricValue(timeseries: timeseries, metric: $0)

        if avgValue > 0 {
            chartableMetrics[$0] = avgValue
        }
    }

    return chartableMetrics
}

func getTimeseriesData(
    uuid: String,
    timeUnit: TimeUnit
) -> ReadingContainer {
    var result: ReadingContainer = [:]

    do {
        try readFromFolder(uuid + "-" + timeUnit.rawValue)
            .sorted { $0 < $1 }
            .forEach {
                let url = getDocumentsDirectory()
                    .appendingPathComponent(uuid + "-" + timeUnit.rawValue)
                    .appendingPathComponent($0)
                let data = readFromFile(url: url)
                let timeseries = try JSONDecoder().decode(ReadingContainer.self, from: data)

                timeseries.keys.forEach {
                    let readings = timeseries[$0]!

                    if result[$0] == nil {
                        result[$0] = []
                    }

                    result[$0] = result[$0]! + readings
                }
            }
    }
    catch {}

    return result
}

func parseScale(
    timeseries: ReadingContainer,
    chartScales: [String: Bool]
) -> ReadingContainer {
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
    let index = getSessionIds(sessions: store.state.sessions).reversed()
        .firstIndex(where: { $0 == store.state.selectedSessionId }) ?? -1

    if index > -1 {
        store.state.selectedSession = store.state.sessions.reversed()[index]
        clearTimeseries(store: store)

        let timeseriesData = getTimeseriesData(
            uuid: store.state.selectedSession.uuid,
            timeUnit: TimeUnit.Minute
        )

        store.state.timeseries = timeseriesData
        store.state.chartableMetrics = getChartableMetrics(timeseries: timeseriesData)
        store.state.timeseries = parseScale(timeseries: store.state.timeseries, chartScales: store.state.chartScales)

        let allProgressData: [String: [ProgressData]] = getAllProgressData(store: store)
        store.state.chartDomain = getChartDomain(timeseries: store.state.timeseries, allProgressData: allProgressData)
        store.state.seriesData = getSeriesData(store: store, allProgressData: allProgressData)
        store.state.activeSubView = store.state.selectedSessionId
    }
}

func hasSessionLogs(store: Store) -> Bool {
    store.state.sessions.count > 0
}

func clearTimeseries(store: Store) {
    store.state.timeseries.keys.forEach {
        store.state.timeseries[$0] = []
    }
}

func deleteSession(store: Store, sessionId: String) {
    var sessionIndex = -1

    for (index, item) in getSessionIds(sessions: store.state.sessions).enumerated() {
        if item == sessionId {
            sessionIndex = index
        }
    }
    
    if sessionIndex > -1 {
        deleteSession(store.state.sessions[sessionIndex])
        store.state.sessions.remove(at: sessionIndex)
    }

    if !hasSessionLogs(store: store) {
        store.state.activeSubView = MENU_VIEWS[store.state.page]![0]
    }
    else {
        store.state.activeSubView = SubView.Log.rawValue
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
