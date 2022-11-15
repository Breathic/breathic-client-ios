import Foundation
import SwiftUI
import Charts

func primaryButton(
    geometry: GeometryProxy,
    label: String = "",
    value: String = "",
    unit: String = "",
    index: Int = -1,
    maxIndex: Int = -1,
    valueColor: Color = Color.white,
    isWide: Bool = false,
    isShort: Bool = false,
    isTall: Bool = true,
    isActive: Bool = false,
    isEnabled: Bool = true,
    opacity: Double = 1,
    minimumScaleFactor: CGFloat = 1,
    action: @escaping () -> Void = {}
) -> some View {
    Button(action: action) {
        VStack {
            HStack {
                VStack {
                    if label.count > 0 {
                        HStack {
                            Text(label)
                                .lineLimit(1)
                                .minimumScaleFactor(0.5)
                                .font(.system(size: 10))
                        }
                        .frame(
                            maxWidth: .infinity,
                            alignment: .topLeading
                        )
                    }

                    if value.count > 0 {
                        if isWide {
                            Spacer(minLength: 4)
                        }
                        else if !isTall {
                            Spacer(minLength: 8)
                        }

                        Text(value)
                            .lineLimit(1)
                            .minimumScaleFactor(minimumScaleFactor)
                            .font(.system(size: isTall ? 32 : isShort ? 12 : 14))
                            .fontWeight(.bold)
                            .foregroundColor(valueColor)
                            .underline(isActive)
                    }

                    if unit.count > 0 {
                        Text(unit)
                            .frame(maxWidth: .infinity, alignment: Alignment.center)
                            .font(.system(size: 8))
                    }
                }

                if maxIndex > 0 {
                    DottedIndicator(index: index, maxIndex: maxIndex, direction: "vertical")
                }
            }
            .frame(alignment: .center)

            Spacer(minLength: 4)
        }
    }
    .frame(width: geometry.size.width / (isWide ? 1 : 2) - 4)
    .frame(height: geometry.size.height / (isWide ? 4 : 2) - 4)
    .foregroundColor(.white)
    .tint(.black)
    .overlay(
        RoundedRectangle(cornerRadius: 10)
            .stroke(colorize("gray"), lineWidth: isEnabled ? 1 : 0)
    )
    .opacity(opacity)
    .disabled(!isEnabled)
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
                ForEach(0...maxIndex, id: \.self) { index in
                    Circle()
                    .fill(index <= self.index ? Color.white : Color.gray)
                    .frame(width: 2, height: 2)
                }
            }
            .rotationEffect(.degrees(-180))
        }
    }
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

func chart(
    geometry: GeometryProxy,
    seriesData: [SeriesData],
    chartDomain: ChartDomain
) -> some View {
    Group {
        if chartDomain.xMin >= chartDomain.xMax && chartDomain.yMin >= chartDomain.yMax {
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
                    .frame(minWidth: geometry.size.width)
                    .frame(minHeight: geometry.size.height)

                    Spacer(minLength: 16)
                }
            }
        }
    }
}
