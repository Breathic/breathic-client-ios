import SwiftUI

func chartSettingsView(
    geometry: GeometryProxy,
    store: Store
) -> some View {
    let columns = METRIC_ORDER
        .filter { store.state.chartedMetrics[$0] != nil }
        .filter { store.state.chartedMetrics[$0] ?? 0 > 0 }
        .chunks(2)

    return HStack {
        Spacer(minLength: 8)

        ScrollView(showsIndicators: false) {
            ForEach(columns, id: \.self) { column in
                HStack {
                    ForEach(column, id: \.self) { metric in
                        primaryButton(
                            geometry: geometry,
                            label: getMetric(metric).label,
                            value: String(format: getMetric(metric).format, store.state.chartedMetrics[metric]!),
                            unit: getMetric(metric).unit,
                            valueColor: getMetric(metric).color,
                            isShort: false,
                            isTall: true,
                            minimumScaleFactor: 0.5,
                            action: { }
                        )

                        Spacer(minLength: 8)
                    }
                }

                Spacer(minLength: 8)
            }
        }
        .frame(width: geometry.size.width - 16)
    }
}
