import Foundation
import SwiftUI

class Coordinator {
    private var session: WKExtendedRuntimeSession?

    func start() {
        if nil == session || session?.state == .invalid {
            session = WKExtendedRuntimeSession()
        }

        session?.start()
    }

    func stop() {
        session?.invalidate()
    }
}
