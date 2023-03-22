import SwiftUI

func sessionStopConfirmationView(geometry: GeometryProxy, store: Store, player: Player) -> some View {
    VStack {
        HStack {
            Button(action: {
                store.state.activeSubView = "Discard"
            }) {
                Text("Discard")
            }
            .font(.system(size: 12))
            .fontWeight(.bold)
            .buttonStyle(.bordered)
            .tint(colorize("red"))

            Button(action: {
                player.stop()
                let sessionIds: [String] = getSessionIds(sessions: store.state.sessions)
                store.state.selectedSessionId = sessionIds[sessionIds.count - 1]
                onLogSelect(store: store)
            }) {
                Text("Save")
            }
            .font(.system(size: 12))
            .fontWeight(.bold)
            .buttonStyle(.bordered)
            .tint(colorize("green"))
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

            Button(action: {
                player.togglePlay()
                store.state.activeSubView = MENU_VIEWS[store.state.page]![0]
            }) {
                Text(store.state.session.isPlaying ? "Pause" : "Play")
            }
            .font(.system(size: 12))
            .fontWeight(.bold)
            .buttonStyle(.bordered)
            .tint(colorize("yellow"))
        }
        .frame(maxHeight: .infinity, alignment: .bottom)
        .edgesIgnoringSafeArea(.all)
    }
}
