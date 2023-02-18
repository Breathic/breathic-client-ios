import Foundation
import SwiftUI

enum SubView {
    case main
    case rhythm
    case volume
}

enum Breathe: String, Codable {
    case BreatheIn = "breathe-in"
    case BreatheInHold = "breathe-in-hold"
    case BreatheOut = "breathe-out"
    case BreatheOutHold = "breathe-out-hold"
}

struct BreathingType: Codable {
    var key: Breathe
    var rhythm: Float = 0
}

struct Preset: Codable {
    var key: String = ""
    var breathingTypes: [BreathingType] = []
}

struct Activity: Codable {
    var label: String = ""
    var presets: [Preset] = []
}

struct MetricType {
    var metric: String = ""
    var label: String = ""
    var unit: String = ""
    var isReversed: Bool = false
    var isSource: Bool = false
    var isChartable: Bool = false
    var color: Color = Color.white
    var format: String = "%.0f"
    var defaultValue: Float = 0
}

class Track: Codable {
    var id: Int = 0
    var samples: [String] = []
}

class Seed: Codable {
    var tracks: [Track] = []
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
    let color: Color
    var id: String { metric }
}

class Session: Codable {
    var activity: Activity = ACTIVITIES["running"]! {
        didSet {
            save()
        }
    }

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
    var inRhythm: Float = RHYTHMS[0] {
        didSet {
            save()
        }
    }
    var outRhythm: Float = RHYTHMS[1] {
        didSet {
            save()
        }
    }
    var feedbackModeIndex: Int = 0 {
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
            uuid = UUID().uuidString
            id = generateSessionId(session: self)
        }

        isActive = true
    }

    func stop() {
        endTime = Date()
        isActive = false
    }

    func getRhythms() -> [Float] {
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
