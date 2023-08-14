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
let MOTION_UPDATE_FREQUENCY: Double = 10
let CHANNEL_REPEAT_COUNT: Int = 128
let FADE_DURATION: Int = CHANNEL_REPEAT_COUNT / 4
let SESSION_COORDINATOR_INTERVAL_S: Double = 60
let READER_INACTIVITY_TIMEOUT_S: Double = 10
let VOLUME_RANGE: [Float] = [0, 5000]
let VOLUME: Float = 1250
let MUSIC_VOLUME_PCT: Float = 0.05
let PICKER_RANDOM_COUNT: Int = 3
let FINISH_DELAY_S: Double = 1
let FINISH_NOTIFICATION_COUNT: Int = 3
let FINISH_NOTIFICATION_DELAY_S: TimeInterval = 0.33
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
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            32, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
        ]
    )
]
let MOVE_PRESETS: [Preset] = [
    Preset(
        key: "4-4",
        breathingSteps: [
            BreathingStep(
                key: Breathe.BreatheIn,
                duration: 4
            ),
            BreathingStep(
                key: Breathe.BreatheOut,
                duration: 4
            )
        ]
    ),
    Preset(
        key: "3.75-3.75",
        breathingSteps: [
            BreathingStep(
                key: Breathe.BreatheIn,
                duration: 3.75,
                format: "%.2f"
            ),
            BreathingStep(
                key: Breathe.BreatheOut,
                duration: 3.75,
                format: "%.2f"
            )
        ]
    ),
    Preset(
        key: "3.5-3.5",
        breathingSteps: [
            BreathingStep(
                key: Breathe.BreatheIn,
                duration: 3.5,
                format: "%.1f"
            ),
            BreathingStep(
                key: Breathe.BreatheOut,
                duration: 3.5,
                format: "%.1f"
            )
        ]
    ),
    Preset(
        key: "3.25-3.25",
        breathingSteps: [
            BreathingStep(
                key: Breathe.BreatheIn,
                duration: 3.25,
                format: "%.2f"
            ),
            BreathingStep(
                key: Breathe.BreatheOut,
                duration: 3.25,
                format: "%.2f"
            )
        ]
    ),
    Preset(
        key: "3-3",
        breathingSteps: [
            BreathingStep(
                key: Breathe.BreatheIn,
                duration: 3
            ),
            BreathingStep(
                key: Breathe.BreatheOut,
                duration: 3
            )
        ]
    ),
    Preset(
        key: "2.75-2.75",
        breathingSteps: [
            BreathingStep(
                key: Breathe.BreatheIn,
                duration: 2.75,
                format: "%.2f"
            ),
            BreathingStep(
                key: Breathe.BreatheOut,
                duration: 2.75,
                format: "%.2f"
            )
        ]
    ),
    Preset(
        key: "2.5-2.5",
        breathingSteps: [
            BreathingStep(
                key: Breathe.BreatheIn,
                duration: 2.5,
                format: "%.1f"
            ),
            BreathingStep(
                key: Breathe.BreatheOut,
                duration: 2.5,
                format: "%.1f"
            )
        ]
    ),
    Preset(
        key: "2.25-2.25",
        breathingSteps: [
            BreathingStep(
                key: Breathe.BreatheIn,
                duration: 2.25,
                format: "%.2f"
            ),
            BreathingStep(
                key: Breathe.BreatheOut,
                duration: 2.25,
                format: "%.2f"
            )
        ]
    ),
    Preset(
        key: "2-2",
        breathingSteps: [
            BreathingStep(
                key: Breathe.BreatheIn,
                duration: 2
            ),
            BreathingStep(
                key: Breathe.BreatheOut,
                duration: 2
            )
        ]
    )
]
let RELAX_PRESETS: [Preset] = [
    Preset(
        key: "4-4-4-4",
        breathingSteps: [
            BreathingStep(
                key: Breathe.BreatheIn,
                duration: 4
            ),
            BreathingStep(
                key: Breathe.BreatheInHold,
                duration: 4
            ),
            BreathingStep(
                key: Breathe.BreatheOut,
                duration: 4
            ),
            BreathingStep(
                key: Breathe.BreatheOutHold,
                duration: 4
            )
        ]
    )
]
/*
let SLEEP_PRESETS: [Preset] = [
    Preset(
        key: "4-7-8",
        breathingSteps: [
            BreathingStep(
                key: Breathe.BreatheIn,
                duration: 4
            ),
            BreathingStep(
                key: Breathe.BreatheInHold,
                duration: 7
            ),
            BreathingStep(
                key: Breathe.BreatheOut,
                duration: 8
            )
        ]
    )
]
*/
let DEFAULT_DURATION_OPTIONS: [String] = [
    "∞",
    "1 minutes",
    "2 minutes",
    "3 minutes",
    "4 minutes",
    "5 minutes",
    "6 minutes",
    "7 minutes",
    "8 minutes",
    "9 minutes",
    "10 minutes",
    "11 minutes",
    "12 minutes",
    "13 minutes",
    "14 minutes",
    "15 minutes",
    "16 minutes",
    "17 minutes",
    "18 minutes",
    "19 minutes",
    "20 minutes",
    "21 minutes",
    "22 minutes",
    "23 minutes",
    "24 minutes",
    "25 minutes",
    "26 minutes",
    "27 minutes",
    "28 minutes",
    "29 minutes",
    "30 minutes",
    "31 minutes",
    "32 minutes",
    "33 minutes",
    "34 minutes",
    "35 minutes",
    "36 minutes",
    "37 minutes",
    "38 minutes",
    "39 minutes",
    "40 minutes",
    "41 minutes",
    "42 minutes",
    "43 minutes",
    "44 minutes",
    "45 minutes",
    "46 minutes",
    "47 minutes",
    "48 minutes",
    "49 minutes",
    "50 minutes",
    "51 minutes",
    "52 minutes",
    "53 minutes",
    "54 minutes",
    "55 minutes",
    "56 minutes",
    "57 minutes",
    "58 minutes",
    "59 minutes",
    "60 minutes",
]
let MINIMAL_DISPLAY_METRICS: [String] = [
    "heart"
]
let DEFAULT_DISPLAY_METRICS: [String] = [
    "breath",
    "heart",
    "step",
    "speed",
    "altitude",
]
let ACTIVITIES: [Activity] = [
    Activity(
        key: "Move",
        presets: MOVE_PRESETS,
        loopIntervalType: LoopIntervalType.Varied,
        durationOptions: DEFAULT_DURATION_OPTIONS,
        displayMetrics: DEFAULT_DISPLAY_METRICS
    ),
    Activity(
        key: "Relax",
        presets: RELAX_PRESETS,
        loopIntervalType: LoopIntervalType.Fixed,
        durationOptions: DEFAULT_DURATION_OPTIONS,
        displayMetrics: MINIMAL_DISPLAY_METRICS
    ),
    /*
    Activity(
        key: "Sleep",
        presets: SLEEP_PRESETS,
        loopIntervalType: LoopIntervalType.Fixed,
        durationOptions: DEFAULT_DURATION_OPTIONS,
        displayMetrics: MINIMAL_DISPLAY_METRICS
    )
    */
]
let METRIC_TYPES: [String: MetricType] = [
    "heart": MetricType(
        metric: "heart",
        abbreviation: "h",
        label: "Heart rate",
        unit: "min",
        isSource: true,
        isChartable: true,
        color: colorize("red"),
        defaultValue: Platform.isSimulator ? 150 : 0
    ),
    "step": MetricType(
        metric: "step",
        abbreviation: "s",
        label: "Step rate",
        unit: "min",
        color: colorize("yellow"),
        format: "%.1f",
        defaultValue: Platform.isSimulator ? 60 : 0
    ),
    "speed": MetricType(
        metric: "speed",
        abbreviation: "sp",
        label: "Speed",
        unit: "m / s",
        isChartable: true,
        color: colorize("blue"),
        format: "%.1f",
        defaultValue: Platform.isSimulator ? 10 : 0
    ),
    "breath": MetricType(
        metric: "breath",
        abbreviation: "b",
        label: "Breath rate",
        unit: "min",
        isChartable: true,
        color: colorize("green"),
        format: "%.1f"
    ),
    "breathe-in": MetricType(
        metric: "breathe-in",
        abbreviation: "bi",
        label: "Breathe in",
        unit: "pace",
        color: colorize("pink"),
        format: "%.1f"
    ),
    "breathe-in-hold": MetricType(
        metric: "breathe-in-hold",
        abbreviation: "bih",
        label: "Breathe in & hold",
        unit: "pace",
        color: colorize("pink"),
        format: "%.1f"
    ),
    "breathe-out": MetricType(
        metric: "breathe-out",
        abbreviation: "bo",
        label: "Breathe out",
        unit: "pace",
        color: colorize("orange"),
        format: "%.1f"
    ),
    "breathe-out-hold": MetricType(
        metric: "breathe-out-hold",
        abbreviation: "boh",
        label: "Breathe out & hold",
        unit: "pace",
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
        abbreviation: "d",
        unit: "m",
        color: colorize("teal"),
        format: "%.1f"
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
    "acceleration-x": MetricType(
        metric: "acceleration-x",
        abbreviation: "ax"
    ),
    "acceleration-y": MetricType(
        metric: "acceleration-y",
        abbreviation: "ay"
    ),
    "acceleration-z": MetricType(
        metric: "acceleration-z",
        abbreviation: "az"
    ),
    "rotation-x": MetricType(
        metric: "rotation-x",
        abbreviation: "rx"
    ),
    "rotation-y": MetricType(
        metric: "rotation-y",
        abbreviation: "ry"
    ),
    "rotation-z": MetricType(
        metric: "rotation-z",
        abbreviation: "rz"
    ),
]
let COLORS: [String: (Double, Double, Double)] = [
    "black": (0, 0, 0),
    "white": (255, 255, 255),
    "red": (242, 16, 75),
    "green": (33, 196, 80),
    "blue": (82, 148, 255),
    "yellow": (187, 196, 27),
    "teal": (29, 209, 208),
    "pink": (230, 0, 126),
    "purple": (160, 32, 240),
    "orange": (255, 87, 51),
    "gray": (63, 63, 63),
    "brown": (139,69,19),
]
let FEEDBACK_MODES: [Feedback] = [
    Feedback.Music,
    Feedback.HapticMusic,
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
    SubView.Session.rawValue: 0,
    SubView.Status.rawValue: 1
]
let MENU_VIEWS: [String] = [
    SubView.Session.rawValue,
    SubView.Guide.rawValue,
    SubView.Terms.rawValue,
    SubView.Log.rawValue
]
let SUB_VIEW: [String] = [
    SubView.Session.rawValue,
    SubView.Status.rawValue,
]
let DEFAULT_PAGE: String = Page.Main.rawValue
let DEFAULT_ACTIVE_SUB_VIEW: String = SubView.Session.rawValue
let CROWN_MULTIPLIER: Float = 2
let DEFAULT_CHART_SCALES: [ChartScale: Bool] = [
    ChartScale.Numeric: true,
    ChartScale.Percentage: false
]
let CONFIRMATION_DEFAULT_VALUE: Double = 0.25
let CONFIRMATION_ENOUGH_VALUE: Double = 0.75
let SYNC_INTERVAL_S: Double = 60
//let SENTRY_DSN = "https://104bfdd0d1f9498bba4cbaca12988611@o1399372.ingest.sentry.io/6726680"
