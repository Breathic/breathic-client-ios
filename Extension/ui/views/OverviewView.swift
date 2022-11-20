import SwiftUI

func overviewView(geometry: GeometryProxy, store: Store) -> some View {
    HStack {
        Spacer(minLength: 8)

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
    }
    .frame(minWidth: geometry.size.width + 8)
}
