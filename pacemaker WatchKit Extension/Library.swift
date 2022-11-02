import Foundation
import SwiftUI

let filestore = NSUbiquitousKeyValueStore()

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

func colorize(color: String) -> Color {
    switch color {
        case "red": return Color(red: 242 / 255, green: 16 / 255, blue: 75 / 255)
        case "green":  return Color(red: 161 / 255, green: 249 / 255, blue: 2 / 255)
        case "blue": return Color(red: 3 / 255, green: 221 / 255, blue: 238 / 255)
        case "gray": return Color(red: 63 / 255, green: 63 / 255, blue: 63 / 255)
        default: return Color.white
    }
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

func readSessionLogs() -> [Session] {
    do {
        let outData = filestore.string(forKey: "SessionLogs") ?? ""
        let jsonData = outData.data(using: .utf8)!
        return try JSONDecoder().decode([Session].self, from: jsonData)
    }
    catch {
        return []
    }
}

func writeSessionLogs(sessionLogs: [Session]) {
    let data = try! JSONEncoder().encode(sessionLogs)
    let json = String(data: data, encoding: .utf8) ?? ""
    filestore.set(json, forKey: "SessionLogs")
    filestore.synchronize()
}

func readActiveSession() -> Session {
    do {
        let outData = filestore.string(forKey: "ActiveSession") ?? ""
        let jsonData = outData.data(using: .utf8)!
        let session = try JSONDecoder().decode(Session.self, from: jsonData)
        return session
    }
    catch {
        return Session()
    }
}

func writeActiveSession(session: Session) {
    let data = try! JSONEncoder().encode(session)
    let json = String(data: data, encoding: .utf8) ?? ""
    filestore.set(json, forKey: "ActiveSession")
    filestore.synchronize()
}

func writeTimeseries(key: String, timeseries: [String: [Timeserie]]) {
    do {
        let data = try! JSONEncoder().encode(timeseries)
        let json = String(data: data, encoding: .utf8) ?? ""
        let filename = getDocumentsDirectory().appendingPathComponent(key)
        try json.write(to: filename, atomically: true, encoding: .utf8)
    }
    catch {
        print("writeTimeseries()", error)
    }
}

func readTimeseries(key: String) -> [String: [Timeserie]] {
    do {
        let filename = getDocumentsDirectory().appendingPathComponent(key)
        let outData = try String(contentsOf: filename, encoding: .utf8)
        let jsonData = outData.data(using: .utf8)!
        let session = try JSONDecoder().decode([String: [Timeserie]].self, from: jsonData)
        return session
    }
    catch {
        return [:]
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

        if repeats > 1 {
            id = id + " - " + String(repeats)
        }

        id = id + " (" + getElapsedTime(from: session.startTime, to: session.endTime) + ")"

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
