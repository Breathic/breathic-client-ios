import SwiftUI

func rhythmView(
    geometry: GeometryProxy,
    store: Store,
    inRhythm: Binding<Int>,
    outRhythm: Binding<Int>
) -> some View {
    VStack {
        HStack {
            Picker("", selection: inRhythm) {
                ForEach(Array(RHYTHM_RANGE[0]...RHYTHM_RANGE[1]), id: \.self) {
                    if $0 == store.state.session.inRhythm {
                        Text(String(format: "%.1f", Double($0) / 10))
                            .font(.system(size: 32))
                            .fontWeight(.bold)
                    }
                    else {
                        Text(String(format: "%.1f", Double($0) / 10))
                            .font(.system(size: 24))
                    }
                }
            }
            .padding(.horizontal, store.state.ui.horizontalPadding)
            .padding(.vertical, store.state.ui.verticalPadding)
            .frame(width: geometry.size.width * store.state.ui.width, height: geometry.size.height * store.state.ui.height)
            .clipped()
            .onChange(of: store.state.session.inRhythm) { value in
                store.state.session.inRhythm = value
                store.state.session.outRhythm = value
            }

            Picker("", selection: outRhythm) {
                ForEach(Array(RHYTHM_RANGE[0]...RHYTHM_RANGE[1]), id: \.self) {
                    if $0 == store.state.session.outRhythm {
                        Text(String(format: "%.1f", Double($0) / 10))
                            .font(.system(size: 32))
                            .fontWeight(.bold)
                    }
                    else {
                        Text(String(format: "%.1f", Double($0) / 10))
                            .font(.system(size: 24))
                    }
                }
            }
            .padding(.horizontal, store.state.ui.horizontalPadding)
            .padding(.vertical, store.state.ui.verticalPadding)
            .frame(width: geometry.size.width * store.state.ui.width, height: geometry.size.height * store.state.ui.height)
            .clipped()
            .onChange(of: store.state.session.outRhythm) { value in
                store.state.session.outRhythm = value
            }
        }
        .font(.system(size: store.state.ui.secondaryTextSize))

        secondaryButton(text: "Set", color: "green", action: { store.state.activeSubView = MAIN_MENU_VIEWS[0] })
    }
}
