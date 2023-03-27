import SwiftUI

func toolbarView(
    store: Store
) -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(
                action: {
                    store.state.activeSubView = store.state.activeSubView != "Menu"
                        ? "Menu"
                        : MENU_VIEWS[DEFAULT_PAGE]![0]
                    store.state.activeSubView = isOverviewSelected(store: store)
                        ? "Log"
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
