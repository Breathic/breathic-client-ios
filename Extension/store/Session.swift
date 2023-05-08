import Foundation

class Session: ObservableObject, Codable {
    var activityIndex: Int = 0  {
        didSet {
            save()
        }
    }
    var activityKey: String = ACTIVITIES[0].key {
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
    var startTime: String = Date().formatted(.iso8601) {
        didSet {
            save()
        }
    }
    var endTime: String? = nil {
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
            startTime = Date().formatted(.iso8601)
            uuid = UUID().uuidString
        }
    }

    func stop() {
        endTime = Date().formatted(.iso8601)
    }

    func save() {
        if self.isPlaying {
            saveActiveSession(self)
        }
    }

    func copy() -> Session {
        var result = Session()

        do {
            let encodedData = try JSONEncoder().encode(self)
            let session = try JSONDecoder().decode(Session.self, from: encodedData)
            session.isPlaying = false
            session.endTime = nil
            session.elapsedSeconds = 0
            session.distance = 0
            session.syncStatus = SyncStatus.Syncable
            result = session
        } catch {
            print("Error: \(error)")
        }

        return result
    }

    func isStarted() -> Bool {
        self.elapsedSeconds > 0
    }
}
