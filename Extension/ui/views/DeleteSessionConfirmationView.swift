import SwiftUI

func deleteSessionConfirmationView(geometry: GeometryProxy, store: Store) -> some View {
    VStack {
        Text("Delete session from " + store.state.selectedSessionId + "?")
            .font(.system(size: 12))
            .frame(maxHeight: .infinity, alignment: .center)
        
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
                onLogSelect(store: store)
            }) {
                Text("Cancel")
            }
            .font(.system(size: 12))
            .fontWeight(.bold)
            .buttonStyle(.bordered)
            .tint(colorize("teal"))
        }.frame(alignment: .center)
    }.frame(maxHeight: .infinity)
}
