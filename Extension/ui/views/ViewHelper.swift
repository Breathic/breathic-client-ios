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
    store.state.dragXOffset = CGSize(width: (-geometry.size.width - 4) * CGFloat(store.state.dragIndex), height: 0)
}

func selectMainMenu(geometry: GeometryProxy, store: Store) {
    if store.state.tempActiveSubView == "" {
        store.state.tempActiveSubView = MAIN_MENU_VIEWS[0]
    }

    store.state.activeSubView = store.state.tempActiveSubView
    store.state.dragIndex = DRAG_INDEXES[store.state.activeSubView] ?? 0
    slide(geometry: geometry, store: store)
}

func highlightFirstLogItem(store: Store) {
    let sessionLogIds = getSessionIds(sessions: store.state.sessionLogs)

    if sessionLogIds.count > 0 {
        store.state.selectedSessionId = sessionLogIds[sessionLogIds.count - 1]
    }
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

                store.state.timeseries.keys.forEach {
                    if _timeseries[$0] != nil {
                        store.state.timeseries[$0] = store.state.timeseries[$0]! + _timeseries[$0]!
                    }
                }
            }
            catch {}

            addedMinutes = addedMinutes + 1
        }

        let result = getSeriesData(timeseries: store.state.timeseries, startTime: store.state.selectedSession.startTime)
        store.state.seriesData = result.0
        store.state.chartDomain.xMin = result.1.xMin
        store.state.chartDomain.xMax = result.1.xMax
        store.state.chartDomain.yMin = result.1.yMin
        store.state.chartDomain.yMax = result.1.yMax

        store.state.activeSubView = store.state.selectedSessionId
    }
}

func hasSessionLogs(store: Store) -> Bool {
    return store.state.sessionLogs.count > 0
}

func clearTimeseries(store: Store) {
    store.state.readings.keys.forEach {
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
        store.state.activeSubView = MAIN_MENU_VIEWS[0]
    }
    else {
        store.state.activeSubView = "Log"
        highlightFirstLogItem(store: store)
    }
}

func isOverviewSelected(store: Store) -> Bool {
    return store.state.activeSubView == store.state.selectedSessionId
}
