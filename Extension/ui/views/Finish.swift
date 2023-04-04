import SwiftUI

func finishView(
    geometry: GeometryProxy,
    store: Store,
    player: Player
) -> some View {
    VStack {
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
                store.state.activeSubView = SubView.Save.rawValue

                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { (timer: Timer) in
                    player.stop()
                    let sessionIds: [String] = getSessionIds(sessions: store.state.sessions)
                    store.state.selectedSessionId = sessionIds[sessionIds.count - 1]
                    onLogSelect(store: store)
                }
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
                store.state.activeSubView = DEFAULT_ACTIVE_SUB_VIEW
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
