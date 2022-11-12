import SwiftUI

func overviewView(geometry: GeometryProxy, store: Store) -> some View {
    HStack {
        Spacer(minLength: 8)

        chart(geometry: geometry, seriesData: store.state.seriesData, chartDomain: store.state.chartDomain)
    }
}
