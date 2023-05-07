import SwiftUI

func activityPickerView(
    geometry: GeometryProxy,
    store: Store,
    player: Player,
    selectedActivityId: Binding<String>
) -> some View {
    func _getActivityIds() -> [String] {
        ACTIVITIES.map { $0.key }
    }

    func _select() {
        let index = _getActivityIds()
            .firstIndex(where: { $0 == store.state.selectedActivityId }) ?? -1

        store.state.activeSession.activityIndex = index
        store.state.activeSession.activityKey = ACTIVITIES[index].key
        player.create()
        player.start()
        store.state.activeSubView = SubView.Controller.rawValue
    }

    return VStack {
        Picker("", selection: selectedActivityId) {
            ForEach(_getActivityIds(), id: \.self) {
                if $0 == store.state.selectedActivityId {
                    Text($0.capitalized)
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                }
                else {
                    Text($0.capitalized)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, store.state.ui.horizontalPadding)
        .padding(.vertical, store.state.ui.verticalPadding)
        .frame(width: geometry.size.width, height: geometry.size.height * store.state.ui.height)
        .clipped()
        .onTapGesture { _select() }

        HStack {
            secondaryButton(text: "Select", color: "green", action: { _select() })
        }
    }
}
