import Foundation

func trimReadings(readings: [Reading], value: Float) -> [Reading] {
    var result = readings
    let reading = Reading()

    reading.timestamp = Date()
    reading.value = value
    result.append(reading)

    result = Array(result.suffix(MAX_READING_COUNT))
    result = result.filter { reading in
        reading.timestamp.distance(to: Date()) <= MAX_READING_TIMEOUT_S
    }

    return result
}

func getAverageValue(_ readings: [Reading]) -> Float {
    return readings.reduce(0) { Float($0) + Float($1.value) } / Float(readings.count)
}

func getIntervalDerivedValue(_ readings: [Reading]) -> Float {
    let intervalDuration = readings[0].timestamp.distance(to: readings[readings.count - 1].timestamp)
    let intervalSteps = readings[readings.count - 1].value - readings[0].value
    return Float(intervalDuration) / intervalSteps
}

func getLastValue(_ readings: [Reading]) -> Float {
    return readings[readings.count - 1].value
}

func canUpdate(_ value: Float) -> Bool {
    return !value.isInfinite && !value.isNaN
}

func parseMetric(metric: String, readings: [Reading]) -> Float {
    switch metric {
        case "heart": return getAverageValue(readings)
        case "step": return getIntervalDerivedValue(readings) * 60
        case "speed": return getAverageValue(readings) * 3.6
        case "altitude": return getLastValue(readings)
        case "longitude": return getLastValue(readings)
        case "latitude": return getLastValue(readings)
        case "distance": return getLastValue(readings)
        default: fatalError("metric is undefined")
    }
}

func updateMetric(
    store: Store,
    metric: String,
    metricValue: Float,
    readings: [Reading]
) -> [Reading] {
    if !store.state.activeSession.isActive {
        store.state.setMetricValuesToDefault()
        return []
    }

    let result = trimReadings(readings: readings, value: metricValue)
    let prevValue = store.state.getMetricValue(metric)
    let value = parseMetric(metric: metric, readings: result)

    if canUpdate(value) && value != prevValue {
        store.state.setMetricValue(metric, value)
    }

    return result
}
