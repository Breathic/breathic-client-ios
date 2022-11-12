import SwiftUI

func dragView(
    geometry: GeometryProxy,
    store: Store,
    player: Player,
    volume: Binding<Float>
) -> some View {
    HStack {
        controllerView(geometry: geometry, store: store, player: player, volume: volume)
        statusView(geometry: geometry, store: store)
    }
    .offset(x: Double(store.state.dragXOffset.width))
    .highPriorityGesture(
        DragGesture()
            .onChanged { gesture in
                store.state.wasDragged = false

                let width = gesture.translation.width + (CGFloat(-store.state.dragIndex) * geometry.size.width)

                if width > 0 { return }  // Stop drag from the left.
                else if width < -geometry.size.width { return } // Stop drag from the right.

                store.state.dragXOffset = CGSize(
                    width: width,
                    height: 0
                )
                store.state.wasDragged = true
            }
            .onEnded { _ in
                if !store.state.wasDragged { return }

                let width = CGFloat(store.state.dragIndex) * geometry.size.width

                if store.state.dragXOffset.width < -width {
                    store.state.dragIndex = 1
                    store.state.activeSubView = "Status"
                }
                else if store.state.dragXOffset.width > -width {
                    store.state.dragIndex = 0
                    store.state.activeSubView = MAIN_MENU_VIEWS[0]
                }
                else {
                    store.state.dragXOffset = CGSize(
                        width: width,
                        height: 0
                    )
                }

                slide(geometry: geometry, store: store)
            }
        )
}
