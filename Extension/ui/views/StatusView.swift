import SwiftUI

func statusView(geometry: GeometryProxy, store: Store) -> some View {
    VStack {
        HStack {
            primaryButton(
                geometry: geometry,
                label: "Heartbeats",
                value: String(format: "%.0f", store.state.getMetricValue("heart")),
                unit: "per minute",
                valueColor: METRIC_COLORS["heart"]!,
                isActive: store.state.metricType.metric == "heart",
                isEnabled: false,
                opacity: isSessionActive(store: store) ? 1 : 0.33
            )

            Spacer(minLength: 8)

            primaryButton(
                geometry: geometry,
                label: "Breaths",
                value: String(format: "%.0f", store.state.getMetricValue("breath")),
                unit: "per minute",
                valueColor: METRIC_COLORS["breath"]!,
                isEnabled: false,
                opacity: isSessionActive(store: store) ? 1 : 0.33
            )
        }

        Spacer(minLength: 8)

        HStack {
            primaryButton(
                geometry: geometry,
                label: "Steps",
                value: String(format: "%.0f", store.state.getMetricValue("step")),
                unit: "per minute",
                valueColor: METRIC_COLORS["step"]!,
                isActive: store.state.metricType.metric == "step",
                isEnabled: false,
                opacity: isSessionActive(store: store) ? 1 : 0.33
            )

            Spacer(minLength: 8)

            primaryButton(
                geometry: geometry,
                label: "Speed",
                value: String(format: "%.0f", store.state.getMetricValue("speed")),
                unit: "km / h",
                valueColor: METRIC_COLORS["speed"]!,
                isActive: store.state.metricType.metric == "speed",
                isEnabled: false,
                opacity: isSessionActive(store: store) ? 1 : 0.33
            )
        }
    }
}
