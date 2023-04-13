import Foundation
import SwiftUI

enum Page: String, Codable {
    case Main = "Main"
    case Overview = "Overview"
}

enum SubView: String, Codable {
    case Guide = "Guide"
    case Terms = "Terms"
    case Menu = "Menu"
    case Controller = "Controller"
    case Status = "Status"
    case Activity = "Activity"
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
    case Audio = "audio"
    case Haptic = "haptic"
    case AudioHaptic = "audio haptic"
    case Muted = "muted"
}

enum TimeUnit: String, Codable {
    case Second = "second"
    case Minute = "minute"
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

class Channel: Codable {
    var tracks: [Track] = []
}

class Track: Codable {
    var id: Int = 0
    var samples: [String] = []
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
