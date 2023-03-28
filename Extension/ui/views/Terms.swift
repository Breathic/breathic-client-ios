import SwiftUI

struct TermsView: View {
    var geometry: GeometryProxy
    var store: Store

    init(geometry: GeometryProxy, store: Store) {
        self.geometry = geometry
        self.store = store
    }

    var body: some View {
        return ScrollView() {
            Spacer(minLength: 24)

            Group {
                Text("Read Breathic's Terms and Conditions on your phone:")
                    .font(.system(size: 10))
                    .frame(maxWidth: .infinity, alignment: .leading)

                qrCode(geometry: geometry, url: TERMS_AND_CONDITIONS_URL)

                Spacer(minLength: 24)
            }

            Group {
                Text("Read Breathic's Privacy Policy on your phone:")
                    .font(.system(size: 10))
                    .frame(maxWidth: .infinity, alignment: .leading)

                qrCode(geometry: geometry, url: PRIVACY_POLICY_URL)

                Spacer(minLength: 24)
            }

            if store.state.isTermsApproved == nil {
                Text("I have read Breathic's Terms and Conditions as well as Privacy Policy and approve to both:")
                    .font(.system(size: 10))
                    .padding(.trailing, 16)

                Button(action: {
                    saveBoolean(name: TERMS_APPROVAL_NAME, bool: true)
                    store.state.isTermsApproved = true
                    store.state.activeSubView = DEFAULT_ACTIVE_SUB_VIEW
                }) {
                    Text("Approve")
                }
                .font(.system(size: 12))
                .fontWeight(.bold)
                .buttonStyle(.bordered)
                .tint(colorize("blue"))
                .padding(.trailing, 16)
            }
        }
    }
}
