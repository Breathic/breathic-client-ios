import SwiftUI
import Charts
import AVFAudio
import AVFoundation
import Foundation

struct ContentView: View {
    @ObservedObject private var store: AppStore = .shared

    let player = Player()
    let parsedData: ParsedData = ParsedData()

    @State private var dragIndex: Int = 0
    @State private var dragXOffset = CGSize.zero
    @State private var wasChanged = false

    let dragIndexes: [String: Int] = [
        "Controller": 0,
        "Status": 1,
        "Log": 0,
        "Graph": 0,
    ]
    let views: [String] = ["Controller", "Status", "Log"]
    let crownMultiplier: Float = 2
    let minimumMovementThreshold = CGFloat(10)
    let slidePadding = CGFloat(4)
    @State private var timeseries: [String: [Timeserie]] = [
        "breath": [],
        "heart": [],
        "step": [],
        "speed": []
    ]
    @State private var seriesData: [SeriesData] = []
    @State private var selectedSession = Session()

    func parseProgressData(metricData: [Timeserie]) -> [ProgressData] {
        let startHour = Calendar.current.component(.hour, from: selectedSession.startTime)

        return Array(metricData.suffix(60 * 10))
            .map {
                let hours = Calendar.current.component(.hour, from: $0.timestamp)
                let minutes = Calendar.current.component(.minute, from: $0.timestamp)
                let seconds = Calendar.current.component(.second, from: $0.timestamp)
                let timestamp = (Int(minutes * 60 + seconds) / 60) + ((hours - startHour) * 60)
                return ProgressData(timestamp: timestamp, value: $0.value)
            }
    }

