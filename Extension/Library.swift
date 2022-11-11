import Foundation
import SwiftUI

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

func readDistances(path: String) -> [Int: [Distance]] {
    var res: [Int: [Distance]] = [:]
    let forResource = String(path.split(separator: ".")[0])
    let ofType = String(path.split(separator: ".")[1])
    
    if let path = Bundle.main.path(forResource: forResource, ofType: ofType) {
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
            let jsonResult = try JSONSerialization.jsonObject(with: data, options: .mutableLeaves)

            if let jsonResult = jsonResult as? Dictionary<String, [AnyObject]> {
                for comparisons in jsonResult {
                    let leftId = Int(comparisons.key)!
                    let values: [AnyObject] = comparisons.value
                    var distances = [Distance]()
                    
                    for value in values {
                        let distance = Distance()
                        
                        distance.value = value[0] as! Double
                        distance.duration = value[1] as! Double
                        distance.rightId = value[2] as! Int
                        distances.append(distance)
                    }
                    
                    res[leftId] = distances
                }
            }
        } catch {}
    }
    return res
}

func convertRange(value: Float, oldRange: [Float], newRange: [Float]) -> Float {
   return ((value - oldRange[0]) * (newRange[1] - newRange[0])) / (oldRange[1] - oldRange[0]) + newRange[0]
}

func colorize(_ color: String) -> Color {
    return Color(red: COLORS[color]!.0 / 255, green: COLORS[color]!.1 / 255, blue: COLORS[color]!.2 / 255)
}

func getElapsedTime(from: Date, to: Date) -> String {
    let difference = Calendar.current.dateComponents([.hour, .minute, .second], from: from, to: to)
    var elapsedTime = ""

    if difference.second! > 0 {
        elapsedTime = String(format: "%02ld:%02ld", difference.minute!, difference.second!)

        if difference.hour! > 0 {
            elapsedTime = String(format: "%01ld:%02ld:%02ld", difference.hour!, difference.minute!, difference.second!)
        }
    }

    return elapsedTime
}

func writeToFile(key: String, data: Data) {
    do {
        let json = String(data: data, encoding: .utf8) ?? ""
        let filename = getDocumentsDirectory().appendingPathComponent(key)
        try json.write(to: filename, atomically: true, encoding: .utf8)
    }
    catch {
        print("writeToFile()", error)
    }
}

func readFromFile(key: String) -> Data {
    do {
        let filename = getDocumentsDirectory().appendingPathComponent(key)
        let outData = try String(contentsOf: filename, encoding: .utf8)
        return outData.data(using: .utf8) ?? Data()
    }
    catch {
        return Data()
    }
}

func getMonthLabel(index: Int) -> String {
    return MONTH_LABELS[index]
}

func generateSessionId(session: Session) -> String {
    return getMonthLabel(index: Calendar.current.component(.month, from: session.startTime) - 1) + " " +
        String(Calendar.current.component(.day, from: session.startTime)) + " " +
        String(session.startTime.formatted(.dateTime.hour().minute()))
        .components(separatedBy: " ")[0]
}

func getSessionIds(sessions: [Session]) -> [String] {
    var result: [String] = []
    var prevId = ""
    var repeats = 1

    for session in sessions {
        var id = generateSessionId(session: session)
        let isDuplicate = prevId == id

        prevId = id
        repeats = isDuplicate
            ? repeats + 1
            : 1

        // Hide duration since there isn't always enough space to go around.
        if repeats > 1 {
            id = id + " - " + String(repeats)

            // And strip duration from the previous one.
            result[result.count - 1] = result[result.count - 1].components(separatedBy: " (")[0]
        }
        else {
            id = id + " (" + getElapsedTime(from: session.startTime, to: session.endTime) + ")"
        }

        result.append(id)
    }

    return result
}

func getTimeseriesUpdateId(uuid: String, date: Date) -> String {
    return "Timeseries-" +
        uuid + "-" +
        String(Calendar.current.component(.day, from: date)) + "-" +
        String(Calendar.current.component(.hour, from: date)) + "-" +
        String(Calendar.current.component(.minute, from: date))
}

