import Foundation
import SwiftUI

let SAMPLE_PATH = "data/samples"
let SAMPLE_EXTENSION = "m4a"
let MAX_READING_COUNT: Int = 30
let DOWN_SCALE: Int = 8
let CHANNEL_REPEAT_COUNT: Int = 128
let FADE_DURATION: Int = CHANNEL_REPEAT_COUNT / 2
let DATA_INACTIVITY_S: Double = 60
let COLORS: [String: Color] = [
    "red": Color(red: 242 / 255, green: 16 / 255, blue: 75 / 255),
    "green": Color(red: 161 / 255, green: 249 / 255, blue: 2 / 255),
    "blue": Color(red: 3 / 255, green: 221 / 255, blue: 238 / 255)
]
