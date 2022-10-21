import SwiftUI
import Charts
import AVFAudio
import AVFoundation
import Foundation

struct ProgressData: Identifiable {
    let timestamp: Int
    let value: Float
    var id: Int { timestamp }
}

struct SeriesData: Identifiable {
    let metric: String
    let data: [ProgressData]
    var id: String { metric }
}

class ParsedData {
    var min: Float = 0
    var max: Float = 0
}

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

    @State private var dragIndex = 0
    @State private var dragXOffset = CGSize.zero
    @State private var wasChanged = false

    let minimumMovementThreshold = CGFloat(10)

    func parseProgressData(metricData: [Update]) -> [ProgressData] {
        return Array(metricData.suffix(60 * 10))
            .map {
                let hours = Calendar.current.component(.hour, from: $0.timestamp)
                let minutes = Calendar.current.component(.minute, from: $0.timestamp)
                let seconds = Calendar.current.component(.second, from: $0.timestamp)
                let timestamp = (Int(minutes * 60 + seconds) / 60) + ((hours - store.state.startHour) * 60)
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

    func menuButton(
        geometry: GeometryProxy,
        label: String = "",
        value: String = "",
        unit: String = "",
        valueColor: Color = Color.white,
        isWide: Bool = false,
        isShort: Bool = false,
        isTall: Bool = true,
        isActive: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void = {}
    ) -> some View {
        Button(action: action) {
            VStack {
                Spacer(minLength: 4)

                if label.count > 0 {
                    HStack {
                        Text(label)
                        .font(.system(size: 10))
                    }
                    .frame(
                        maxWidth: .infinity,
                        maxHeight: .infinity,
                        alignment: .topLeading
                    )
                }

                if value.count > 0 {
                    Spacer(minLength: 8)

                    Text(value)
                    .font(.system(size: isTall ? 32 : isShort ? 12 : 14))
                    .fontWeight(.bold)
                    .foregroundColor(valueColor)
                }

                if unit.count > 0 {
                    Text(unit)
                    .frame(maxWidth: .infinity, alignment: Alignment.center)
                    .font(.system(size: 8))
                }

                Rectangle()
                .fill(isActive ? .white : .black)
                .frame(width: geometry.size.width / 3 - 4, height: 2)

                Spacer(minLength: 4)
            }
        }
        .frame(width: geometry.size.width / (isWide ? 1 : 2) - 4, height: geometry.size.height / 2 - 4)
        .foregroundColor(.white)
        .tint(.black)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.gray, lineWidth: isEnabled ? store.state.ui.borderLineWidth : 0)
        )
        .disabled(!isEnabled)
    }

    func controllerView(geometry: GeometryProxy) -> some View {
        VStack {
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
                    label: "Volume",
                    value: String(store.state.selectedVolume),
                    unit: store.state.selectedVolume == 0 ? "muted" : "⠀", // Emtpy char for filling up space.
                    isTall: false,
                    action: {
                        store.state.activeSubView = "Volume"
                    }
                )

                Spacer(minLength: 8)

                menuButton(
                    geometry: geometry,
                    label: "Playback",
                    value: store.state.isAudioPlaying ? "||" : "▶",
                    unit: store.state.isAudioPlaying ? "Playing" : "Paused",
                    isTall: false,
                    action: {
                        player.togglePlay()
                    }
                )
            }
        }
    }

    func metricsView(geometry: GeometryProxy) -> some View {
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

    func progressView(geometry: GeometryProxy) -> some View {
        Group {
            VStack {
                if !store.state.isSessionActive {
                    Button(action: { store.state.isSessionActive = true }) {
                        Text("Start session")
                    }
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                    .buttonStyle(.bordered)
                    .tint(Color.green)
                }
                else {
                    Button(action: { store.state.isSessionActive = false }) {
                        Text("Finish session")
                    }
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                    .buttonStyle(.bordered)
                    .tint(Color.red)
                }
            }
        }
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

    func volumeView(geometry: GeometryProxy) -> some View {
            Group {
                Picker("", selection: $store.state.selectedVolume) {
                    ForEach(Array(0...100), id: \.self) {
                        if $0 == store.state.selectedVolume {
                            Text(String($0))
                                .font(.system(size: 32))
                                .fontWeight(.bold)
                        }
                        else {
                            Text(String($0))
                                .font(.system(size: 24))
                        }
                    }
                }
                .padding(.horizontal, store.state.ui.horizontalPadding)
                .padding(.vertical, store.state.ui.verticalPadding)
                .frame(width: geometry.size.width, height: geometry.size.height * store.state.ui.height)
                .clipped()
                .font(.system(size: store.state.ui.secondaryTextSize))
            }
    }

    struct PageControl: View {
        var index: Int
        let maxIndex: Int

        var body: some View {
            HStack(spacing: 8) {
                ForEach(0...maxIndex, id: \.self) { index in
                    Circle()
                        .fill(index == self.index ? Color.white : Color.gray)
                        .frame(width: 8, height: 8)
                }
            }
            .padding(15)
        }
    }

    var body: some View {
        let navbarAction = store.state.activeSubView == "Controller" || store.state.activeSubView == "Metrics"
            ? "Progress"
            : "Controller"

        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in
                VStack() {
                    Spacer(minLength: 4)

                    switch(store.state.activeSubView) {
                        case "Controller", "Metrics":
                            HStack {
                                controllerView(geometry: geometry)
                                metricsView(geometry: geometry)
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
                                                store.state.activeSubView = "Metrics"
                                            default:
                                                return
                                        }
                                    }
                            )

                        case "Progress":
                            progressView(geometry: geometry)

                        case "Rhythm":
                            rhythmView(geometry: geometry)

                        case "Volume":
                            volumeView(geometry: geometry)

                        default:
                            controllerView(geometry: geometry)
                    }
                }
                .font(.system(size: store.state.ui.secondaryTextSize))

                ZStack {
                    HStack {
                        PageControl(index: dragIndex, maxIndex: 1)
                    }
                    .frame(height: geometry.size.height + 40, alignment: .bottom)
                }
                .frame(width: geometry.size.width, alignment: .center)
            }
        }.toolbar(content: {
            ToolbarItem(placement: .cancellationAction) {
                Button(
                    action: { store.state.activeSubView = navbarAction },
                    label: { Text("← " + store.state.activeSubView).font(.system(size: 14)) }
                )
            }
        })
    }
}
