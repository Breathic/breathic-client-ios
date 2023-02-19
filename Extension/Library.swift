import Foundation
import SwiftUI

func convertRange(value: Float, oldRange: [Float], newRange: [Float]) -> Float {
   return ((value - oldRange[0]) * (newRange[1] - newRange[0])) / (oldRange[1] - oldRange[0]) + newRange[0]
}

func parsePickerRange(range: [Float]) -> [Float] {
    return Array(Int(range[0] * 10)...Int(range[1] * 10))
        .map { Float($0) / 10 }
}

func colorize(_ color: String) -> Color {
    return Color(red: COLORS[color]!.0 / 255, green: COLORS[color]!.1 / 255, blue: COLORS[color]!.2 / 255)
}

func getRhythms(_ store: Store) -> [Float] {
    return store.state.preset.breathingTypes.map { $0.rhythm }
}

func incrementPreset(_ store: Store) {
    store.state.session.presetIndex = store.state.session.presetIndex + 1 == store.state.activity.presets.count
        ? 0
        : store.state.session.presetIndex + 1
    store.state.preset = store.state.activity.presets[store.state.session.presetIndex]
}

func getMetric(_ metric: String) -> MetricType {
    return METRIC_TYPES[metric] != nil
        ? METRIC_TYPES[metric]!
        : MetricType()
}

func getElapsedTime(from: Date, to: Date) -> String {
    let difference = Calendar.current.dateComponents([.hour, .minute, .second], from: from, to: to)
    var elapsedTime = "00:00"

    if difference.second! > 0 || difference.minute! > 0 || difference.hour! > 0 {
        elapsedTime = String(format: "%02ld:%02ld", difference.minute!, difference.second!)

        if difference.hour! > 0 {
            elapsedTime = String(format: "%01ld:%02ld:%02ld", difference.hour!, difference.minute!, difference.second!)
        }
    }

    return elapsedTime
}

func getMonthLabel(index: Int) -> String {
    let monthChars = Array(DateFormatter().monthSymbols[index].capitalized)
    return String(monthChars[0..<3])
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
    var saves = 1

    for session in sessions.reversed() {
        var id = generateSessionId(session: session)
        let isDuplicate = prevId == id

        prevId = id
        saves = isDuplicate
            ? saves + 1
            : 1

        // Display the latest session for each minute.
        if saves == 1 {
            let elapsedTime = getElapsedTime(from: session.startTime, to: session.endTime)
            id = id + " (" + elapsedTime + ")"
            result.append(id)
        }
    }

    return result.reversed()
}

func getTimeseriesUpdateId(uuid: String, date: Date) -> String {
    return "Timeseries-" +
        uuid + "-" +
        String(Calendar.current.component(.day, from: date)) + "-" +
        String(Calendar.current.component(.hour, from: date)) + "-" +
        String(Calendar.current.component(.minute, from: date))
}

func parseProgressData(timeseries: [Reading], startTime: Date) -> [ProgressData] {
    let startHour = Calendar.current.component(.hour, from: startTime)
    let startMinute = Calendar.current.component(.minute, from: startTime)
    var dataByMinuteAveraged: [Int: Float] = [:]

    timeseries
        .forEach {
            let hours = Calendar.current.component(.hour, from: $0.timestamp)
            let minutes = Calendar.current.component(.minute, from: $0.timestamp)
            let timestampByMinute = (Int((hours - startHour) * 60 + (minutes - startMinute)))

            dataByMinuteAveraged[timestampByMinute] = $0.value
        }

    return dataByMinuteAveraged.keys.sorted().map {
        ProgressData(timestamp: $0, value: dataByMinuteAveraged[$0]!)
    }
}

func getFadeScale() -> [Float] {
    var result: [Float] = []
    let fadeMax = FADE_DURATION - 1
    let middleMax = CHANNEL_REPEAT_COUNT - FADE_DURATION * 2 - 1

    Array(0...fadeMax).forEach {
        result.append(
            convertRange(
                value: Float($0),
                oldRange: [0, Float(fadeMax)],
                newRange: [0, 1]
            )
        )
    }
    let endFade: [Float] = result.reversed()

    for _ in Array(0...middleMax) {
        result.append(1)
    }

    for volume in endFade {
        result.append(volume)
    }

    return result
}

func getPanScale() -> [Float] {
    let easingCount: Int = 8
    var easing: Float = 0
    var left: [Float] = []
    var right: [Float] = []

    for (index, _) in Array(1...easingCount).enumerated() {
        easing = Float(index) * 1 / (Float(easingCount) - 1) * 2
        left.append(0 - (1 - easing))
        right.append(easing)
    }

    return left + right
}

func getAverages(timeseries: [String: [Reading]]) -> [String: [Reading]] {
    var result: [String: [Reading]] = [:]

    timeseries.keys.forEach {
        let timeserie = Reading()
        let values = (timeseries[$0] ?? [])

        if values.count > 0 {
            timeserie.value = values
                .map { $0.value }
                .reduce(0, +) / Float(values.count)
            timeserie.timestamp = values[0].timestamp
            result.append(element: timeserie, toValueOfKey: $0)
        }
    }

    return result
}

func saveSessionLogs(sessionLogs: [Session]) {
    guard let data = try? JSONEncoder().encode(sessionLogs) else { return }
    writeToFile(key: STORE_SESSION_LOGS, data: data)
}
