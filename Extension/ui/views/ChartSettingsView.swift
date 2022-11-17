import SwiftUI

func chartSettingsView(
    geometry: GeometryProxy,
    store: Store
) -> some View {
    let columns = METRIC_ORDER
        .filter { store.state.chartedMetrics[$0] != nil }
        .chunks(2)

    return HStack {
        Spacer(minLength: 8)

        ScrollView(showsIndicators: false) {
            Text("Duration")
                .foregroundColor(Color.white)
                .font(.system(size: 10))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(getElapsedTime(from: store.state.selectedSession.startTime, to: store.state.selectedSession.endTime))
                .foregroundColor(Color.white)
                .font(.system(size: 24))
                .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 8)

            Text("Legend")
                .font(.system(size: 10))
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(columns, id: \.self) { column in
                HStack {
                    ForEach(column, id: \.self) { metric in
                        primaryButton(
                            geometry: geometry,
                            label: getMetric(metric).label,
                            value: String(format: getMetric(metric).format, store.state.chartedMetrics[metric]!),
                            unit: getMetric(metric).unit,
                            valueColor: store.state.chartedMetricsVisivbility[metric]!
                                ? getMetric(metric).color
                                : colorize("gray"),
                            isShort: false,
                            isTall: true,
                            minimumScaleFactor: 0.5,
                            action: {
                                store.state.chartedMetricsVisivbility[metric]! = !store.state.chartedMetricsVisivbility[metric]!
                                onLogSelect(store: store)
                            }
                        )

                        Spacer(minLength: 8)
                    }
                }

                Spacer(minLength: 8)
            }
        }
        .frame(width: geometry.size.width - 8)
    }
}
