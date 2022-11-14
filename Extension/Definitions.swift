import Foundation
import SwiftUI

enum SubView {
    case main
    case rhythm
    case volume
}

struct MetricType {
    var metric: String = ""
    var label: String = ""
    var unit: String = ""
    var valueColor: Color = Color.white
    var isReversed: Bool = false
}

class Rhythm: Codable {
    var id: Int = 0
    var samples: [String] = []
    //var durationRange: [Double] = []
}

class Seed: Codable {
    var rhythms: [Rhythm] = []
    var isPanning: Bool = false
}

class Distance {
    var rightId: Int = 0
    var value: Double = 0.0
    var duration: Double = 0.0
}

class UI {
    let horizontalPadding = -8.0
    let verticalPadding = -8.0
    let width = 0.45
    let height = 0.9
    let primaryTextSize = 8.0
    let secondaryTextSize = 14.0
    let tertiaryTextSize = 6.0
}

struct SeedInput {
    var durationRange: [Double] = []
    var interval: [Float] = []
}

class Reading: Codable {
    var timestamp: Date = Date()
    var value: Float = 0
}

class Audio {
    var fadeIndex: Int = 0
    var sampleIndex: Int = 0
    var channels: [[String]] = []
    var forResources: [String] = []

    init(
        fadeIndex: Int,
        sampleIndex: Int,
        channels: [[String]],
        forResources: [String]
    ) {
        self.fadeIndex = fadeIndex
        self.sampleIndex = sampleIndex
        self.channels = channels
        self.forResources = forResources
    }

    func copy() -> Any {
        let copy = Audio(
            fadeIndex: fadeIndex,
            sampleIndex: sampleIndex,
            channels: channels,
            forResources: forResources
        )
        return copy
    }
}

struct ProgressData: Identifiable {
    let timestamp: Int
    let value: Float
    var id: Int { timestamp }
}

struct SeriesData: Identifiable {
    let metric: String
    let data: [ProgressData]
    var id: String { metric }
}

class Session: Codable {
    var isActive: Bool = false {
        didSet {
            save()
        }
    }
    var uuid: String = UUID().uuidString {
        didSet {
            save()
        }
    }
    var id: String = "" {
        didSet {
            save()
        }
    }
    var startTime: Date = Date() {
        didSet {
            save()
        }
    }
    var endTime: Date = Date() {
        didSet {
            save()
        }
    }
    var inRhythm: Int = RHYTHMS[0] {
        didSet {
            save()
        }
    }
    var outRhythm: Int = RHYTHMS[1] {
        didSet {
            save()
        }
    }
    var volume: Float = VOLUME {
        didSet {
            save()
        }
    }
    var metricTypeIndex: Int = 0 {
        didSet {
            save()
        }
    }

    func start() {
        if !isActive {
            startTime = Date()
            endTime = Date()
            uuid = UUID().uuidString
            id = generateSessionId(session: self)
        }

        isActive = true
    }

    func stop() {
        isActive = false
        endTime = Date()
    }

    func getRhythms() -> [Int] {
        return [inRhythm, outRhythm]
    }

    func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        writeToFile(key: STORE_ACTIVE_SESSION, data: data)
    }
}

class ChartDomain {
    var xMin: Float = 0
    var xMax: Float = 0
    var yMin: Float = 0
    var yMax: Float = 0
}

struct PageOption {
    var dragIndex: Int = 0
    var dragXOffset = CGFloat(0)
    var wasDragged = false
}
