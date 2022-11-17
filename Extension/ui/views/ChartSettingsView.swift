import SwiftUI

func chartSettingsView(
    geometry: GeometryProxy,
    store: Store
) -> some View {
    let columns = METRIC_ORDER
        .filter { store.state.chartableMetrics[$0] != nil }
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

            Spacer(minLength: 16)

            Text("Legend")
                .font(.system(size: 10))
                .frame(maxWidth: .infinity, alignment: .leading)

            ForEach(columns, id: \.self) { column in
                HStack {
                    ForEach(column, id: \.self) { metric in
                        primaryButton(
                            geometry: geometry,
                            label: getMetric(metric).label,
                            value: String(format: getMetric(metric).format, store.state.chartableMetrics[metric]!),
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

            Spacer(minLength: 16)

            Text("Scale")
                .font(.system(size: 10))
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack {
                VStack {
                    ForEach(Array(store.state.chartScales.keys), id: \.self) { scale in
                        secondaryButton(
                            text: scale,
                            color: store.state.chartScales[scale] == true ? "white": "gray",
                            action: {
                                store.state.chartScales.keys.forEach {
                                    store.state.chartScales[$0] = false
                                }

                                store.state.chartScales[scale] = true
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