func parseProgressData(metricData: [Timeserie], startTime: Date) -> [ProgressData] {
    let startHour = Calendar.current.component(.hour, from: startTime)
    let startMinute = Calendar.current.component(.minute, from: startTime)
    var dataByMinute: [Int: [Float]] = [:]
    var dataByMinuteAveraged: [Int: Float] = [:]

    metricData
        .forEach {
            let hours = Calendar.current.component(.hour, from: $0.timestamp)
            let minutes = Calendar.current.component(.minute, from: $0.timestamp)
            let timestampByMinute = (Int((hours - startHour) * 60 + (minutes - startMinute)))
            dataByMinute.append(element: $0.value, toValueOfKey: timestampByMinute)
        }

    for timestamp in dataByMinute.keys {
        let values = dataByMinute[timestamp] ?? []
        dataByMinuteAveraged[timestamp] = values.reduce(0, +) / Float(values.count)
    }

    return dataByMinuteAveraged.keys.sorted().map {
        ProgressData(timestamp: $0, value: dataByMinuteAveraged[$0]!)
    }
}

func getAverageMetricValue(
    timeseries: [String: [Timeserie]],
    metric: String
) -> String {
    let metrics = (timeseries[metric] ?? [])
    let average = metrics
        .map { $0.value }
        .reduce(0, +) / Float(metrics.count)

    return String(metrics.count > 0 ? String(format: "%.0f", average) : "")
}

func getSeriesData(
    timeseries: [String: [Timeserie]],
    startTime: Date
) -> ([SeriesData], ChartDomain) {
    let chartXAxisRightSpacingPct: Float = 8
    var _timeseries: [String: [ProgressData]] = [:]
    let chartDomain = ChartDomain()

    timeseries.keys.forEach {
        let progressData = parseProgressData(metricData: timeseries[$0] ?? [], startTime: startTime)

        _timeseries[$0] = progressData

        if progressData.count > 0 {
            chartDomain.xMin = Float(progressData[0].timestamp)
            chartDomain.xMax = Float(progressData[progressData.count - 1].timestamp) + Float(progressData[progressData.count - 1].timestamp) * chartXAxisRightSpacingPct / 100
        }

        let value: Float = progressData
            .map { Float($0.value) }.max() ?? Float(0)

        if value > chartDomain.yMax {
            chartDomain.yMax = value
        }
    }

    let result: [SeriesData] = _timeseries.keys.map {
        let avgValue = getAverageMetricValue(timeseries: timeseries, metric: $0)
        let progressData: [ProgressData] = _timeseries[$0] ?? []

        return .init(metric: avgValue + " " + $0 + " avg", data: progressData)
    }

    return (result, chartDomain)
}

func updateReadings(readings: [Reading], value: Float) -> [Reading] {
    var result = readings
    let reading = Reading()

    reading.time = .now()
    reading.value = value
    result.append(reading)

    result = Array(result.suffix(MAX_READING_COUNT))
    result = result.filter { reading in
        reading.time + MAX_READING_TIMEOUT_S >= .now()
    }

    return result
}

func getAverageValue(readings: [Reading]) -> Float {
    return readings.reduce(0) { Float($0) + Float($1.value) } / Float(readings.count)
}

func getIntervalDerivedValue(readings: [Reading]) -> Float {
    let intervalDuration: DispatchTimeInterval = readings[0].time.distance(to: readings[readings.count - 1].time)
    let intervalSteps = Double(readings[readings.count - 1].value - readings[0].value)
    return Float(intervalDuration.toDouble()) / Float(intervalSteps)
}

func canUpdate(_ value: Float) -> Bool {
    return value >= 0 && !value.isInfinite && !value.isNaN
}

func getAverageByMetric(metric: String, readings: [Reading]) -> Float {
    switch metric {
        case "heart": return getAverageValue(readings: readings)
        case "step": return getIntervalDerivedValue(readings: readings) * 60
        case "speed": return getAverageValue(readings: readings) * 3.6
        default: fatalError("metric is undefined")
    }
}

func updateMetric(store: Store, metric: String, metricValue: Float, readings: [Reading]) -> [Reading] {
    let _readings = updateReadings(readings: readings, value: metricValue)
    let prevValue = store.state.getMetricValue(metric)
    var value = getAverageByMetric(metric: metric, readings: _readings)

    if canUpdate(value) {
        if value != prevValue {
            store.state.lastDataChangeTime = .now()
        }
    }
    else {
        value = 0
    }

    store.state.setMetricValue(metric, value)
    return _readings
}
