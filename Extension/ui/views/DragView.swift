import SwiftUI

func onDragChanged(
    geometry: GeometryProxy,
    store: Store,
    gesture: DragGesture.Value
) {
    store.state.pageOptions[store.state.page]!.wasDragged = false

    let width = gesture.translation.width + (CGFloat(-store.state.pageOptions[store.state.page]!.dragIndex) * geometry.size.width)

    //if width > 0 { return }  // Stop drag from the left.
    //else if width < -geometry.size.width { return } // Stop drag from the right.

    store.state.pageOptions[store.state.page]!.dragXOffset = CGFloat(width)
    store.state.pageOptions[store.state.page]!.wasDragged = true
}

func onDragEnded(
    geometry: GeometryProxy,
    store: Store
) {
    if !store.state.pageOptions[store.state.page]!.wasDragged { return }

    let width = CGFloat(store.state.pageOptions[store.state.page]!.dragIndex) * geometry.size.width

    if store.state.pageOptions[store.state.page]!.dragXOffset < -width {
        store.state.pageOptions[store.state.page]!.dragIndex = 1
        store.state.activeSubView = store.state.menuViews[store.state.page]![1]
    }
    else if store.state.pageOptions[store.state.page]!.dragXOffset > -width {
        store.state.pageOptions[store.state.page]!.dragIndex = 0
        store.state.activeSubView = store.state.menuViews[store.state.page]![0]
    }
    else {
        store.state.pageOptions[store.state.page]!.dragXOffset = CGFloat(width)
    }

    slide(geometry: geometry, store: store)
}

func dragView(
    children: some View,
    geometry: GeometryProxy,
    store: Store
) -> some View {
    children
        .offset(x: store.state.pageOptions[store.state.page]!.dragXOffset, y: 0)
        .simultaneousGesture(
            DragGesture(minimumDistance: 10.0)
                .onChanged { gesture in
                    onDragChanged(geometry: geometry, store: store, gesture: gesture)
                }
                .onEnded { _ in
                    onDragEnded(geometry: geometry, store: store)
                }
            )
}
