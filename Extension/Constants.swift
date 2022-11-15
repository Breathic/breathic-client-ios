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
let METRIC_TYPES: [String: MetricType] = [
    "heart": MetricType(
        metric: "heart",
        label: "Heartbeats",
        unit: "per minute",
        isSource: true,
        color: colorize("red")
    ),
    "step": MetricType(
        metric: "step",
        label: "Steps",
        unit: "per minute",
        isReversed: true,
        isSource: true,
        color: colorize("blue")
    ),
    "speed": MetricType(
        metric: "speed",
        label: "Speed",
        unit: "m / s",
        isSource: true,
        color: colorize("yellow")
    ),
    "breath": MetricType(
        metric: "breath",
        label: "Breaths",
        unit: "per minute",
        color: colorize("green")
    ),
    "heart-to-breath": MetricType(
        metric: "heart-to-breath",
        label: "Heartbreaths",
        unit: "per minute",
        color: colorize("teal")
    ),
    "step-to-breath": MetricType(
        metric: "step-to-breath",
        label: "Stepbreaths",
        unit: "per minute",
        color: colorize("blue")
    ),
    "speed-to-breath": MetricType(
        metric: "speed-to-breath",
        label: "Speedbreaths",
        unit: "per minute",
        color: colorize("yellow")
    ),
    "rhythm-in": MetricType(
        metric: "rhythm-in",
        label: "Rhythm (in)",
        unit: "per pace",
        color: colorize("purple"),
        format: "%.1f"
    ),
    "rhythm-out": MetricType(
        metric: "rhythm-out",
        label: "Rhythm (out)",
        unit: "per pace",
        color: colorize("orange"),
        format: "%.1f"
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
    "teal": (3, 253, 252),
    "purple": (160, 32, 240),
    "orange": (255, 87, 51),
    "gray": (63, 63, 63)
]
let METRIC_ORDER: [String] = [
    "breath",
    "heart",
    "step",
    "speed",
    "heart-to-breath",
    "step-to-breath",
    "speed-to-breath",
    "rhythm-in",
    "rhythm-out"
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
    "Overview": ["Chart", "Settings"]
]
let DEFAULT_PAGE = "Main"
let DEFAULT_ACTIVE_SUB_VIEW = "Controller"
let CROWN_MULTIPLIER: Float = 2
