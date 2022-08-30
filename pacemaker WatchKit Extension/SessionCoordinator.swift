import Foundation
import SwiftUI

class SessionCoordinator {
    private var session: WKExtendedRuntimeSession?

    func start() {
        guard session?.state != .running else { return }

        // create or recreate session if needed
        if nil == session || session?.state == .invalid {
            session = WKExtendedRuntimeSession()
        }
        session?.start()
    }

    func invalidate() {
        session?.invalidate()
    }
}
