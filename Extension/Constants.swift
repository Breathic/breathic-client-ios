import Foundation
import SwiftUI

let SAMPLE_PATH = "/data/samples/"
let SAMPLE_EXTENSION = "m4a"
let MAX_READING_COUNT: Int = 20
let DOWN_SCALE: Int = 1
let CHANNEL_REPEAT_COUNT: Int = 256
let FADE_DURATION: Int = CHANNEL_REPEAT_COUNT / 4
let DATA_INACTIVITY_S: Double = 60
let VOLUME_RANGE: [Float] = [0, 2000]
let VOLUME: Float = 500
let RHYTHM_RANGE: [Int] = [5, 50]
let RHYTHMS: [Int] = [20, 20]
let SEED_INPUTS = [
    SeedInput(durationRange: [0, 8], interval: [1])
]
let METRIC_TYPES = [
    MetricType(
        metric: "heart",
        label: "heart rate",
        unit: "minute",
        valueColor: colorize(color: "red"),
        isReversed: false
    )/*,
    MetricType(
        metric: "step",
        label: "step rate",
        unit: "minute",
        valueColor: colorize(color: "blue"),
        isReversed: true
    ),
    MetricType(
        metric: "speedMetric",
        unit: "m / s",
        isReversed: true
    )*/
]
let DEFAULT_BREATH: Float = Platform.isSimulator ? 60 : 0
let DEFAULT_HEART: Float = Platform.isSimulator ? 60 : 0
let DEFAULT_STEP: Float = Platform.isSimulator ? 60 : 0
let DEFAULT_SPEED: Float = Platform.isSimulator ? 3.6 : 0
let MONTH_LABELS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
let COLORS: [String: (Double, Double, Double)] = [
    "red": (242, 16, 75),
    "green": (161, 249, 2),
    "blue": (3, 221, 238),
    "gray": (63, 63, 63),
]
let TIMESERIES_SAVER_S: Double = 60
let DEFAULT_TIME_RESOLUTION: String = "1-min-avg"
let STORE_ACTIVE_SESSION = "ActiveSession"
let STORE_SESSION_LOGS = "SessionLogs"
