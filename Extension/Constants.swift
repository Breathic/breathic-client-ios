import Foundation
import SwiftUI

let SAMPLE_PATH: String = "/data/samples/"
let SAMPLE_EXTENSION: String = "m4a"
let MAX_READING_TIMEOUT_S: Double = 15
let MAX_READING_COUNT: Int = 100
let DOWN_SCALE: Int = 1
let CHANNEL_REPEAT_COUNT: Int = 256
let FADE_DURATION: Int = CHANNEL_REPEAT_COUNT / 4
let DATA_INACTIVITY_S: Double = 60
let SESSION_COORDINATOR_INTERVAL_S: Double = 60
let READER_INACTIVITY_TIMEOUT_S: Double = 10
let VOLUME_RANGE: [Float] = [0, 5000]
let VOLUME: Float = 500
let RHYTHM_RANGE: [Int] = [5, 100]
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
        isChartable: true,
        color: colorize("red"),
        defaultValue: Platform.isSimulator ? 60 : 0
    ),
    "step": MetricType(
        metric: "step",
        label: "Steps",
        unit: "per minute",
        isReversed: true,
        isSource: true,
        color: colorize("teal"),
        defaultValue: Platform.isSimulator ? 60 : 0
    ),
    "speed": MetricType(
        metric: "speed",
        label: "Speed",
        unit: "m / s",
        isSource: true,
        isChartable: true,
        color: colorize("yellow"),
        defaultValue: Platform.isSimulator ? 10 : 0
    ),
    "breath": MetricType(
        metric: "breath",
        label: "Breaths",
        unit: "per minute",
        isChartable: true,
        color: colorize("green")
    ),
    "heart-to-breath": MetricType(
        metric: "heart-to-breath",
        label: "Heartbreaths",
        unit: "per minute",
        color: colorize("pink")
    ),
    "step-to-breath": MetricType(
        metric: "step-to-breath",
        label: "Stepbreaths",
        unit: "per minute",
        color: colorize("teal")
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
        color: colorize("blue"),
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
let COLORS: [String: (Double, Double, Double)] = [
    "white": (255, 255, 255),
    "red": (242, 16, 75),
    "green": (26, 163, 109),
    "blue": (0, 122, 255),
    "yellow": (222, 252, 82),
    "teal": (3, 253, 252),
    "pink": (230, 0, 126),
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
let TIMESERIES_SAVER_INTERVAL_S: Double = 60
let DEFAULT_TIME_RESOLUTION: String = "1-min-avg"
let STORE_ACTIVE_SESSION: String = "ActiveSession"
let STORE_SESSION_LOGS: String = "SessionLogs"
let DRAG_INDEXES: [String: Int] = [
    "Controller": 0,
    "Status": 1,
    "Log": 0
]
let DEFAULT_MENU_VIEWS: [String: [String]] = [
    "Main": ["Controller", "Status", "Log"],
    "Overview": ["", ""]
]
let DEFAULT_PAGE: String = "Main"
let DEFAULT_ACTIVE_SUB_VIEW: String = "Controller"
let CROWN_MULTIPLIER: Float = 2
let DEFAULT_CHART_SCALES: [String: Bool] = [
    "Numeric": true,
    "Percentage": false
]
//let SENTRY_DSN = "https://104bfdd0d1f9498bba4cbaca12988611@o1399372.ingest.sentry.io/6726680"
