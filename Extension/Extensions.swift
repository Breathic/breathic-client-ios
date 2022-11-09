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

extension Date {
    func adding(minutes: Int) -> Date {
        return Calendar.current.date(byAdding: .minute, value: minutes, to: self)!
    }
}

extension Dictionary where Value: RangeReplaceableCollection {
    public mutating func append(element: Value.Iterator.Element, toValueOfKey key: Key) {
        var value: Value = self[key] ?? Value()
        value.append(element)
        self[key] = value
    }
}
