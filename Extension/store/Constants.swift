import Foundation
import SwiftUI

let API_URL: String = Bundle.main.infoDictionary!["API_URL"]! as! String
let APP_ENV: String = Bundle.main.infoDictionary!["APP_ENV"]! as! String
let TERMS_AND_CONDITIONS_URL: String = "https://breathic.com/terms-and-conditions.html"
let PRIVACY_POLICY_URL: String = "https://breathic.com/privacy-policy.html"
let GUIDE_URL: String = "https://breathic.com"
let DISTANCE_PATH: String = "/data/distances"
let SAMPLE_PATH: String = "/data/samples"
let SAMPLE_EXTENSION: String = "m4a"
let MAX_READING_TIMEOUT_S: Double = 15
let MAX_READING_COUNT: Int = 100
let DOWN_SCALE: Int = 1
let CHANNEL_REPEAT_COUNT: Int = 128
let FADE_DURATION: Int = CHANNEL_REPEAT_COUNT / 4
let SESSION_COORDINATOR_INTERVAL_S: Double = 60
let READER_INACTIVITY_TIMEOUT_S: Double = 10
let VOLUME_RANGE: [Float] = [0, 5000]
let VOLUME: Float = 1250
let MUSIC_VOLUME_PCT: Float = 0.02
let RHYTHM_RANGE: [Float] = [0.5, 10]
let RHYTHMS: [Float] = [2, 2]
let SEQUENCES = [
    Sequence(
        instrument: "breathing",
        isBreathing: true,
        pattern: [
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
            1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1,
        ]
    ),
    Sequence(
        instrument: "ambient",
        pattern: [
            16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        ]
    )
]
let RUN_PRESETS: [Preset] = [
    Preset(
        key: "4",
        breathingTypes: [
            BreathingType(
                key: Breathe.BreatheIn,
                rhythm: 4
            ),
            BreathingType(
                key: Breathe.BreatheOut,
                rhythm: 4
            )
        ]
    ),
    Preset(
        key: "3.5",
        breathingTypes: [
            BreathingType(
                key: Breathe.BreatheIn,
                rhythm: 3.5
            ),
            BreathingType(
                key: Breathe.BreatheOut,
                rhythm: 3.5
            )
        ]
    ),
    Preset(
        key: "3",
        breathingTypes: [
            BreathingType(
                key: Breathe.BreatheIn,
                rhythm: 3
            ),
            BreathingType(
                key: Breathe.BreatheOut,
                rhythm: 3
            )
        ]
    ),
    Preset(
        key: "2.5",
        breathingTypes: [
            BreathingType(
                key: Breathe.BreatheIn,
                rhythm: 2.5
            ),
            BreathingType(
                key: Breathe.BreatheOut,
                rhythm: 2.5
            )
        ]
    ),
    Preset(
        key: "2",
        breathingTypes: [
            BreathingType(
                key: Breathe.BreatheIn,
                rhythm: 2
            ),
            BreathingType(
                key: Breathe.BreatheOut,
                rhythm: 2
            )
        ]
    )
]
let RIDE_PRESETS: [Preset] = [
    Preset(
        key: "6",
        breathingTypes: [
            BreathingType(
                key: Breathe.BreatheIn,
                rhythm: 6
            ),
            BreathingType(
                key: Breathe.BreatheOut,
                rhythm: 6
            )
        ]
    ),
    Preset(
        key: "5",
        breathingTypes: [
            BreathingType(
                key: Breathe.BreatheIn,
                rhythm: 5
            ),
            BreathingType(
                key: Breathe.BreatheOut,
                rhythm: 5
            )
        ]
    ),
    Preset(
        key: "4",
        breathingTypes: [
            BreathingType(
                key: Breathe.BreatheIn,
                rhythm: 4
            ),
            BreathingType(
                key: Breathe.BreatheOut,
                rhythm: 4
            )
        ]
    ),
    Preset(
        key: "3",
        breathingTypes: [
            BreathingType(
                key: Breathe.BreatheIn,
                rhythm: 3
            ),
            BreathingType(
                key: Breathe.BreatheOut,
                rhythm: 3
            )
        ]
    ),
    Preset(
        key: "2",
        breathingTypes: [
            BreathingType(
                key: Breathe.BreatheIn,
                rhythm: 2
            ),
            BreathingType(
                key: Breathe.BreatheOut,
                rhythm: 2
            )
        ]
    )
]
let ACTIVITIES: [Activity] = [
    Activity(
        key: "run",
        label: "Run",
        presets: RUN_PRESETS
    ),
    Activity(
        key: "ride",
        label: "Ride",
        presets: RIDE_PRESETS
    )
]
let METRIC_TYPES: [String: MetricType] = [
    "heart": MetricType(
        metric: "heart",
        abbreviation: "h",
        label: "Heartbeats",
        unit: "per minute",
        isSource: true,
        isChartable: true,
        color: colorize("red"),
        defaultValue: Platform.isSimulator ? 150 : 0
    ),
    "step": MetricType(
        metric: "step",
        abbreviation: "s",
        label: "Steps",
        unit: "per minute",
        color: colorize("teal"),
        defaultValue: Platform.isSimulator ? 60 : 0
    ),
    "speed": MetricType(
        metric: "speed",
        abbreviation: "sp",
        label: "Speed",
        unit: "m / s",
        isChartable: true,
        color: colorize("yellow"),
        defaultValue: Platform.isSimulator ? 10 : 0
    ),
    "breath": MetricType(
        metric: "breath",
        abbreviation: "b",
        label: "Breaths",
        unit: "per minute",
        isChartable: true,
        color: colorize("green")
    ),
    "breathe-in": MetricType(
        metric: "breathe-in",
        abbreviation: "bi",
        label: "Breathe in",
        unit: "per pace",
        color: colorize("blue"),
        format: "%.1f"
    ),
    "breathe-in-hold": MetricType(
        metric: "breathe-in-hold",
        abbreviation: "bih",
        label: "Breathe in & hold",
        unit: "per pace",
        color: colorize("blue"),
        format: "%.1f"
    ),
    "breathe-out": MetricType(
        metric: "breathe-out",
        abbreviation: "bo",
        label: "Breathe out",
        unit: "per pace",
        color: colorize("orange"),
        format: "%.1f"
    ),
    "breathe-out-hold": MetricType(
        metric: "breathe-out-hold",
        abbreviation: "boh",
        label: "Breathe out & hold",
        unit: "per pace",
        color: colorize("orange"),
        format: "%.1f"
    ),
    "sample-id": MetricType(
        metric: "sample-id",
        abbreviation: "sid"
    ),
    "longitude": MetricType(
        metric: "longitude",
        abbreviation: "lon"
    ),
    "latitude": MetricType(
        metric: "latitude",
        abbreviation: "lat"
    ),
    "distance": MetricType(
        metric: "distance",
        abbreviation: "d"
    ),
    "altitude": MetricType(
        metric: "altitude",
        abbreviation: "a",
        label: "Altitude",
        unit: "m",
        isChartable: false,
        color: colorize("purple"),
        defaultValue: Platform.isSimulator ? 10 : 0
    ),
]
let COLORS: [String: (Double, Double, Double)] = [
    "black": (0, 0, 0),
    "white": (255, 255, 255),
    "red": (242, 16, 75),
    "green": (26, 163, 109),
    "blue": (0, 122, 255),
    "yellow": (222, 252, 82),
    "teal": (3, 253, 252),
    "pink": (230, 0, 126),
    "purple": (160, 32, 240),
    "orange": (255, 87, 51),
    "gray": (63, 63, 63),
    "brown": (139,69,19),
]
let METRIC_ORDER: [String] = [
    "breath",
    "heart",
    "step",
    "speed",
    "breathe-in",
    "breathe-in-hold",
    "breathe-out",
    "breathe-out-hold",
    "altitude",
]
let FEEDBACK_MODES: [Feedback] = [
    Feedback.Audio,
    Feedback.Haptic,
    Feedback.Muted,
]
let TIMESERIES_SAVER_INTERVAL_SECONDLY: Double = 1
let TIMESERIES_SAVER_INTERVAL_MINUTELY: Double = 60
let ACTIVE_SESSION_FILE_NAME: String = "ActiveSession"
let SESSIONS_FOLDER_NAME: String = "Sessions"
let TERMS_APPROVAL_NAME: String = "TermsApproval"
let GUIDE_SEEN_NAME: String = "GuideSeen"
let DRAG_INDEXES: [String: Int] = [
    SubView.Controller.rawValue: 0,
    SubView.Status.rawValue: 1
]
let MENU_VIEWS: [String: [String]] = [
    Page.Main.rawValue: [
        SubView.Controller.rawValue,
        SubView.Status.rawValue,
        SubView.Guide.rawValue,
        SubView.Terms.rawValue,
        SubView.Log.rawValue,
    ],
    Page.Overview.rawValue: ["", ""]
]
let DEFAULT_PAGE: String = Page.Main.rawValue
let DEFAULT_ACTIVE_SUB_VIEW: String = SubView.Controller.rawValue
let CROWN_MULTIPLIER: Float = 2
let DEFAULT_CHART_SCALES: [String: Bool] = [
    "Numeric": true,
    "Percentage": false
]
let CONFIRMATION_DEFAULT_VALUE: Double = 0.25
let CONFIRMATION_ENOUGH_VALUE: Double = 0.75
let SYNC_INTERVAL_S: Double = 60
//let SENTRY_DSN = "https://104bfdd0d1f9498bba4cbaca12988611@o1399372.ingest.sentry.io/6726680"
