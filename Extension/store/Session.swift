import Foundation

class Session: ObservableObject, Codable {
    var activityIndex: Int = 0  {
        didSet {
            save()
        }
    }
    var presetIndex: Int = 0 {
        didSet {
            save()
        }
    }
    var isActive: Bool = false {
        didSet {
            save()
        }
    }
    var isPlaying: Bool = false {
        didSet {
            save()
        }
    }
    var uuid: String = UUID().uuidString {
        didSet {
            save()
        }
    }
    var elapsedSeconds: Int = 0 {
        didSet {
            save()
        }
    }
    var startTime: Date = Date() {
        didSet {
            save()
        }
    }
    var distance: Float = 0 {
        didSet {
            save()
        }
    }
    var endTime: Date? = nil {
        didSet {
            save()
        }
    }
    var feedbackModeIndex: Int = 0 {
        didSet {
            save()
        }
    }
    var volume: Float = VOLUME {
        didSet {
            save()
        }
    }
    var metricTypeIndex: Int = 0 {
        didSet {
            save()
        }
    }
    var syncStatus: SyncStatus = SyncStatus.Syncable {
        didSet {
            save()
        }
    }

    func start() {
        if !isActive {
            startTime = Date()
            uuid = UUID().uuidString
        }

        isActive = true
    }

    func stop() {
        endTime = Date()
        isActive = false
    }

    func save() {
        guard let data: Data = try? JSONEncoder().encode(self) else { return }
        let url = getDocumentsDirectory().appendingPathComponent(ACTIVE_SESSION_FILE_NAME)
        writeToFile(url: url, data: data)
    }
}
