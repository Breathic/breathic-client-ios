import SwiftUI

func finishView(
    geometry: GeometryProxy,
    store: Store,
    player: Player
) -> AnyView {
    if !store.state.isCurrentlySaving {
        return AnyView(
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
                        store.state.isCurrentlySaving = true

                        Timer.scheduledTimer(withTimeInterval: 0, repeats: false) { (timer: Timer) in
                            player.stop()
                            let sessionIds: [String] = getSessionIds(sessions: store.state.sessions)
                            store.state.selectedSessionId = sessionIds[sessionIds.count - 1]
                            onLogSelect(store: store)
                            store.state.isCurrentlySaving = false
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
        )
    }
    else {
        return AnyView(
            Text("Saving...")
                .frame(width: geometry.size.width, height: geometry.size.height)
        )
    }
}
