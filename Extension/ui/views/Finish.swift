import SwiftUI

func finishView(
    geometry: GeometryProxy,
    store: Store,
    player: Player
) -> some View {
    var isAlreadySaving: Bool = false

    return VStack {
        HStack {
            Button(action: {
                store.state.activeSubView = SubView.Discard.rawValue
            }) {
                Text("Discard")
            }
            .font(.system(size: 12))
            .fontWeight(.bold)
            .buttonStyle(.bordered)
            .tint(colorize("red"))

            Button(action: {
                if !isAlreadySaving {
                    isAlreadySaving = true
                    player.stop()
                    let sessionIds: [String] = getSessionIds(sessions: store.state.sessions)
                    store.state.selectedSessionId = sessionIds[sessionIds.count - 1]
                    onLogSelect(store: store)
                }
            }) {
                Text(!isAlreadySaving ? "Save" : "Saving")
            }
            .font(.system(size: 12))
            .fontWeight(.bold)
            .buttonStyle(.bordered)
            .tint(!isAlreadySaving ? colorize("green") : colorize("gray"))
        }

        HStack {
            Button(action: {
                store.state.activeSubView = MENU_VIEWS[store.state.page]![0]
            }) {
                Text("Cancel")
            }
            .font(.system(size: 12))
            .fontWeight(.bold)
            .buttonStyle(.bordered)
            .tint(colorize("teal"))
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .edgesIgnoringSafeArea(.all)
    }
}
