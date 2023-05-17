import SwiftUI

func menuView(
    geometry: GeometryProxy,
    store: Store,
    tempActiveSubView: Binding<String>
) -> some View {
    VStack {
        Picker("", selection: tempActiveSubView) {
            ForEach(MENU_VIEWS, id: \.self) {
                if $0 == store.state.tempActiveSubView {
                    Text($0)
                        .font(.system(size: 18))
                        .fontWeight(.bold)
                }
                else {
                    Text($0)
                        .font(.system(size: 14))
                }
            }
        }
        .padding(.horizontal, store.state.ui.horizontalPadding)
        .padding(.vertical, store.state.ui.verticalPadding)
        .frame(width: geometry.size.width, height: geometry.size.height * store.state.ui.height)
        .clipped()
        .onAppear() {
            store.state.tempActiveSubView = MENU_VIEWS[0]
        }
        .onTapGesture { selectMainMenu(geometry: geometry, store: store) }

        secondaryButton(text: "Select", color: "green", action: { selectMainMenu(geometry: geometry, store: store) })
    }
}
