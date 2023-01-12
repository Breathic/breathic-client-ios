import SwiftUI

func discardSessionConfirmationView(geometry: GeometryProxy, store: Store, player: Player) -> some View {
    VStack {
        Text("Really, really discard?")
            .font(.system(size: 12))
            .frame(alignment: .center)
        
        HStack {

            Button(action: {
                player.pause()
                store.state.session.stop()
                store.state.activeSubView = store.state.menuViews[store.state.page]![0]
            }) {
                Text("Discard")
            }
            .font(.system(size: 12))
            .fontWeight(.bold)
            .buttonStyle(.bordered)
            .tint(colorize("red"))

            Button(action: {
                store.state.activeSubView = "Controller"
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
