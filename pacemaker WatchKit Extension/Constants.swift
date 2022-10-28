import Foundation
import SwiftUI

let SAMPLE_PATH = "/data/samples/"
let SAMPLE_EXTENSION = "m4a"
let MAX_READING_COUNT: Int = 20
let DOWN_SCALE: Int = 8
let CHANNEL_REPEAT_COUNT: Int = 128
let FADE_DURATION: Int = CHANNEL_REPEAT_COUNT / 2
let DATA_INACTIVITY_S: Double = 60
let VOLUME_RANGE: [Float] = [0, 100]
let RHYTHM_RANGE: [Int] = Array(10...50)
let SEED_INPUTS = [
    SeedInput(durationRange: [0, 8], interval: [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0])
]
