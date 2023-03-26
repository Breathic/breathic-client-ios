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
    var endTime: Date? = nil {
        didSet {
            save()
        }
    }
    var distance: Float = 0 {
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
        if elapsedSeconds == 0 {
            startTime = Date()
            uuid = UUID().uuidString
        }
    }

    func stop() {
        endTime = Date()
    }

    func save() {
        saveActiveSession(self)
    }

    func copy() -> Session {
        var result = Session()
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        do {
            let encodedData = try encoder.encode(self)
            let session = try decoder.decode(Session.self, from: encodedData)
            session.endTime = nil
            session.elapsedSeconds = 0
            session.distance = 0
            session.syncStatus = SyncStatus.Syncable
            result = session
        } catch {
            print("Error: \(error)")
        }

        saveActiveSession(result)
        return result
    }

    func isStarted() -> Bool {
        self.elapsedSeconds > 0
    }
}