    func convert(data: [ProgressData], range: [Float]) -> [ProgressData] {
        let min = data.map { Float($0.value) }.min() ?? Float(0)
        let max = data.map { Float($0.value) }.max() ?? Float(0)

        return data.map {
            let progressData = ProgressData(
                timestamp: $0.timestamp,
                value: convertRange(
                    value: $0.value,
                    oldRange: [min, max],
                    newRange: [range[0], range[1]]
                )
            )

            return progressData
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
        var _timeseries: [String: [ProgressData]] = [:]

        parsedData.max = 0

        timeseries.keys.forEach {
            _timeseries[$0] = parseProgressData(
                metricData: timeseries[$0] ?? []
            )

            let value: Float = (_timeseries[$0] ?? [])
                .map { Float($0.value) }.max() ?? Float(0)
            if value > parsedData.max {
                parsedData.max = value
            }
        }

        return _timeseries.keys.map {
            let avgValue = getCurrentMetricValue(metric: $0)
            let progressData: [ProgressData] = _timeseries[$0] ?? []

            return .init(metric: avgValue + " " + $0, data: progressData)
        }
    }

    func slide(geometry: GeometryProxy) {
        dragXOffset = CGSize(width: (-geometry.size.width - slidePadding) * CGFloat(dragIndex), height: 0)
    }

    func selectMainMenu(geometry: GeometryProxy) {
        if store.state.tempActiveSubView == "" {
            store.state.tempActiveSubView = views[0]
        }

        store.state.activeSubView = store.state.tempActiveSubView
        dragIndex = dragIndexes[store.state.activeSubView] ?? 0
        slide(geometry: geometry)
    }

    func menuView(geometry: GeometryProxy) -> some View {
        VStack {
            Picker("", selection: $store.state.tempActiveSubView) {
                ForEach(views, id: \.self) {
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
                store.state.tempActiveSubView = views[0]
            }
            .onTapGesture { selectMainMenu(geometry: geometry) }

            secondaryButton(text: "Select", color: "green", action: { selectMainMenu(geometry: geometry) })
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
                    value: store.state.isAudioSessionLoaded && store.state.session.isActive
                    ? "⚑"
                    : "◴",
                    unit: store.state.isAudioSessionLoaded && store.state.session.isActive
                    ? store.state.elapsedTime
                    : "Stopped",
                    isTall: false,
                    action: {
                        if store.state.isAudioSessionLoaded && store.state.session.isActive {
                            store.state.activeSubView = "Confirm"
                        }
                        else {
                            player.start()
                        }
                    }
                )

                Spacer(minLength: 8)

                primaryButton(
                    geometry: geometry,
                    label: "Playback",
                    value: store.state.isAudioPlaying ? "||" : "▶",
                    unit: store.state.isAudioPlaying ? "Playing" : "Paused",
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
                    label: "Heart rate",
                    value: String(format: "%.0f", store.state.valueByMetric(metric: store.state.metricType.metric)),
                    unit: "per minute",
                    valueColor: colorize(color: "red"),
                    isEnabled: false
                )

                Spacer(minLength: 8)

                primaryButton(
                    geometry: geometry,
                    label: "Breath rate",
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
                    label: "Step rate",
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
            store.state.activeSubView = views[0]
        }
        else {
            store.state.activeSubView = "Log"
            highlightFirstLogItem()
        }
    }

    func logView(geometry: GeometryProxy) -> some View {
        VStack {
            Picker("", selection: $store.state.selectedSessionId) {
                ForEach(store.state.sessionLogIds.reversed(), id: \.self) {
                    if $0 == store.state.selectedSessionId {
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
            .onAppear() { highlightFirstLogItem() }
            .onTapGesture { }

            if hasSessionLogs() {
                HStack {
                    secondaryButton(text: "Delete", color: "red", action: { store.state.activeSubView = "Delete" })
                    secondaryButton(text: "Select", color: "green", action: {
                        let index = store.state.sessionLogIds
                            .firstIndex(where: { $0 == store.state.selectedSessionId }) ?? -1

                        if index > -1 {
                            selectedSession = store.state.sessionLogs[index]
                            timeseries.keys.forEach {
                                timeseries[$0] = []
                            }

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
                            store.state.activeSubView = "Graph"
                        }
                    })
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

            secondaryButton(text: "Set", color: "green", action: { store.state.activeSubView = views[0] })
        }
    }

    func sessionStopConfirmationView(geometry: GeometryProxy) -> some View {
        VStack {
            HStack {
                Button(action: {
                    player.pause()
                    store.state.session.stop()
                    store.state.activeSubView = views[0]
                }) {
                    Text("Discard")
                }
                .font(.system(size: 12))
                .fontWeight(.bold)
                .buttonStyle(.bordered)
                .tint(colorize(color: "red"))

                Button(action: {
                    player.stop()
                    store.state.activeSubView = views[0]
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
                    store.state.activeSubView = views[0]
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

    func graphView(geometry: GeometryProxy) -> some View {
        VStack {
            Spacer(minLength: 24)

            Chart(seriesData) { series in
                ForEach(series.data) { element in
                    LineMark(
                        x: .value("Time", element.timestamp),
                        y: .value("Value", element.value)
                    )
                    .foregroundStyle(by: .value("Metric", series.metric))
                }
            }
            .chartYScale(domain: floor(parsedData.min)...ceil(parsedData.max))
            .frame(height: geometry.size.height - 8)
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
            }

            Text("Delete session from " + store.state.selectedSessionId + "?")
            .font(.system(size: 16))
            .frame(maxHeight: .infinity, alignment: .center)

            HStack {
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
            .frame(maxHeight: .infinity, alignment: .bottom)
            .edgesIgnoringSafeArea(.all)
        }
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

                        case views[0], "Controller", "Status":
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

                                        if width > minimumMovementThreshold { return }  // Stop drag from the left.
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
                                            store.state.activeSubView = views[0]
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

                        case "Graph":
                            graphView(geometry: geometry)

                        default:
                            controllerView(geometry: geometry)
                    }
                }
                .font(.system(size: store.state.ui.secondaryTextSize))

                if store.state.activeSubView == views[0] || store.state.activeSubView == "Controller" || store.state.activeSubView == "Status" {
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
                        store.state.activeSubView = store.state.activeSubView != "Menu"
                            ? "Menu"
                            : views[0]
                    },
                    label: { Text("☰ " + store.state.activeSubView).font(.system(size: 14)) }
                )
            }
        })
    }
}
