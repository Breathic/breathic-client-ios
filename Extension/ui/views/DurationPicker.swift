import SwiftUI

func durationPickerView(
    geometry: GeometryProxy,
    store: Store,
    player: Player,
    selectedDurationId: Binding<String>
) -> some View {
    let durationOptions = ACTIVITIES[store.state.activeSession.activityIndex].durationOptions

    func _select() {
        let index = durationOptions.firstIndex(where: { $0 == store.state.selectedDurationId }) ?? 0
        store.state.activeSession.durationIndex = index
        player.create()
        player.start()
        store.state.activeSubView = SubView.Session.rawValue
    }
    
    return VStack {
        Picker("", selection: selectedDurationId) {
            ForEach(durationOptions, id: \.self) {
                if $0 == store.state.selectedDurationId {
                    Text($0)
                        .font(.system(size: 16))
                        .fontWeight(.bold)
                }
                else {
                    Text($0)
                        .font(.system(size: 12))
                }
            }
        }
        .padding(.horizontal, store.state.ui.horizontalPadding)
        .padding(.vertical, store.state.ui.verticalPadding)
        .frame(width: geometry.size.width, height: geometry.size.height * store.state.ui.height)
        .clipped()
        .onTapGesture { _select() }
        
        HStack {
            secondaryButton(text: "Cancel", color: "blue", action: {
                store.state.activeSubView = SubView.Activity.rawValue
            })
            secondaryButton(text: "Select", color: "green", action: { _select() })
        }
    }
}
