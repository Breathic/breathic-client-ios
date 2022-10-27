import Foundation
import SwiftUI

extension DispatchTimeInterval {
    func toDouble() -> Double {
        var result: Double = 0

        switch self {
            case .seconds(let value):
                result = Double(value)
            case .milliseconds(let value):
                result = Double(value) * 0.001
            case .microseconds(let value):
                result = Double(value) * 0.000001
            case .nanoseconds(let value):
                result = Double(value) * 0.000000001
            case .never:
                result = 0
            @unknown default:
                result = 0
        }

        return result
    }
}

struct Platform {
    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
}

public extension View {
    func onScenePhaseChange(phase: ScenePhase, action: @escaping () -> ()) -> some View {
        self.modifier(OnScenePhaseChangeModifier(phase: phase, action: action))
    }
}

public struct OnScenePhaseChangeModifier: ViewModifier {
    @Environment(\.scenePhase) private var scenePhase

    public let phase: ScenePhase
    public let action: () -> ()
    public func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { phase in
                if (self.phase == phase) {
                    action()
                }
            }
    }
}
