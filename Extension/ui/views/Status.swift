import SwiftUI

func statusView(geometry: GeometryProxy, store: Store) -> some View {
    let columns = Array(METRIC_ORDER[0...3]).chunks(2)

    return VStack {
        HStack {
            primaryButton(
                geometry: geometry,
                label: "Duration",
                value: getElapsedTime(store.state.activeSession.elapsedSeconds),
                unit: " ",
                valueColor: colorize("white"),
                valueTextSize: 32,
                borderWidth: 0,
                isTall: false,
                isEnabled: false,
                minimumScaleFactor: 0.45
            )

            Spacer(minLength: 8)

            primaryButton(
                geometry: geometry,
                label: "Distance (k" + getMetric("distance").unit + ")",
                value: String(format: getMetric("distance").format, store.state.getMetricValue("distance") / 1000),
                valueColor: colorize("blue"),
                valueTextSize: 32,
                borderWidth: 0,
                isTall: false,
                isEnabled: false,
                minimumScaleFactor: 0.7
            )

            Spacer(minLength: 8)
        }
        
        Spacer(minLength: 8)

        ForEach(columns, id: \.self) { column in
            HStack {
                ForEach(column, id: \.self) { metric in
                    primaryButton(
                        geometry: geometry,
                        label: getMetric(metric).label + " (" + getMetric(metric).unit + ")",
                        value: String(format: getMetric(metric).format, store.state.getMetricValue(metric)),
                        valueColor: getMetric(metric).color,
                        valueTextSize: 32,
                        borderWidth: 0,
                        isTall: false,
                        isEnabled: false
                    )

                }
            }

            Spacer(minLength: 12)
        }
    }
}
