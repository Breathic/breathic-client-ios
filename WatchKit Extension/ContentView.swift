import SwiftUI
import Charts
import AVFAudio
import AVFoundation
import Foundation

struct ContentView: View {
    class ChartDomain {
        var xMin: Float = 0
        var xMax: Float = 0
        var yMin: Float = 0
        var yMax: Float = 0
    }

    @ObservedObject private var store: Store = .shared

    @State private var timeseries: [String: [Timeserie]] = [:]
    @State private var seriesData: [SeriesData] = []
    @State private var selectedSession = Session()
    @State private var dragIndex: Int = 0
    @State private var dragXOffset = CGSize.zero
    @State private var wasChanged = false

    let player = Player()
    let chartDomain = ChartDomain()
    let dragIndexes: [String: Int] = [
        "Controller": 0,
        "Status": 1,
        "Log": 0
    ]
    let mainMenuViews: [String] = ["Controller", "Status", "Log"]
    let crownMultiplier: Float = 2
    let slidePadding = CGFloat(4)

    init() {
        clearTimeseries()
    }

    func clearTimeseries() {
        store.state.timeseries.keys.forEach {
            timeseries[$0] = []
        }
    }

    func parseProgressData(metricData: [Timeserie]) -> [ProgressData] {
        let startHour = Calendar.current.component(.hour, from: selectedSession.startTime)
        let startMinute = Calendar.current.component(.minute, from: selectedSession.startTime)
        let startSecond = Calendar.current.component(.second, from: selectedSession.startTime)

        return metricData
            .map {
                let hours = Calendar.current.component(.hour, from: $0.timestamp)
                let minutes = Calendar.current.component(.minute, from: $0.timestamp)
                let seconds = Calendar.current.component(.second, from: $0.timestamp)
                let timestamp = (Int((minutes - startMinute) * 60 + (seconds - startSecond)) / 60) + ((hours - startHour) * 60)

                return ProgressData(timestamp: timestamp, value: $0.value)
            }
    }

    func getCurrentMetricValue(metric: String) -> String {
        let metrics = (timeseries[metric] ?? [])
        let average = metrics
            .map { $0.value }
            .reduce(0, +) / Float(metrics.count)

        return String(metrics.count > 0 ? String(format: "%.0f", average) : "")
    }

    func getSeriesData() -> [SeriesData] {
        let chartXAxisRightSpacingPct: Float = 8
        var _timeseries: [String: [ProgressData]] = [:]

        chartDomain.yMax = 0

        timeseries.keys.forEach {
            let progressData = parseProgressData(metricData: timeseries[$0] ?? [])

            _timeseries[$0] = progressData

            if progressData.count > 0 {
                chartDomain.xMin = Float(progressData[0].timestamp)
                chartDomain.xMax = Float(progressData[progressData.count - 1].timestamp) + Float(progressData[progressData.count - 1].timestamp) * chartXAxisRightSpacingPct / 100
            }

            let value: Float = progressData
                .map { Float($0.value) }.max() ?? Float(0)

            if value > chartDomain.yMax {
                chartDomain.yMax = value
            }
        }

        return _timeseries.keys.map {
            let avgValue = getCurrentMetricValue(metric: $0)
            let progressData: [ProgressData] = _timeseries[$0] ?? []

            return .init(metric: avgValue + " " + $0 + " avg", data: progressData)
        }
    }

    func slide(geometry: GeometryProxy) {
        dragXOffset = CGSize(width: (-geometry.size.width - slidePadding) * CGFloat(dragIndex), height: 0)
    }

    func selectMainMenu(geometry: GeometryProxy) {
        if store.state.tempActiveSubView == "" {
            store.state.tempActiveSubView = mainMenuViews[0]
        }

        store.state.activeSubView = store.state.tempActiveSubView
        dragIndex = dragIndexes[store.state.activeSubView] ?? 0
        slide(geometry: geometry)
    }

