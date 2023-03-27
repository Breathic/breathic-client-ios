import SwiftUI

struct PrivacyPolicyView: View {
    var geometry: GeometryProxy
    var store: Store

    init(geometry: GeometryProxy, store: Store) {
        self.geometry = geometry
        self.store = store
    }

    var body: some View {
        return ScrollView() {
            Spacer(minLength: 24)

            Text("Read Breathic's privacy policy on your phone:")
                .font(.system(size: 10))
                .frame(maxWidth: .infinity, alignment: .leading)

            qrCode(geometry: geometry, url: PRIVACY_POLICY_URL)

            Spacer(minLength: 24)

            if store.state.isPrivacyPolicyApproved == nil {
                Text("I have read Breathic's privacy policy and approve it:")
                    .font(.system(size: 10))
                    .padding(.trailing, 16)

                Button(action: {
                    saveBoolean(name: PRIVACY_POLICY_APPROVAL_NAME, bool: true)
                    store.state.isPrivacyPolicyApproved = true
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
