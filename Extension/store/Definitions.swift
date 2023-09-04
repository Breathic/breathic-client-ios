import Foundation
import SwiftUI

class Session: ObservableObject, Codable {
    var activityIndex: Int = 0  {
        didSet {
            save()
        }
    }
    var activityKey: String = ACTIVITIES[0].key {
        didSet {
            save()
        }
    }
    var presetIndex: Int = 0 {
        didSet {
            save()
        }
    }
    var durationIndex: Int = 0 {
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
    var elapsedSeconds: Int = 0 {
        didSet {
            save()
        }
    }
    var startTime: Date = Date() {
        didSet {
            save()
        }
    }
    var endTime: Date? = nil {
        didSet {
            save()
        }
    }
    var startTimeUtc: String = "" {
        didSet {
            save()
        }
    }
    var endTimeUtc: String = "" {
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
    var syncStatus: SyncStatus = SyncStatus.Syncable {
        didSet {
            save()
        }
    }

    func start() {
        if elapsedSeconds == 0 {
            startTime = Date()
            uuid = UUID().uuidString
        }
    }

    func stop() {
        endTime = Date()
    }

    func save() {
        if self.isPlaying {
            saveActiveSession(self)
        }
    }

    func copy() -> Session {
        var result = Session()

        do {
            let encodedData = try JSONEncoder().encode(self)
            let session = try JSONDecoder().decode(Session.self, from: encodedData)
            session.isPlaying = false
            session.endTime = nil
            session.elapsedSeconds = 0
            session.syncStatus = SyncStatus.Syncable
            session.durationIndex = 0
            result = session
        } catch {
            print("Error: \(error)")
        }

        return result
    }

    func isStarted() -> Bool {
        self.elapsedSeconds > 0
    }
}

enum Page: String, Codable {
    case Main = "Main"
    case Overview = "Overview"
}

enum SubView: String, Codable {
    case Guide = "Guide"
    case Terms = "Terms"
    case Menu = "Menu"
    case Session = "Session"
    case Status = "Status"
    case Activity = "Activity"
    case Duration = "Duration"
    case Log = "Log"
    case Finish = "Finish"
    case Save = "Save"
    case Discard = "Discard"
    case Delete = "Delete"
    case Settings = "Settings"
}

enum Breathe: String, Codable {
    case BreatheIn = "breathe-in"
    case BreatheInHold = "breathe-in-hold"
    case BreatheOut = "breathe-out"
    case BreatheOutHold = "breathe-out-hold"
}

enum Feedback: String {
    case Music = "music"
    case Haptic = "haptic"
    case Both = "both"
    case Muted = "muted"
}

enum TimeUnit: String, Codable {
    case Second = "second"
    case Minute = "minute"
}

enum ChartScale: String, Codable {
    case Numeric = "numeric"
    case Percentage = "percentage"
}

enum LoopIntervalType: String, Codable {
    case Varied = "varied"
    case Fixed = "fixed"
}

struct BreathingStep: Codable {
    var key: Breathe
    var duration: Float = 0
    var format: String = "%.0f"
}

struct Preset: Codable {
    var key: String = ""
    var breathingSteps: [BreathingStep] = []
}

struct Activity: Codable {
    var key: String = ""
    var presets: [Preset] = []
    var loopIntervalType: LoopIntervalType
    var durationOptions: [String]
    var displayMetrics: [String]
}

struct MetricType {
    var metric: String = ""
    var abbreviation: String = ""
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

class Channel: Codable {
    var tracks: [Track] = []
}

class Distance {
    var rightId: Int = 0
    var value: Double = 0.0
}

typealias Overview = [String: Float]

typealias Distances = [Int: [Distance]]

typealias Instruments = [String: Distances]

class UI {
    let horizontalPadding: Double = -8.0
    let verticalPadding: Double = -8.0
    let width: Double = 0.45
    let height: Double = 0.9
    let primaryTextSize: Double = 8.0
    let secondaryTextSize: Double = 14.0
    let tertiaryTextSize: Double = 6.0
}

struct Sequence: Codable {
    var instrument: String = ""
    var isBreathing: Bool = false
    var pattern: [Int] = []
}

class Reading: Codable {
    var timestamp: Date = Date()
    var value: Float = 0
}

enum SyncStatus: String, Codable {
    case Syncable = "Syncable"
    case Syncing = "Syncing"
    case Synced = "Synced"
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
