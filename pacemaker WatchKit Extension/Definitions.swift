import Foundation

enum SubView {
    case main
    case rhythm
    case volume
}

class Rhythm: Codable {
    var id: Int = 0
    var samples: [String] = []
    var durationRange: [Double] = []
}

class Seed: Codable {
    var rhythms: [Rhythm] = []
    var isPanning: Bool = false
}

class Distance {
    var rightId: Int = 0
    var value: Double = 0.0
    var duration: Double = 0.0
}

class UI {
    let horizontalPadding = -8.0
    let verticalPadding = -8.0
    let width = 0.45
    let height = 0.9
    let primaryTextSize = 8.0
    let secondaryTextSize = 14.0
    let borderLineWidth = 1.0
}

struct SeedInput {
    var durationRange: [Double] = []
    var interval: [Float] = []
    var isPanning: Bool = false
}

class Step {
    var time: DispatchTime = .now()
    var count: Int = 0
}

struct RhythmType {
    var unit: String = ""
    var key: String = ""
}

class Track {
    var sampleIndex: Int = 0
    var channels: [[String]] = []
}
