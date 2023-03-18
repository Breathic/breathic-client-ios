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
    var id: String = "" {
        didSet {
            save()
        }
    }
    var startTime: Date = Date() {
        didSet {
            save()
        }
    }
    var endTime: Date = Date() {
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

    var uploadStatus: UploadStatus = UploadStatus.UploadStart {
        didSet {
            save()
        }
    }

    func start() {
        if !isActive {
            startTime = Date()
            uuid = UUID().uuidString
            id = generateSessionId(session: self)
        }

        isActive = true
    }

    func stop() {
        endTime = Date()
        isActive = false
    }

    func save() {
        guard let data: Data = try? JSONEncoder().encode(self) else { return }
        let url = getDocumentsDirectory().appendingPathComponent(STORE_ACTIVE_SESSION)
        writeToFile(url: url, data: data)
    }
}
