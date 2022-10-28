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

class Step {
    var time: DispatchTime = .now()
    var count: Int = 0
}

class Update {
    var timestamp: Date = Date()
    var value: Float = 0
}

class Audio {
    var channelRepeatIndex: Int = 0
    var sampleIndex: Int = 0
    var channels: [[String]] = []
    var forResources: [String] = []

    init(
        channelRepeatIndex: Int,
        sampleIndex: Int,
        channels: [[String]],
        forResources: [String]
    ) {
        self.channelRepeatIndex = channelRepeatIndex
        self.sampleIndex = sampleIndex
        self.channels = channels
        self.forResources = forResources
    }

    func copy() -> Any {
        let copy = Audio(
            channelRepeatIndex: channelRepeatIndex,
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

class ParsedData {
    var min: Float = 0
    var max: Float = 0
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
    var elapsedTime: String = "" {
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
    var volume: Float = VOLUME_RANGE[1] / 2 {
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
            isActive = true
            startTime = Date()
            endTime = startTime
            elapsedTime = ""
            uuid = UUID().uuidString
            id = generateSessionId(session: self)
        }
    }

    func stop() {
        isActive = false
        endTime = Date()
    }

    func getRhythms() -> [Int] {
        return [inRhythm, outRhythm]
    }

    func save() {
        writeActiveSession(session: self)
    }
}
