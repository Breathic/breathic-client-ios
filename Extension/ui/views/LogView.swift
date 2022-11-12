import SwiftUI

func logView(
    geometry: GeometryProxy,
    store: Store,
    selectedSessionId: Binding<String>
) -> some View {
    VStack {
        Picker("", selection: selectedSessionId) {
            ForEach(store.state.sessionLogIds.reversed(), id: \.self) {
                if $0 == store.state.selectedSessionId {
                    Text($0)
                        .font(.system(size: 14))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
                else {
                    Text($0)
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, alignment: .topLeading)
                }
            }
        }
        .padding(.horizontal, store.state.ui.horizontalPadding)
        .padding(.vertical, store.state.ui.verticalPadding)
        .frame(width: geometry.size.width, height: geometry.size.height * store.state.ui.height)
        .clipped()
        .onAppear() { highlightFirstLogItem(store: store) }
        .onTapGesture { onLogSelect(store: store) }

        if hasSessionLogs(store: store) {
            HStack {
                secondaryButton(text: "Delete", color: "red", action: { store.state.activeSubView = "Delete" })
                secondaryButton(text: "Select", color: "green", action: { onLogSelect(store: store) })
            }
        }
    }
}