    func menuView(geometry: GeometryProxy) -> some View {
        VStack {
            Picker("", selection: $store.state.tempActiveSubView) {
                ForEach(mainMenuViews, id: \.self) {
                    if $0 == store.state.tempActiveSubView {
                        Text($0)
                            .font(.system(size: 18))
                            .fontWeight(.bold)
                    }
                    else {
                        Text($0)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(.horizontal, store.state.ui.horizontalPadding)
            .padding(.vertical, store.state.ui.verticalPadding)
            .frame(width: geometry.size.width, height: geometry.size.height * store.state.ui.height)
            .clipped()
            .onAppear() {
                store.state.tempActiveSubView = mainMenuViews[0]
            }
            .onTapGesture { selectMainMenu(geometry: geometry) }

            secondaryButton(text: "Select", color: "green", action: { selectMainMenu(geometry: geometry) })
        }
    }

    func getSessionUnit() -> String {
        if store.state.session.isActive {
            if store.state.isResumable { return "Resume" }
            else if store.state.elapsedTime.count > 0 { return store.state.elapsedTime }
            else { return " " }
        }
        else {
            return "Stopped"
        }
    }

    func controllerView(geometry: GeometryProxy) -> some View {
        VStack() {
            HStack {
                primaryButton(
                    geometry: geometry,
                    label: "Pace",
                    value: store.state.metricType.label,
                    unit: "per " + store.state.metricType.unit,
                    valueColor: store.state.metricType.valueColor,
                    isShort: true,
                    isTall: false,
                    action: {
                        store.state.session.metricTypeIndex = store.state.session.metricTypeIndex + 1 < METRIC_TYPES.count
                            ? store.state.session.metricTypeIndex + 1
                            : 0
                        store.state.metricType = METRIC_TYPES[store.state.session.metricTypeIndex]
                    }
                )

                Spacer(minLength: 8)

                primaryButton(
                    geometry: geometry,
                    label: "Rhythm",
                    value: "\(String(format: "%.1f", Double(store.state.session.inRhythm) / 10)):\(String(format: "%.1f", Double(store.state.session.outRhythm) / 10))",
                    unit: "per pace",
                    valueColor: store.state.metricType.valueColor,
                    isTall: false,
                    action: { store.state.activeSubView = "Rhythm" }
                )
            }

            Spacer(minLength: 8)

            HStack {
                primaryButton(
                    geometry: geometry,
                    label: "Session",
                    value: store.state.session.isActive
                        ? "⚑"
                        : "◴",
                    unit: getSessionUnit(),
                    isTall: false,
                    action: {
                        if !store.state.session.isActive || store.state.isResumable { player.start() }
                        else { store.state.activeSubView = "Confirm" }
                    }
                )

                Spacer(minLength: 8)

                primaryButton(
                    geometry: geometry,
                    label: "Audio",
                    value: store.state.session.isAudioPlaying
                        ? "||"
                        : "▶",
                    unit: store.state.session.isAudioPlaying
                        ? Float(store.state.session.volume) > 0
                            ? "Playing"
                            : "Muted"
                        : "Paused",
                    index: Int(ceil(
                        convertRange(
                            value: Float(store.state.session.volume),
                            oldRange: [Float(VOLUME_RANGE[0]), Float(VOLUME_RANGE[1])],
                            newRange: [Float(0), Float(10)]
                        )) - 1
                    ),
                    maxIndex: Int(ceil(
                        convertRange(
                            value: Float(VOLUME_RANGE[1]),
                            oldRange: [Float(VOLUME_RANGE[0]), Float(VOLUME_RANGE[1])],
                            newRange: [Float(0), Float(10)]
                        )) - 1
                    ),
                    isTall: false,
                    isEnabled: store.state.isAudioSessionLoaded && store.state.session.isActive,
                    opacity: store.state.isAudioSessionLoaded && store.state.session.isActive ? 1 : 0.33,
                    action: {
                        player.togglePlay()
                    }
                )
            }
        }
        .focusable()
        .digitalCrownRotation(
            $store.state.session.volume,
            from: VOLUME_RANGE[0] - (VOLUME_RANGE[1] * crownMultiplier),
            through: VOLUME_RANGE[1] + (VOLUME_RANGE[1] * crownMultiplier),
            by: VOLUME_RANGE[1] / 100 * 3 * crownMultiplier,
            sensitivity: .high,
            isContinuous: true,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: store.state.session.volume) { value in
            if value < VOLUME_RANGE[0] {
                store.state.session.volume = VOLUME_RANGE[0]
            }
            else if value > VOLUME_RANGE[1] {
                store.state.session.volume = VOLUME_RANGE[1]
            }
        }
    }

    func statusView(geometry: GeometryProxy) -> some View {
        VStack {
            HStack {
                primaryButton(
                    geometry: geometry,
                    label: "Heartbeats",
                    value: String(format: "%.0f", store.state.valueByMetric(metric: store.state.metricType.metric)),
                    unit: "per minute",
                    valueColor: colorize(color: "red"),
                    isEnabled: false
                )

                Spacer(minLength: 8)

                primaryButton(
                    geometry: geometry,
                    label: "Breaths",
                    value: String(format: "%.0f", store.state.valueByMetric(metric: "breath")),
                    unit: "per minute",
                    valueColor: colorize(color: "green"),
                    isEnabled: false
                )
            }

            Spacer(minLength: 8)

            HStack {
                primaryButton(
                    geometry: geometry,
                    label: "Steps",
                    value: String(format: "%.0f", store.state.valueByMetric(metric: "step")),
                    unit: "per minute",
                    valueColor: colorize(color: "blue"),
                    isEnabled: false
                )

                Spacer(minLength: 8)

                primaryButton(
                    geometry: geometry,
                    label: "Speed",
                    value: String(format: "%.0f", store.state.valueByMetric(metric: "speed")),
                    unit: "km / h",
                    isEnabled: false
                )
            }
        }
    }

    func hasSessionLogs() -> Bool {
        return store.state.sessionLogs.count > 0
    }

    func highlightFirstLogItem() {
        let sessionLogIds = getSessionIds(sessions: store.state.sessionLogs)

        if sessionLogIds.count > 0 {
            store.state.selectedSessionId = sessionLogIds[sessionLogIds.count - 1]
        }
    }

    func deleteSession(sessionId: String) {
        var sessionIndex = -1

        for (index, item) in getSessionIds(sessions: store.state.sessionLogs).enumerated() {
            if item == sessionId {
                sessionIndex = index
            }
        }

        if sessionIndex > -1 {
            store.state.sessionLogs.remove(at: sessionIndex)
            writeSessionLogs(sessionLogs: store.state.sessionLogs)
            store.state.sessionLogIds = getSessionIds(sessions: store.state.sessionLogs)
        }

        if !hasSessionLogs() {
            store.state.activeSubView = mainMenuViews[0]
        }
        else {
            store.state.activeSubView = "Log"
            highlightFirstLogItem()
        }
    }

    func onLogSelect() {
        let index = store.state.sessionLogIds
            .firstIndex(where: { $0 == store.state.selectedSessionId }) ?? -1

        if index > -1 {
            selectedSession = store.state.sessionLogs[index]
            clearTimeseries()

            var addedMinutes = 0
            while(selectedSession.startTime.adding(minutes: addedMinutes) <= selectedSession.endTime) {
                let id = getTimeseriesUpdateId(uuid: selectedSession.uuid, date: selectedSession.startTime.adding(minutes: addedMinutes))
                let _timeseries = readTimeseries(key: id)

                timeseries.keys.forEach {
                    if _timeseries[$0] != nil {
                        timeseries[$0] = timeseries[$0]! + _timeseries[$0]!
                    }
                }

                addedMinutes = addedMinutes + 1
            }

            seriesData = getSeriesData()
            store.state.activeSubView = store.state.selectedSessionId
        }
    }

    func logView(geometry: GeometryProxy) -> some View {
        VStack {
            Picker("", selection: $store.state.selectedSessionId) {
                ForEach(store.state.sessionLogIds.reversed(), id: \.self) {
                    if $0 == store.state.selectedSessionId {
                        Text($0)
                            .font(.system(size: 14))
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                    else {
                        Text($0)
                            .font(.system(size: 14))
                            .frame(maxWidth: .infinity, alignment: .topLeading)
                    }
                }
            }
            .padding(.horizontal, store.state.ui.horizontalPadding)
            .padding(.vertical, store.state.ui.verticalPadding)
            .frame(width: geometry.size.width, height: geometry.size.height * store.state.ui.height)
            .clipped()
            .onAppear() { highlightFirstLogItem() }
            .onTapGesture { onLogSelect() }

            if hasSessionLogs() {
                HStack {
                    secondaryButton(text: "Delete", color: "red", action: { store.state.activeSubView = "Delete" })
                    secondaryButton(text: "Select", color: "green", action: { onLogSelect() })
                }
            }
        }
    }

    func rhythmView(geometry: GeometryProxy) -> some View {
        VStack {
            HStack {
                Picker("", selection: $store.state.session.inRhythm) {
                    ForEach(Array(RHYTHM_RANGE[0]...RHYTHM_RANGE[1]), id: \.self) {
                        if $0 == store.state.session.inRhythm {
                            Text(String(format: "%.1f", Double($0) / 10))
                                .font(.system(size: 32))
                                .fontWeight(.bold)
                        }
                        else {
                            Text(String(format: "%.1f", Double($0) / 10))
                                .font(.system(size: 24))
                        }
                    }
                }
                .padding(.horizontal, store.state.ui.horizontalPadding)
                .padding(.vertical, store.state.ui.verticalPadding)
                .frame(width: geometry.size.width * store.state.ui.width, height: geometry.size.height * store.state.ui.height)
                .clipped()
                .onChange(of: store.state.session.inRhythm) { value in
                    store.state.session.inRhythm = value
                    store.state.session.outRhythm = value
                }

                Picker("", selection: $store.state.session.outRhythm) {
                    ForEach(Array(RHYTHM_RANGE[0]...RHYTHM_RANGE[1]), id: \.self) {
                        if $0 == store.state.session.outRhythm {
                            Text(String(format: "%.1f", Double($0) / 10))
                                .font(.system(size: 32))
                                .fontWeight(.bold)
                        }
                        else {
                            Text(String(format: "%.1f", Double($0) / 10))
                                .font(.system(size: 24))
                        }
                    }
                }
                .padding(.horizontal, store.state.ui.horizontalPadding)
                .padding(.vertical, store.state.ui.verticalPadding)
                .frame(width: geometry.size.width * store.state.ui.width, height: geometry.size.height * store.state.ui.height)
                .clipped()
                .onChange(of: store.state.session.outRhythm) { value in
                    store.state.session.outRhythm = value
                }
            }
            .font(.system(size: store.state.ui.secondaryTextSize))

            secondaryButton(text: "Set", color: "green", action: { store.state.activeSubView = mainMenuViews[0] })
        }
    }

    func sessionStopConfirmationView(geometry: GeometryProxy) -> some View {
        VStack {
            HStack {
                Button(action: {
                    player.pause()
                    store.state.session.stop()
                    store.state.activeSubView = mainMenuViews[0]
                }) {
                    Text("Discard")
                }
                .font(.system(size: 12))
                .fontWeight(.bold)
                .buttonStyle(.bordered)
                .tint(colorize(color: "red"))

                Button(action: {
                    player.stop()
                    store.state.activeSubView = mainMenuViews[0]
                }) {
                    Text("Save")
                }
                .font(.system(size: 12))
                .fontWeight(.bold)
                .buttonStyle(.bordered)
                .tint(colorize(color: "green"))
            }

            Text("Finish session?")
                .font(.system(size: 16))
                .frame(maxHeight: .infinity, alignment: .center)

            HStack {
                Button(action: {
                    store.state.activeSubView = mainMenuViews[0]
                }) {
                    Text("Cancel")
                }
                .font(.system(size: 12))
                .fontWeight(.bold)
                .buttonStyle(.bordered)
                .tint(colorize(color: "blue"))
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .edgesIgnoringSafeArea(.all)
        }
    }

    func overviewView(geometry: GeometryProxy) -> some View {
        HStack {
            Spacer(minLength: 8)

            Chart(seriesData) { series in
                ForEach(series.data) { element in
                    LineMark(
                        x: .value("Time", element.timestamp),
                        y: .value("Value", element.value)
                    )
                    .foregroundStyle(by: .value("Metric", series.metric))
                }
            }
            .chartXScale(domain: floor(chartDomain.xMin)...ceil(chartDomain.xMax))
            .chartYScale(domain: floor(chartDomain.yMin)...ceil(chartDomain.yMax))
            .frame(height: geometry.size.height + 16)
        }
    }

    func deleteSessionConfirmationView(geometry: GeometryProxy) -> some View {
        VStack {
            HStack {
                Button(action: {
                    deleteSession(sessionId: store.state.selectedSessionId)
                }) {
                    Text("Delete")
                }
                .font(.system(size: 12))
                .fontWeight(.bold)
                .buttonStyle(.bordered)
                .tint(colorize(color: "red"))

                Button(action: {
                    store.state.activeSubView = "Log"
                }) {
                    Text("Cancel")
                }
                .font(.system(size: 12))
                .fontWeight(.bold)
                .buttonStyle(.bordered)
                .tint(colorize(color: "blue"))
            }
            .frame(maxHeight: .infinity, alignment: .topLeading)

            Text("Delete session from " + store.state.selectedSessionId + "?")
            .font(.system(size: 16))
            .frame(maxHeight: .infinity, alignment: .bottom)
        }
    }

    func detectOverviewSelection() -> Bool {
        return store.state.activeSubView == store.state.selectedSessionId
    }

    var body: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in
                VStack() {
                    Spacer(minLength: 4)

                    switch(store.state.activeSubView) {
                        case "Menu":
                            menuView(geometry: geometry)

                        case mainMenuViews[0], "Controller", "Status":
                            HStack {
                                controllerView(geometry: geometry)
                                statusView(geometry: geometry)
                            }
                            .offset(x: Double(dragXOffset.width))
                            .highPriorityGesture(
                                DragGesture()
                                    .onChanged { gesture in
                                        wasChanged = false

                                        let width = gesture.translation.width + (CGFloat(-dragIndex) * geometry.size.width)

                                        if width > 0 { return }  // Stop drag from the left.
                                        else if width < -geometry.size.width { return } // Stop drag from the right.

                                        dragXOffset = CGSize(
                                            width: width,
                                            height: 0
                                        )
                                        wasChanged = true
                                    }
                                    .onEnded { _ in
                                        if !wasChanged { return }

                                        let width = CGFloat(dragIndex) * geometry.size.width

                                        if dragXOffset.width < -width {
                                            dragIndex = 1
                                            store.state.activeSubView = "Status"
                                        }
                                        else if dragXOffset.width > -width {
                                            dragIndex = 0
                                            store.state.activeSubView = mainMenuViews[0]
                                        }
                                        else {
                                            dragXOffset = CGSize(
                                                width: width,
                                                height: 0
                                            )
                                        }

                                        slide(geometry: geometry)
                                    }
                            )

                        case "Log":
                            logView(geometry: geometry)

                        case "Rhythm":
                            rhythmView(geometry: geometry)

                        case "Confirm":
                            sessionStopConfirmationView(geometry: geometry)

                        case "Delete":
                            deleteSessionConfirmationView(geometry: geometry)

                        case store.state.selectedSessionId:
                            overviewView(geometry: geometry)

                        default:
                            controllerView(geometry: geometry)
                    }
                }
                .font(.system(size: store.state.ui.secondaryTextSize))

                if store.state.activeSubView == mainMenuViews[0] || store.state.activeSubView == "Controller" || store.state.activeSubView == "Status" {
                    ZStack {
                        HStack {
                            DottedIndicator(index: dragIndex, maxIndex: 1, direction: "horizontal")
                        }
                        .frame(height: geometry.size.height + 20, alignment: .bottom)
                    }
                    .frame(width: geometry.size.width, alignment: .center)
                }
            }
        }.toolbar(content: {
            ToolbarItem(placement: .cancellationAction) {
                Button(
                    action: {
                        let isOverviewSelected = detectOverviewSelection()

                        store.state.activeSubView = store.state.activeSubView != "Menu"
                            ? "Menu"
                            : mainMenuViews[0]
                        store.state.activeSubView = isOverviewSelected
                            ? "Log"
                            : store.state.activeSubView
                    },
                    label: {
                        Text("☰ " + store.state.activeSubView.components(separatedBy: " (")[0]) // Remove duration when overview.
                            .font(.system(size: 12))
                    }
                )
            }
        })
    }
}
