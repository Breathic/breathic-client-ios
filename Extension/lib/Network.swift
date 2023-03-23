import WatchKit
import WatchConnectivity

func uploadSession(_ session: Session) async -> Bool {
    do {
        struct RequestData: Encodable {
            let sessionUuid: String
            let deviceUuid: String
            let session: String
            let payload: String
        }

        if WKInterfaceDevice.current().identifierForVendor != nil {
            let timeseriesData: ReadingContainer = getTimeseriesData(
                uuid: session.uuid,
                timeUnit: TimeUnit.Second
            )
            let payload: String = buildSessionPayload(timeseriesData: timeseriesData)
            let url = URL(string: API_URL + "/session")!
            let sessionUuid = session.uuid;
            let deviceUuid = WKInterfaceDevice.current().identifierForVendor!.uuidString
            let sessionData = String(data: try JSONEncoder().encode(session), encoding: String.Encoding.utf8)!

            let requestData = try JSONEncoder().encode(
                RequestData(
                    sessionUuid: sessionUuid,
                    deviceUuid: deviceUuid,
                    session: sessionData,
                    payload: payload
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

            if response != nil && response?.statusCode != nil && (
                response?.statusCode == 200 ||
                response?.statusCode == 409
            ) {
                return true
            }

            return false
        }
    }
    catch {}

    return false
}
