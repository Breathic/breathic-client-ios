import SwiftUI

func statusView(geometry: GeometryProxy, store: Store) -> some View {
    VStack {
        HStack {
            primaryButton(
                geometry: geometry,
                label: getMetric("heart").label,
                value: String(format: getMetric("heart").format, store.state.getMetricValue("heart")),
                unit: getMetric("heart").unit,
                valueColor: getMetric("heart").color,
                isActive: store.state.metricType.metric == "heart",
                isEnabled: false,
                opacity: isSessionActive(store: store) ? 1 : 0.33
            )

            Spacer(minLength: 8)

            primaryButton(
                geometry: geometry,
                label: getMetric("breath").label,
                value: String(format: getMetric("breath").format, store.state.getMetricValue("breath")),
                unit: getMetric("breath").unit,
                valueColor: getMetric("breath").color,
                isEnabled: false,
                opacity: isSessionActive(store: store) ? 1 : 0.33
            )
        }

        Spacer(minLength: 8)

        HStack {
            primaryButton(
                geometry: geometry,
                label: getMetric("step").label,
                value: String(format: getMetric("step").format, store.state.getMetricValue("step")),
                unit: getMetric("step").unit,
                valueColor: getMetric("step").color,
                isActive: store.state.metricType.metric == "step",
                isEnabled: false,
                opacity: isSessionActive(store: store) ? 1 : 0.33
            )

            Spacer(minLength: 8)

            primaryButton(
                geometry: geometry,
                label: getMetric("speed").label,
                value: String(format: getMetric("speed").format, store.state.getMetricValue("speed")),
                unit: getMetric("speed").unit,
                valueColor: getMetric("speed").color,
                isActive: store.state.metricType.metric == "speed",
                isEnabled: false,
                opacity: isSessionActive(store: store) ? 1 : 0.33
            )
        }
    }
}
