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

struct ContentView: View {
    @ObservedObject private var store: AppStore = .shared

    let player = Player()
    let parsedData: ParsedData = ParsedData()
    
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

    func getSeriesData() -> [SeriesData] {
        let breathMetrics = store.state.updates["breath"] ?? []
        let heartRateMetrics = store.state.updates["heartRate"] ?? []
        let stepMetrics = store.state.updates["step"] ?? []
        let speedMetrics = store.state.updates["speed"] ?? []

        let lastBreathMetricValue = String(breathMetrics.count > 0 ? String(format: "%.1f", breathMetrics[breathMetrics.count - 1].value) : "")
        let lastHeartRateMetricValue = String(heartRateMetrics.count > 0 ? String(format: "%.1f", heartRateMetrics[heartRateMetrics.count - 1].value) : "")
        let lastStepMetricValue = String(stepMetrics.count > 0 ? String(format: "%.1f", stepMetrics[stepMetrics.count - 1].value) : "")
        let lastSpeedhMetricValue = String(speedMetrics.count > 0 ? String(format: "%.1f", speedMetrics[speedMetrics.count - 1].value) : "")

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
        isWide: Bool = false,
        isTall: Bool = true,
        isActive: Bool = false,
        isEnabled: Bool = true,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack {
                Spacer(minLength: 4)
                
                if label.count > 0 {
                    Text(label)
                    .frame(maxWidth: .infinity, alignment: Alignment.topLeading)
                    .font(.system(size: store.state.ui.primaryTextSize))
                }

                if value.count > 0 {
                    Spacer(minLength: 8)
                    
                    Text(value)
                    .font(.system(size: 18))
                    .fontWeight(.bold)
                }

                if unit.count > 0 {
                    Spacer(minLength: 0)

                    Text(unit)
                    .frame(maxWidth: .infinity, alignment: Alignment.center)
                    .font(.system(size: store.state.ui.tertiaryTextSize))
                }

                Rectangle()
                .fill(isActive ? .white : .black)
                .frame(width: geometry.size.width / 3 - 4, height: 2)
                
                Spacer(minLength: 4)
            }
        }
        .fixedSize()
        .frame(width: geometry.size.width / (isWide ? 1 : 2) - 4, height: geometry.size.height / (isTall ? 2 : 3) - 4)
        .foregroundColor(.white)
        .tint(.black)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(.gray, lineWidth: store.state.ui.borderLineWidth)
        )
        .opacity(isEnabled ? 1 : 0.33)
        .disabled(!isEnabled)
    }

    func controllerView(geometry: GeometryProxy) -> some View {
        VStack {
            HStack {
                menuButton(
                    geometry: geometry,
                    label: "Pace",
                    value: String(format: "%.2f", store.state.valueByMetric(metric: store.state.metricTypes[store.state.selectedMetricTypeIndex].metric)),
                    unit: store.state.metricTypes[store.state.selectedMetricTypeIndex].unit,
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
                    action: { store.state.activeSubView = "Rhythm" }
                )
            }

            Spacer(minLength: 8)

            HStack {
                menuButton(
                    geometry: geometry,
                    label: "Volume",
                    value: String(store.state.selectedVolume),
                    unit: store.state.selectedVolume == 0 ? "muted" : "",
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
                    action: {
                        player.togglePlay()
                    }
                )
            }
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
                            .font(.system(size: 18))
                            .fontWeight(.bold)
                        }
                        else {
                            Text(String(format: "%.1f", Double($0) / 10))
                            .font(.system(size: 12))
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
                            .font(.system(size: 18))
                            .fontWeight(.bold)
                        }
                        else {
                            Text(String(format: "%.1f", Double($0) / 10))
                            .font(.system(size: 12))
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
                                .font(.system(size: 18))
                                .fontWeight(.bold)
                        }
                        else {
                            Text(String($0))
                                .font(.system(size: 12))
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

    var body: some View {
        let toolbarAction = store.state.activeSubView == "Controller"
            ? "Progress"
            : "Controller"

        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            GeometryReader { geometry in
                VStack() {
                    switch(store.state.activeSubView) {
                        case "Controller":
                            controllerView(geometry: geometry)

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
            }
        }.toolbar(content: {
            ToolbarItem(placement: .cancellationAction) {
                Button(
                    action: { store.state.activeSubView = toolbarAction },
                    label: { Text("← " + store.state.activeSubView).font(.system(size: 14)) }
                )
            }
        })
    }
}
