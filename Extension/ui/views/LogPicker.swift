import SwiftUI

func logPickerView(
    geometry: GeometryProxy,
    store: Store,
    selectedSessionId: Binding<String>
) -> some View {
    VStack {
        if getSessionIds(sessions: store.state.sessions).count == 0 {
            Text("Your saved sessions will be soon appearing here, hopefully!")
                .foregroundColor(Color.white)
                .font(.system(size: 12))
                .frame(minWidth: geometry.size.width, minHeight: geometry.size.height)
                .background(colorize("black"))
        }

        Picker("", selection: selectedSessionId) {
            ForEach(getSessionIds(sessions: store.state.sessions).reversed(), id: \.self) {
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
                secondaryButton(text: "Select", color: "green", action: { onLogSelect(store: store)
                })
            }
        }
    }
}
