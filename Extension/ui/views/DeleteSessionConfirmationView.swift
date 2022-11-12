import SwiftUI

func deleteSessionConfirmationView(geometry: GeometryProxy, store: Store) -> some View {
    VStack {
        HStack {
            Button(action: {
                deleteSession(store: store, sessionId: store.state.selectedSessionId)
            }) {
                Text("Delete")
            }
            .font(.system(size: 12))
            .fontWeight(.bold)
            .buttonStyle(.bordered)
            .tint(colorize("red"))

            Button(action: {
                store.state.activeSubView = "Log"
            }) {
                Text("Cancel")
            }
            .font(.system(size: 12))
            .fontWeight(.bold)
            .buttonStyle(.bordered)
            .tint(colorize("blue"))
        }
        .frame(maxHeight: .infinity, alignment: .topLeading)

        Text("Delete session from " + store.state.selectedSessionId + "?")
        .font(.system(size: 12))
        .frame(maxHeight: .infinity, alignment: .bottom)
    }
}
