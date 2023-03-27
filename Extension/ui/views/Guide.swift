import SwiftUI

struct GuideView: View {
    var geometry: GeometryProxy
    var store: Store

    init(geometry: GeometryProxy, store: Store) {
        self.geometry = geometry
        self.store = store
    }

    var body: some View {
        ScrollView() {
            Spacer(minLength: 24)

            Text("To get acquainted with Breathic, read its guide from your phone:")
                .font(.system(size: 10))
                .frame(maxWidth: .infinity, alignment: .leading)

            qrCode(geometry: geometry, url: GUIDE_URL)

            if store.state.isGuideSeen == nil {
                Spacer(minLength: 24)

                HStack {
                    Button(action: {
                        saveBoolean(name: GUIDE_SEEN_NAME, bool: true)
                        store.state.isGuideSeen = true
                        store.state.activeSubView = DEFAULT_ACTIVE_SUB_VIEW
                    }) {
                        Text("Continue")
                    }
                    .font(.system(size: 12))
                    .fontWeight(.bold)
                    .buttonStyle(.bordered)
                    .tint(colorize("blue"))
                }
                .padding(.trailing, 16)
            }
        }
    }
}
