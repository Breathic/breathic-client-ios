import WatchKit
import WatchConnectivity

func uploadSession(
    session: Session,
    deviceToken: String
) async throws -> Bool {
    do {
        struct RequestData: Encodable {
            let deviceToken: String
            let sessionUuid: String
            let deviceUuid: String
            let session: String
            let readings: String
            let overview: String
        }

        if WKInterfaceDevice.current().identifierForVendor != nil {
            session.startTimeUtc = session.startTime.formatted(.iso8601)
                .replacingOccurrences(of: "Z", with: ".000Z")
            session.endTimeUtc = session.endTime?.formatted(.iso8601)
                ?? Date().formatted(.iso8601)
                    .replacingOccurrences(of: "Z", with: ".000Z")
            let timeseriesData: ReadingContainer = getTimeseriesData(
                uuid: session.uuid,
                timeUnit: TimeUnit.Second
            )
            let readings: String = buildSessionPayload(timeseriesData: timeseriesData)
            let url = URL(string: API_URL + "/session")!
            let sessionUuid = session.uuid;
            let deviceUuid = WKInterfaceDevice.current().identifierForVendor!.uuidString
            let sessionData = String(data: try JSONEncoder().encode(session), encoding: String.Encoding.utf8)!
            
            var overview: Overview = [:]
            let overviewMetrics = getOverviewMetrics(timeseries: timeseriesData)
            DEFAULT_DISPLAY_METRICS
                .filter { overviewMetrics[$0] != nil }
                .forEach {
                    overview[$0] = Float(String(format: getMetric($0).format, overviewMetrics[$0]!))
                }
            let overviewData = String(data: try JSONEncoder().encode(overview), encoding: String.Encoding.utf8)!

            let requestData = try JSONEncoder().encode(
                RequestData(
                    deviceToken: deviceToken,
                    sessionUuid: sessionUuid,
                    deviceUuid: deviceUuid,
                    session: sessionData,
                    readings: readings,
                    overview: overviewData
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
    catch {
        throw(error)
    }

    return false
}

func detectAPIAvailability() async throws -> Bool {
    do {
        let url = URL(string: GUIDE_URL)

        var response: HTTPURLResponse? = nil
        let (_, _response) = try await URLSession.shared.download(from: url!)
        response = _response as? HTTPURLResponse

        if response != nil && response?.statusCode != nil && (
            response?.statusCode == 200) {
            return true
        }

        return false

    }
    catch {
        return false
    }
}
