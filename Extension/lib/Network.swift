import WatchKit
import WatchConnectivity

func uploadSession(_ session: Session) async -> Bool {
    do {
        struct RequestData: Encodable {
            let sessionUuid: String
            let deviceUuid: String
            let payload: String
            let startTimeEpoch: Int
            let endTimeEpoch: Int
        }

        if WKInterfaceDevice.current().identifierForVendor != nil {
            let timeseriesData: ReadingContainer = getTimeseriesData(
                uuid: session.uuid,
                startTime: session.startTime,
                endTime: session.endTime!,
                timeUnit: TimeUnit.Second
            )
            let payload: String = buildSessionPayload(timeseriesData: timeseriesData)
            let url = URL(string: API_URL + "/session")!
            let sessionUuid = session.uuid;
            let deviceUuid = WKInterfaceDevice.current().identifierForVendor!.uuidString
            let encoder = JSONEncoder()
            let requestData = try encoder.encode(
                RequestData(
                    sessionUuid: sessionUuid,
                    deviceUuid: deviceUuid,
                    payload: payload,
                    startTimeEpoch: Int(session.startTime.timeIntervalSince1970),
                    endTimeEpoch: Int(session.endTime!.timeIntervalSince1970)
                )
            )
            var request = URLRequest(url: url)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"

            var response: HTTPURLResponse? = nil
            if Platform.isSimulator {
                let (_, _response) = try await URLSession.shared.upload(for: request, from: requestData)
                response = _response as? HTTPURLResponse
            }
            else {
                request.httpBody = requestData
                let (_, _response) = try await URLSession.shared.data(for: request)
                response = _response as? HTTPURLResponse
            }

            if response != nil && response?.statusCode != nil && response?.statusCode != 200 {
                return false
            }

            return true
        }
    }
    catch {}

    return false
}
