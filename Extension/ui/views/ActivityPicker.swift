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
        store.state.activeSubView = SubView.Duration.rawValue
    }

    return VStack {
        Picker("", selection: selectedActivityId) {
            ForEach(_getActivityIds(), id: \.self) {
                if $0 == store.state.selectedActivityId {
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
                store.state.activeSubView = DEFAULT_ACTIVE_SUB_VIEW
            })
            secondaryButton(text: "Select", color: "green", action: { _select() })
        }
    }
}
