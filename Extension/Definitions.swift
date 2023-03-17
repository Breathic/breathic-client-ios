import Foundation
import SwiftUI
import SwiftDate

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
    var key: String = ""
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
    let horizontalPadding: Double = -8.0
    let verticalPadding: Double = -8.0
    let width: Double = 0.45
    let height: Double = 0.9
    let primaryTextSize: Double = 8.0
    let secondaryTextSize: Double = 14.0
    let tertiaryTextSize: Double = 6.0
}

struct SeedInput {
    var durationRange: [Double] = []
    var interval: [Float] = []
}

class Reading: Codable {
    var timestamp: Date = Date()
    var value: Float = 0
}

enum UploadStatus: String, Codable {
    case UploadStart = "upload"
    case Uploading = "uploading"
    case Uploaded = "uploaded"
    case UploadRetry = "retry upload"
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
        let copy: Audio = Audio(
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

typealias ReadingContainer = [String: [Reading]]

class Session: Codable {
    var activityKey: String = ACTIVITIES.map { $0.key }[0] {
        didSet {
            save()
        }
    }
    var audioPanningIndex: Int = 0 {
        didSet {
            save()
        }
    }
    var presetIndex: Int = 0 {
        didSet {
            save()
        }
    }
    var isActive: Bool = false {
        didSet {
            save()
        }
    }
    var isPlaying: Bool = false {
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

    var uploadStatus: UploadStatus = UploadStatus.UploadStart {
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

    func save() {
        guard let data: Data = try? JSONEncoder().encode(self) else { return }
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
    var dragXOffset: CGFloat = CGFloat(0)
    var wasDragged: Bool = false
}
