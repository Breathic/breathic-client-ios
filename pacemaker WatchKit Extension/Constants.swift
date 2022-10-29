import Foundation
import SwiftUI

let SAMPLE_PATH = "/data/samples/"
let SAMPLE_EXTENSION = "m4a"
let MAX_READING_COUNT: Int = 20
let DOWN_SCALE: Int = 1
let CHANNEL_REPEAT_COUNT: Int = 256
let FADE_DURATION: Int = CHANNEL_REPEAT_COUNT / 2
let DATA_INACTIVITY_S: Double = 60
let VOLUME_RANGE: [Float] = [0, 100]
let RHYTHM_RANGE: [Int] = Array(1...50)
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
    ),
    MetricType(
        metric: "step",
        label: "step rate",
        unit: "minute",
        valueColor: colorize(color: "blue"),
        isReversed: true
    )/*,
    MetricType(
        metric: "speedMetric",
        unit: "m / s",
        isReversed: true
    )*/
]
