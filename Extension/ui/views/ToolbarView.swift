import SwiftUI

func toolbarView(
    store: Store
) -> some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(
                action: {
                    store.state.activeSubView = store.state.activeSubView != "Menu"
                    ? "Menu"
                    : MAIN_MENU_VIEWS[0]
                    store.state.activeSubView = isOverviewSelected(store: store)
                    ? "Log"
                    : store.state.activeSubView
                },
                label: {
                    Text(
                        "☰ " + store.state.activeSubView
                            .components(separatedBy: " (")[0] // Remove duration as well as count when overview.
                            .components(separatedBy: " -")[0]
                    )
                    .font(.system(size: 12))
                }
            )
        }
}

