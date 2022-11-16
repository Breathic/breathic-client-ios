import SwiftUI

func sessionStopConfirmationView(geometry: GeometryProxy, store: Store, player: Player) -> some View {
    VStack {
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
                player.stop()
                store.state.activeSubView = store.state.menuViews[store.state.page]![0]
            }) {
                Text("Save")
            }
            .font(.system(size: 12))
            .fontWeight(.bold)
            .buttonStyle(.bordered)
            .tint(colorize("green"))
        }

        Text("Finish session?")
            .font(.system(size: 12))
            .frame(maxHeight: .infinity, alignment: .center)

        HStack {
            Button(action: {
                store.state.activeSubView = store.state.menuViews[store.state.page]![0]
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
