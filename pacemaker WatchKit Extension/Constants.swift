import Foundation
import SwiftUI

let SAMPLE_PATH = "/data/samples/"
let SAMPLE_EXTENSION = "m4a"
let MAX_READING_COUNT: Int = 20
let DOWN_SCALE: Int = 8
let CHANNEL_REPEAT_COUNT: Int = 128
let FADE_DURATION: Int = CHANNEL_REPEAT_COUNT / 2
let DATA_INACTIVITY_S: Double = 60
let AUDIO_RANGE: [Float] = [0, 100]
