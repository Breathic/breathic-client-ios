import SwiftUI
import CompactSlider

struct DeleteSessionConfirmationView: View {
    var geometry: GeometryProxy
    var store: Store

    @State var value: Double = CONFIRMATION_DEFAULT_VALUE

    init(geometry: GeometryProxy, store: Store) {
        self.geometry = geometry
        self.store = store
    }

    var body: some View {
        VStack {
            CompactSlider(value: $value, handleVisibility: .hidden) {
                Text("Delete session?")
                    .font(.system(size: 12))
            }
            .onChange(of: value, perform: {_ in
                if value > CONFIRMATION_ENOUGH_VALUE {
                    deleteSession(store: store, sessionId: store.state.selectedSessionId)
                }
            })
            .compactSliderStyle(CustomCompactSliderStyle())
            .edgesIgnoringSafeArea(.all)

            HStack {
                Button(action: {
                    onLogSelect(store: store)
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
