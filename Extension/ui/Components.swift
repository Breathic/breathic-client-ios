import Foundation
import SwiftUI
import Charts

func primaryButton(
    geometry: GeometryProxy,
    label: String = "",
    value: String = "",
    unit: String = "",
    hasIndicator: Bool = false,
    index: Int = -1,
    maxIndex: Int = -1,
    valueColor: Color = Color.white,
    valueTextSize: CGFloat = 14,
    borderWidth: Double = 1,
    isWide: Bool = false,
    isShort: Bool = false,
    isTall: Bool = false,
    isActive: Bool = false,
    isEnabled: Bool = true,
    isBlurred: Bool = false,
    minimumScaleFactor: CGFloat = 1,
    action: @escaping () -> Void = {},
    longAction: @escaping () -> Void = {}
) -> some View {
    @GestureState var pressState: Bool = true

    let blur: Double = 3
    let blurredOpacity: Double = 0.5
    
    func _parseValue(_ value: String) -> String {
        value.count > 0 && Float(value) != nil && Float(value)! == 0
            ? "0"
            : value
    }

    return Button(action: {}) {
        VStack {
            HStack {
                VStack {
                    if label.count > 0 {
                        HStack {
                            Text(label)
                                .lineLimit(1)
                                .minimumScaleFactor(0.7)
                                .font(.system(size: 10))
                        }
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                    }

                    if value.count > 0 {
                        Spacer(minLength: isTall ? 8 : 2)

                        Text(_parseValue(value))
                            .lineLimit(1)
                            .minimumScaleFactor(minimumScaleFactor)
                            .font(.system(size: isShort ? 12 : valueTextSize))
                            .fontWeight(.bold)
                            .foregroundColor(valueColor)
                            .underline(isActive)
                    }

                    if unit.count > 0 {
                        Text(unit)
                            .lineLimit(1)
                            .minimumScaleFactor(minimumScaleFactor)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .font(.system(size: 8))
                    }
                }

                if hasIndicator {
                    DottedIndicator(index: index, maxIndex: maxIndex, direction: "vertical")
                }
            }
            .frame(alignment: .center)

            Spacer(minLength: 4)
        }
    }
    .frame(width: geometry.size.width / (isWide ? 1 : 2) - 4)
    .frame(height: geometry.size.height / (isTall ? 2 : 3) - (isTall ? 4 : 8))
    .foregroundColor(.white)
    .tint(.black)
    .overlay(
        RoundedRectangle(cornerRadius: 10)
            .stroke(colorize("gray"), lineWidth: borderWidth)
    )
    .opacity(isBlurred ? blurredOpacity : 1)
    .blur(radius: isBlurred ? blur : 0)
    .disabled(!isEnabled)
    .simultaneousGesture(
        LongPressGesture(minimumDuration: 0.1, maximumDistance: 10.0)
            .sequenced(before: LongPressGesture(minimumDuration: .infinity, maximumDistance: 10.0))
            .updating($pressState) { value, state, transaction in
                if value == .second(true, nil) {
                    longAction()
                }
            }
    )
    .highPriorityGesture(
        TapGesture()
            .onEnded { _ in
                action()
            }
    )
}

func secondaryButton(
    text: String,
    color: String,
    action: @escaping () -> Void = {}
) -> some View {
    Button(action: action) {
        Text(text)
    }
    .font(.system(size: 12))
    .fontWeight(.bold)
    .buttonStyle(.bordered)
    .tint(colorize(color))
}

struct DottedIndicator: View {
    var index: Int
    let maxIndex: Int
    let direction: String

    var body: some View {
        if direction == "horizontal" {
            HStack(spacing: 4) {
                ForEach(0...maxIndex, id: \.self) { index in
                    Circle()
                        .fill(index == self.index ? Color.white : Color.gray)
                        .frame(width: 8, height: 8)
                }
            }
        }
        else if direction == "vertical" {
            VStack(spacing: 1) {
                if maxIndex > 0 {
                    ForEach(0...maxIndex, id: \.self) { index in
                        Circle()
                            .fill(index <= self.index ? Color.white : Color.gray)
                            .frame(width: 2, height: 2)
                    }
                }
                else {
                    Circle()
                        .fill(Color.black)
                        .frame(width: 2, height: 2)
                }
            }
            .rotationEffect(.degrees(-180))
        }
    }
}

func chart(
    geometry: GeometryProxy,
    seriesData: [SeriesData],
    chartDomain: ChartDomain,
    action: @escaping () -> Void = {}
) -> some View {
    Group {
        if seriesData.count == 0 {
            Text("No usable data found.")
                .font(.system(size: 12))
                .frame(maxWidth: .infinity, alignment: .center)
                .frame(maxHeight: .infinity, alignment: .center)
        }
        else {
            VStack {
                HStack {
                    Chart(seriesData) { series in
                        ForEach(series.data) { element in
                            LineMark(
                                x: .value("Time", element.timestamp),
                                y: .value("Value", element.value)
                            )
                            .foregroundStyle(by: .value("Metric", series.metric))
                        }
                    }
                    .chartForegroundStyleScale(range: graphColors(for: seriesData))
                    .chartXScale(domain: floor(chartDomain.xMin)...ceil(chartDomain.xMax))
                    .chartYScale(domain: floor(chartDomain.yMin)...ceil(chartDomain.yMax))
                    .chartLegend(.hidden)
                    .frame(width: geometry.size.width)
                    .frame(height: geometry.size.height - 24)

                    Spacer(minLength: 16)
                }
                .onTapGesture { action() }
            }
        }
    }
}

func qrCode(
    geometry: GeometryProxy,
    url: String
) -> some View {
    generateQRCode(url)
        .resizable()
        .scaledToFit()
        .frame(width: geometry.size.width - 16, height: geometry.size.height - 16)
        .padding(.trailing, 16)
}
