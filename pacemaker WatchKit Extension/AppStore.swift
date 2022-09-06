import Foundation

struct AppState {
    var activeSubView: SubView = .main
    var seeds: [Seed] = []
    var distances: [Int: [Distance]] = readDistances(path: "data/distances.json")
    var ui: UI = UI()
    var history: [Int] = []
    var seedInputs: [SeedInput] = [
        SeedInput(durationRange: [0, 8], interval: [1, 1, 1, 1, 1, 1, 1, 1] ** 8, isPanning: true),
    ]
    var likes: [[Seed]] = []
    var likesIds: [String] = []
    var isAudioSessionLoaded: Bool = false
    var isAudioPlaying: Bool = false
    var selectedVolume: Int = 5
    var isDiscoveryEnabled = true
    var playerIndex: Int = -1
    var currentSampleIndex = 0
    var rhythmRange: [Int] = Array(1...50)
    var selectedInRhythm: Int = 10
    var selectedOutRhythm: Int = 10
    var rhythmTypes: [RhythmType] = [
        RhythmType(unit: "heartbeat/s", key: "averageHeartRatePerSecond", reversed: false, selectedRhythm: 10),
        RhythmType(unit: "step/s", key: "averageStepsPerSecond", reversed: false, selectedRhythm: 10),
        RhythmType(unit: "m/s", key: "averageMetersPerSecond", reversed: true, selectedRhythm: 10),
    ]
    var selectedRhythmTypeIndex = 0
    var averageHeartRatePerSecond: Double = 1
    var averageStepsPerSecond: Double = 1
    var averageMetersPerSecond: Double = 1
    
    func valueByKey(key: String) -> Double {
        switch key {
            case "averageHeartRatePerSecond": return averageHeartRatePerSecond
            case "averageStepsPerSecond": return averageStepsPerSecond
            case "averageMetersPerSecond": return averageMetersPerSecond
            default: fatalError("Key is undefined")
        }
    }
}

final class AppStore: ObservableObject {
    static let shared: AppStore = AppStore()

    @Published var state = AppState(activeSubView: .main)
}
