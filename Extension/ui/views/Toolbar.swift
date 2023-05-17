import SwiftUI

func toolbarView(
    store: Store
) -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(
                action: {
                    store.state.activeSubView = store.state.activeSubView != SubView.Menu.rawValue
                        ? SubView.Menu.rawValue
                        : MENU_VIEWS[0]
                    store.state.activeSubView = isOverviewSelected(store: store)
                        ? SubView.Log.rawValue
                        : store.state.activeSubView
                },
                label: {
                    Text(
                        "☰ " + store.state.activeSubView
                            .components(separatedBy: " (")[0] // Remove duration as well as count when overview.
                    )
                    .font(.system(size: 12))
                }
            )
        }
}

