import SwiftUI
import Sentry

@main
struct pacemakerApp: App {
    init() {
        SentrySDK.start { options in
            options.dsn = SENTRY_DSN
            options.debug = true
            options.tracesSampleRate = 1.0
        }
    }

    var body: some Scene {
        WindowGroup {
            NavigationView {
                ContentView()
            }
        }
    }
}
