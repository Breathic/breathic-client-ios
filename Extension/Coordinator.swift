import Foundation
import SwiftUI

class Coordinator {
    private var session: WKExtendedRuntimeSession?

    func create() {
        if nil == session || session?.state == .invalid {
            session = WKExtendedRuntimeSession()
        }

        start()
    }

    func start() {
        session?.start()
    }

    func stop() {
        session?.invalidate()
    }
}
