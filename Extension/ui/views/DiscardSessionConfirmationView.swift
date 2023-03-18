import SwiftUI
import CompactSlider

struct DiscardSessionConfirmationView: View {
    var geometry: GeometryProxy
    var store: Store
    var player: Player

    @State var value: Double = CONFIRMATION_DEFAULT_VALUE

    init(geometry: GeometryProxy, store: Store, player: Player) {
        self.geometry = geometry
        self.store = store
        self.player = player
    }

    var body: some View {
        VStack {
            CompactSlider(value: $value, handleVisibility: .hidden) {
                Text("Discard session?")
                    .font(.system(size: 12))
            }
            .onChange(of: value, perform: {_ in
                if value > CONFIRMATION_ENOUGH_VALUE {
                    player.stop()
                    store.state.activeSubView = MENU_VIEWS[store.state.page]![0]
                }
            })
            .compactSliderStyle(CustomCompactSliderStyle())
            .edgesIgnoringSafeArea(.all)

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
}
