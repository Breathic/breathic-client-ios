import SwiftUI

func chartSettingsView(
    geometry: GeometryProxy,
    store: Store
) -> some View {
    let columns = METRIC_ORDER
        .filter { store.state.chartableMetrics[$0] != nil }
        .chunks(2)

    return ScrollView(showsIndicators: false) {
        Text("Duration")
            .foregroundColor(Color.white)
            .font(.system(size: 10))
            .frame(maxWidth: .infinity, alignment: .leading)

        Text(getElapsedTime(from: store.state.selectedSession.startTime, to: store.state.selectedSession.endTime))
            .foregroundColor(Color.white)
            .font(.system(size: 24))
            .frame(maxWidth: .infinity, alignment: .leading)

        Spacer(minLength: 24)
        
        Text("Progress")
            .font(.system(size: 10))
            .frame(maxWidth: .infinity, alignment: .leading)
        
        chart(
            geometry: geometry,
            seriesData: store.state.seriesData,
            chartDomain: store.state.chartDomain,
            action: {
                store.state.chartScales.keys.forEach {
                    store.state.chartScales[$0] = !store.state.chartScales[$0]!
                }
                
                onLogSelect(store: store)
            }
        )
        
        Spacer(minLength: 24)

        Text("Legend")
            .font(.system(size: 10))
            .frame(maxWidth: .infinity, alignment: .leading)
        
        VStack {
            ForEach(columns, id: \.self) { column in
                HStack {
                    ForEach(column, id: \.self) { metric in
                        primaryButton(
                            geometry: geometry,
                            label: getMetric(metric).label,
                            value: String(format: getMetric(metric).format, store.state.chartableMetrics[metric]!),
                            unit: getMetric(metric).unit,
                            valueColor: store.state.chartedMetricsVisibility[metric]!
                                ? getMetric(metric).color
                                : colorize("gray"),
                            isShort: false,
                            isTall: true,
                            minimumScaleFactor: 0.5,
                            action: {
                                store.state.chartedMetricsVisibility[metric]! = !store.state.chartedMetricsVisibility[metric]!
                                onLogSelect(store: store)
                            }
                        )
                        
                        Spacer(minLength: 8)
                    }
                }.frame(width: geometry.size.width + 8)
                
                Spacer(minLength: 8)
            }
        }.frame(maxWidth: .infinity, alignment: .leading)

        Spacer(minLength: 24)

        secondaryButton(text: "Delete", color: "red", action: { store.state.activeSubView = "Delete" })
            .frame(maxHeight: .infinity, alignment: .bottom)
            .padding(.trailing, 16)
    }
    .edgesIgnoringSafeArea(.all)
}
