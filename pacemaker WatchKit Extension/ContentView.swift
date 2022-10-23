import SwiftUI
import Charts
import AVFAudio
import AVFoundation
import Foundation

/*
Spacer(minLength: 24)

Chart(getSeriesData()) { series in
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
 */

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
        "Log": 0
    ]
    let views: [String] = ["Controller", "Status", "Log"]
    let crownMultiplier: Float = 2
    let minimumMovementThreshold = CGFloat(10)

    func parseProgressData(metricData: [Update]) -> [ProgressData] {
        let startHour = Calendar.current.component(.hour, from: store.state.sessionStartTime)

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
        let metrics = store.state.updates[metric] ?? []
        let currentMetricValue = String(metrics.count > 0 ? String(format: "%.1f", metrics[metrics.count - 1].value) : "")
        return currentMetricValue
    }

    func getSeriesData() -> [SeriesData] {
        let breathMetrics = store.state.updates["breath"] ?? []
        let heartRateMetrics = store.state.updates["heartRate"] ?? []
        let stepMetrics = store.state.updates["step"] ?? []
        let speedMetrics = store.state.updates["speed"] ?? []

        let lastBreathMetricValue = getCurrentMetricValue(metric: "breath")
        let lastHeartRateMetricValue = getCurrentMetricValue(metric: "heartRate")
        let lastStepMetricValue = getCurrentMetricValue(metric: "step")
        let lastSpeedhMetricValue = getCurrentMetricValue(metric: "speed")

        let breath: [ProgressData] = parseProgressData(metricData: breathMetrics)

        parsedData.max = breath.map { Float($0.value) }.max() ?? Float(0)

        let heartRate: [ProgressData] = parseProgressData(metricData: heartRateMetrics)
        let step: [ProgressData] = parseProgressData(metricData: stepMetrics)
        let speed: [ProgressData] = parseProgressData(metricData: speedMetrics)

        return [
            .init(metric: lastBreathMetricValue + " breath (s)", data: breath),
            .init(metric: lastHeartRateMetricValue + " heart rate (s)", data: heartRate),
            .init(metric: lastStepMetricValue + " steps (s)", data: step),
            .init(metric: lastSpeedhMetricValue + " speed (m/s)", data: speed)
        ]
    }

    func menuView(geometry: GeometryProxy) -> some View {
        Picker("", selection: $store.state.tempActiveSubView) {
            ForEach(views, id: \.self) {
                if $0 == store.state.tempActiveSubView {
                    Text($0)
                    .font(.system(size: 32))
                    .fontWeight(.bold)
                }
                else {
                    Text($0)
                    .font(.system(size: 24))
                }
            }
        }
        .padding(.horizontal, store.state.ui.horizontalPadding)
        .padding(.vertical, store.state.ui.verticalPadding)
        .frame(width: geometry.size.width, height: geometry.size.height * store.state.ui.height)
        .clipped()
        .onTapGesture {
            if store.state.tempActiveSubView == "" {
                store.state.tempActiveSubView = views[0]
            }
            store.state.activeSubView = store.state.tempActiveSubView
            dragIndex = dragIndexes[store.state.activeSubView] ?? 0
        }
    }

    func controllerView(geometry: GeometryProxy) -> some View {
        VStack() {
            HStack {
                menuButton(
                    geometry: geometry,
                    label: "Pace",
                    value: store.state.metricTypes[store.state.selectedMetricTypeIndex].label,
                    unit: "per " + store.state.metricTypes[store.state.selectedMetricTypeIndex].unit,
                    valueColor: store.state.metricTypes[store.state.selectedMetricTypeIndex].valueColor,
                    isShort: true,
                    isTall: false,
                    action: {
                        store.state.selectedMetricTypeIndex = store.state.selectedMetricTypeIndex + 1 < store.state.metricTypes.count
                            ? store.state.selectedMetricTypeIndex + 1
                            : 0
                    }
                )

                Spacer(minLength: 8)

                menuButton(
                    geometry: geometry,
                    label: "Rhythm",
                    value: "\(String(format: "%.1f", Double(store.state.selectedInRhythm) / 10)):\(String(format: "%.1f", Double(store.state.selectedOutRhythm) / 10))",
                    unit: "per pace",
                    valueColor: store.state.metricTypes[store.state.selectedMetricTypeIndex].valueColor,
                    isTall: false,
                    action: { store.state.activeSubView = "Rhythm" }
                )
            }

            Spacer(minLength: 8)

            HStack {
                menuButton(
                    geometry: geometry,
                    label: "Session",
                    value: store.state.isSessionActive
                        ? "⚑"
                        : "◴",
                    unit: store.state.isSessionActive
                        ? store.state.sessionElapsedTime
                        : "Stopped",
                    isTall: false,
                    action: {
                        if !store.state.isSessionActive {
                            player.startSession()
                        }
                        else {
                            store.state.activeSubView = "Confirm"
                        }
                    }
                )

                Spacer(minLength: 8)

                menuButton(
                    geometry: geometry,
                    label: "Playback",
                    value: store.state.isAudioPlaying ? "||" : "▶",
                    unit: store.state.isAudioPlaying ? "Playing" : "Paused",
                    index: Int(ceil(
                        convertRange(
                            value: Float(store.state.selectedVolume),
                            oldRange: [Float(AUDIO_RANGE[0]), Float(AUDIO_RANGE[1])],
                            newRange: [Float(0), Float(10)]
                        )) - 1
                    ),
                    maxIndex: Int(ceil(
                        convertRange(
                            value: Float(AUDIO_RANGE[1]),
                            oldRange: [Float(AUDIO_RANGE[0]), Float(AUDIO_RANGE[1])],
                            newRange: [Float(0), Float(10)]
                        )) - 1
                    ),
                    isTall: false,
                    isEnabled: store.state.isSessionActive,
                    action: {
                        player.togglePlay()
                    }
                )
            }
        }
        .focusable()
        .digitalCrownRotation(
            $store.state.selectedVolume,
            from: AUDIO_RANGE[0] - (AUDIO_RANGE[1] * crownMultiplier),
            through: AUDIO_RANGE[1] + (AUDIO_RANGE[1] * crownMultiplier),
            by: AUDIO_RANGE[1] / 100 * 3 * crownMultiplier,
            sensitivity: .high,
            isContinuous: true,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: store.state.selectedVolume) { value in
            if value < AUDIO_RANGE[0] {
                store.state.selectedVolume = AUDIO_RANGE[0]
            }
            else if value > AUDIO_RANGE[1] {
                store.state.selectedVolume = AUDIO_RANGE[1]
            }
         }
    }

    func statusView(geometry: GeometryProxy) -> some View {
        VStack {
            HStack {
                menuButton(
                    geometry: geometry,
                    label: "Heart rate",
                    value: String(format: "%.0f", store.state.valueByMetric(metric: store.state.metricTypes[store.state.selectedMetricTypeIndex].metric) * 60),
                    unit: "per minute",
                    valueColor: colorize(color: "red"),
                    isEnabled: false
                )

                Spacer(minLength: 8)

                menuButton(
                    geometry: geometry,
                    label: "Breath rate",
                    value: String(format: "%.0f", store.state.valueByMetric(metric: "breathRateMetric") * 60),
                    unit: "per minute",
                    valueColor: colorize(color: "green"),
                    isEnabled: false
                )
            }

            Spacer(minLength: 8)

            HStack {
                menuButton(
                    geometry: geometry,
                    label: "Step rate",
                    value: String(format: "%.0f", store.state.valueByMetric(metric: "stepMetric") * 60),
                    unit: "per minute",
                    valueColor: colorize(color: "blue"),
                    isEnabled: false
                )

                Spacer(minLength: 8)

                menuButton(
                    geometry: geometry,
                    label: "Speed",
                    value: String(format: "%.0f", store.state.valueByMetric(metric: "speedMetric") * 3.6),
                    unit: "km / h",
                    isEnabled: false
                )
            }
        }
    }

    func logView(geometry: GeometryProxy) -> some View {
        Group {}
    }

    func rhythmView(geometry: GeometryProxy) -> some View {
        Group {
            HStack {
                Picker("", selection: $store.state.selectedInRhythm) {
                    ForEach(store.state.rhythmRange, id: \.self) {
                        if $0 == store.state.selectedInRhythm {
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
                .onChange(of: store.state.selectedInRhythm) { value in
                    store.state.selectedInRhythm = value
                    store.state.selectedOutRhythm = value
                }
                
                Picker("", selection: $store.state.selectedOutRhythm) {
                    ForEach(store.state.rhythmRange, id: \.self) {
                        if $0 == store.state.selectedOutRhythm {
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
                .onChange(of: store.state.selectedOutRhythm) { value in
                    store.state.selectedOutRhythm = value
                }
            }
            .font(.system(size: store.state.ui.secondaryTextSize))
        }
    }

    func sessionStopConfirmationView(geometry: GeometryProxy) -> some View {
        VStack {
            HStack {
                Button(action: {
                    player.stopSession()
                    store.state.activeSubView = "Controller"
                }) {
                    Text("Discard")
                }
                .font(.system(size: 12))
                .fontWeight(.bold)
                .buttonStyle(.bordered)
                .tint(colorize(color: "red"))

                Button(action: {
                    player.stopSession()
                    store.state.activeSubView = "Controller"
                }) {
                    Text("Save")
                }
                .font(.system(size: 12))
                .fontWeight(.bold)
                .buttonStyle(.bordered)
                .tint(colorize(color: "green"))
            }

            HStack {
                Button(action: {
                    store.state.activeSubView = "Controller"
                }) {
                    Text("Cancel")
                }
                .font(.system(size: 12))
                .fontWeight(.bold)
                .buttonStyle(.bordered)
                .tint(colorize(color: "blue"))
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
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

                        case "Controller", "Status":
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

                                        if width > minimumMovementThreshold { return }
                                        else if width < -geometry.size.width { return }

                                        dragXOffset = CGSize(
                                            width: width,
                                            height: 0
                                        )
                                        wasChanged = true
                                    }
                                    .onEnded { _ in
                                        if !wasChanged { return }

                                        let padding = CGFloat(4)
                                        let width = CGFloat(dragIndex) * geometry.size.width

                                        if dragXOffset.width < -width {
                                            dragXOffset = CGSize(width: -geometry.size.width - padding, height: 0)
                                            dragIndex = 1
                                        }
                                        else if dragXOffset.width > -width {
                                            dragXOffset = CGSize(width: 0, height: 0)
                                            dragIndex = 0
                                        }
                                        else {
                                            dragXOffset = CGSize(
                                                width: width,
                                                height: 0
                                            )
                                        }

                                        switch(dragIndex) {
                                            case 0:
                                                store.state.activeSubView = "Controller"
                                            case 1:
                                                store.state.activeSubView = "Status"
                                            default:
                                                return
                                        }
                                    }
                            )

                        case "Log":
                            logView(geometry: geometry)

                        case "Rhythm":
                            rhythmView(geometry: geometry)

                        case "Confirm":
                            sessionStopConfirmationView(geometry: geometry)

                        default:
                            controllerView(geometry: geometry)
                    }
                }
                .font(.system(size: store.state.ui.secondaryTextSize))

                if store.state.activeSubView == "Controller" || store.state.activeSubView == "Status" {
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
