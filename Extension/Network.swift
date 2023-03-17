import WatchKit
import WatchConnectivity

func uploadSession(session: Session) {
    struct RequestData: Encodable {
        let sessionUuid: String
        let deviceUuid: String
        let payload: String
        let startTimeEpoch: Int
        let endTimeEpoch: Int
    }

    if WKInterfaceDevice.current().identifierForVendor != nil {
        Task {
            let timeseriesData: ReadingContainer = getTimeseriesData(
                uuid: session.uuid,
                startTime: session.startTime,
                endTime: session.endTime,
                average: false
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
                    endTimeEpoch: Int(session.endTime.timeIntervalSince1970)
                )
            )

            var request = URLRequest(url: url)

            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpMethod = "POST"

            if Platform.isSimulator {
                uploadSimulator(request: request, requestData: requestData)
            }
            else {
                request.httpBody = requestData
                uploadDevice(request: request)
            }
        }
    }
}

func uploadSimulator(request: URLRequest, requestData: Data) {
    Task {
        let (data, response) = try await URLSession.shared.upload(for: request, from: requestData)
        print(data, response)
    }
}

func uploadDevice(request: URLRequest) {
    let task = URLSession.shared.dataTask(
        with: request,
        completionHandler: { data, response, error in
            print(
                data ?? "",
                response ?? "",
                error ?? ""
            )
        }
    )

    task.resume()
}
