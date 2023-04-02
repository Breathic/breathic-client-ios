import SwiftUI

func statusView(geometry: GeometryProxy, store: Store) -> some View {
    let columns = Array(METRIC_ORDER[0...3]).chunks(2)

    return VStack {
        ForEach(columns, id: \.self) { column in
            HStack {
                ForEach(column, id: \.self) { metric in
                    primaryButton(
                        geometry: geometry,
                        label: getMetric(metric).label,
                        value: String(format: getMetric(metric).format, store.state.getMetricValue(metric)),
                        unit: getMetric(metric).unit,
                        valueColor: getMetric(metric).color,
                        borderWidth: 0,
                        isEnabled: false
                    )

                    Spacer(minLength: 8)
                }
            }

            Spacer(minLength: 8)
        }
    }
}
