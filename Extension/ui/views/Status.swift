import SwiftUI

func statusView(geometry: GeometryProxy, store: Store) -> some View {
    let columns = Array(DEFAULT_DISPLAY_METRICS[0...3]).chunks(2)
    
    func _capText(text: String, maxLength: Int) -> String {
        var capped = String(text.prefix(maxLength))
        
        if capped.hasSuffix(".") {
            capped.removeLast()
        }
        
        return capped
    }

    return VStack {
        Spacer(minLength: 8)
        
        ForEach(columns, id: \.self) { column in
            HStack {
                ForEach(column, id: \.self) { metric in
                    primaryButton(
                        geometry: geometry,
                        label: getMetric(metric).label + " (" + getMetric(metric).unit + ")",
                        value: _capText(
                            text: String(format: getMetric(metric).format, store.state.getMetricValue(metric)),
                            maxLength: 4
                        ),
                        valueColor: getMetric(metric).color,
                        valueTextSize: 32,
                        borderWidth: 0,
                        isShort: false,
                        isTall: false,
                        isEnabled: false
                    )
                }
            }

            Spacer(minLength: 8)
        }
        
        HStack {
            primaryButton(
                geometry: geometry,
                label: "Distance (k" + getMetric("distance").unit + ")",
                value: String(format: getMetric("distance").format, store.state.getMetricValue("distance") / 1000),
                valueColor: getMetric("distance").color,
                valueTextSize: 32,
                borderWidth: 0,
                isTall: false,
                isEnabled: false,
                minimumScaleFactor: 0.6
            )

            Spacer(minLength: 8)
            
            primaryButton(
                geometry: geometry,
                label: "Duration",
                value: getElapsedTime(store.state.activeSession.elapsedSeconds),
                valueColor: colorize("white"),
                valueTextSize: 32,
                borderWidth: 0,
                isTall: false,
                isEnabled: false,
                minimumScaleFactor: 0.45
            )
        }
    }
}
