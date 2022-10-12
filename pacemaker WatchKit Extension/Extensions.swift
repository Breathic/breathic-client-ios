import Foundation

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

extension Array where Element: Sequence {
    func joined() -> Array<Element.Element> {
        return self.reduce([], +)
    }
}

extension Array {
    func repeated(count: Int) -> Array<Element> {
        assert(count > 0, "count must be greater than 0")

        var result = self
        for _ in 0 ..< count - 1 {
            result += self
        }

        return result
    }

    static func **(lhs: Array<Element>, rhs: Int) -> Array<Element> {
        return lhs.repeated(count: rhs)
    }
    
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
    
    func indexExists(_ index: Int) -> Bool {
      return self.indices.contains(index)
    }
}

infix operator **

struct Platform {
    static var isSimulator: Bool {
        return TARGET_OS_SIMULATOR != 0
    }
}
