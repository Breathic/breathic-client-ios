import Foundation
import SwiftUI

let SAMPLE_PATH = "/data/samples/"
let SAMPLE_EXTENSION = "m4a"
let MAX_READING_TIMEOUT_S: Double = 30
let MAX_READING_COUNT: Int = 100
let DOWN_SCALE: Int = 1
let CHANNEL_REPEAT_COUNT: Int = 256
let FADE_DURATION: Int = CHANNEL_REPEAT_COUNT / 4
let DATA_INACTIVITY_S: Double = 60
let VOLUME_RANGE: [Float] = [0, 2000]
let VOLUME: Float = 500
let RHYTHM_RANGE: [Int] = [1, 50]
let RHYTHMS: [Int] = [20, 20]
let SEED_INPUTS = [
    SeedInput(durationRange: [0, 8], interval: [1])
]
let METRIC_TYPES = [
    MetricType(
        metric: "heart",
        label: "heart rate",
        unit: "minute",
        valueColor: colorize("red"),
        isReversed: false
    ),
    MetricType(
        metric: "step",
        label: "step rate",
        unit: "minute",
        valueColor: colorize("blue"),
        isReversed: true
    ),
    MetricType(
        metric: "speed",
        label: "speed",
        unit: "m / s",
        valueColor: colorize("yellow"),
        isReversed: true
    )
]
let DEFAULT_METRICS: [String: Float] = [
    "breath": Platform.isSimulator ? 60 : 0,
    "heart": Platform.isSimulator ? 60 : 0,
    "step": Platform.isSimulator ? 60 : 0,
    "speed": Platform.isSimulator ? 10 : 0
]
let COLORS: [String: (Double, Double, Double)] = [
    "red": (242, 16, 75),
    "green": (161, 249, 2),
    "blue": (3, 221, 238),
    "yellow": (222, 252, 82),
    "gray": (63, 63, 63),
]
let TIMESERIES_SAVER_S: Double = 60
let DEFAULT_TIME_RESOLUTION: String = "1-min-avg"
let STORE_ACTIVE_SESSION = "ActiveSession"
let STORE_SESSION_LOGS = "SessionLogs"
let DRAG_INDEXES: [String: Int] = [
    "Controller": 0,
    "Status": 1,
    "Log": 0
]
let DEFAULT_MENU_VIEWS: [String: [String]] = [
    "Main": ["Controller", "Status", "Log"],
    "Overview": ["Chart", "Chart settings"]
]
let DEFAULT_PAGE = "Main"
let DEFAULT_ACTIVE_SUB_VIEW = "Controller"
let CROWN_MULTIPLIER: Float = 2
