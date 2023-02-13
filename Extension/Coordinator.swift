import Foundation
import SwiftUI

class Coordinator {
    private var session: WKExtendedRuntimeSession?

    func start() {
        if session?.state == .running {
            session?.invalidate()
        }
        else {
            session = WKExtendedRuntimeSession()
        }

        session?.start()
    }
}

/*
import Foundation
import SwiftUI

class Coordinator {
    private var session: WKExtendedRuntimeSession?

    func start() {
        guard session?.state != .running else { return }

        if nil == session || session?.state == .invalid {
            session = WKExtendedRuntimeSession()
        }
        session?.start()
    }

    func stop() {
        session?.invalidate()
    }
}
*/
