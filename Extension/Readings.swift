import Foundation

func updateReadings(readings: [Reading], value: Float) -> [Reading] {
    var result = readings
    let reading = Reading()

    reading.timestamp = Date()
    reading.value = value
    result.append(reading)

    result = Array(result.suffix(MAX_READING_COUNT))
    result = result.filter { reading in
        reading.timestamp.timeIntervalSince1970 + MAX_READING_TIMEOUT_S >= Date().timeIntervalSince1970
    }

    return result
}

func getAverageValue(readings: [Reading]) -> Float {
    return readings.reduce(0) { Float($0) + Float($1.value) } / Float(readings.count)
}

func getIntervalDerivedValue(readings: [Reading]) -> Float {
    let intervalDuration = readings[0].timestamp.timeIntervalSince1970 - readings[readings.count - 1].timestamp.timeIntervalSince1970
    let intervalSteps = Double(readings[readings.count - 1].value - readings[0].value)
    return Float(intervalDuration) / Float(intervalSteps)
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
    if !store.state.session.isActive {
        store.state.timeseries.keys.forEach {
            store.state.setMetricValue($0, nil)
        }
        return []
    }

    let result = updateReadings(readings: readings, value: metricValue)
    let prevValue = store.state.getMetricValue(metric)
    let value = getAverageByMetric(metric: metric, readings: result)

    if canUpdate(value) && value != prevValue {
        store.state.setMetricValue(metric, value)
        store.state.lastDataChangeTime = .now()
    }

    return result
}
