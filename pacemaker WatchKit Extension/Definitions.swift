import Foundation
import AVFAudio

enum SubView {
    case main
    case rhythm
    case volume
}

struct MetricType {
    var metric: String = ""
    var unit: String = ""
    var isReversed: Bool = false
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
    let tertiaryTextSize = 6.0
    let borderLineWidth = 1.0
}

struct SeedInput {
    var durationRange: [Double] = []
    var interval: [Float] = []
}

class Step {
    var time: DispatchTime = .now()
    var count: Int = 0
}

class Update {
    var timestamp: Date = Date()
    var value: Float = 0
}

class Audio {
    var channelRepeatIndex: Int = 0
    var sampleIndex: Int = 0
    var channels: [[String]] = []
    var playerLabels: [String: AVAudioPlayer] = [:]
    var players: [AVAudioPlayer?] = []

    init(
        channelRepeatIndex: Int,
        sampleIndex: Int,
        channels: [[String]],
        playerLabels: [String: AVAudioPlayer],
        players: [AVAudioPlayer?]
    ) {
        self.channelRepeatIndex = channelRepeatIndex
        self.sampleIndex = sampleIndex
        self.channels = channels
        self.playerLabels = playerLabels
        self.players = players
    }

    func copy() -> Any {
        let copy = Audio(
            channelRepeatIndex: channelRepeatIndex,
            sampleIndex: sampleIndex,
            channels: channels,
            playerLabels: playerLabels,
            players: players)
        return copy
    }
}
