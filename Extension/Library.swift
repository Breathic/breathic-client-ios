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

func writeToKeyValueStore(key: String, data: Data) {
    let json = String(data: data, encoding: .utf8) ?? ""
    filestore.set(json, forKey: key)
    filestore.synchronize()
}

func readFromKeyValueStore(key: String) -> Data {
    let outData = filestore.string(forKey: key) ?? ""
    return outData.data(using: .utf8)!
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
    return sessions.map {
        return generateSessionId(session: $0) + " (" + getElapsedTime(from: $0.startTime, to: $0.endTime) + ")"
    }
}

func getTimeseriesUpdateId(uuid: String, date: Date) -> String {
    return "Timeseries-" +
        uuid + "-" +
        String(Calendar.current.component(.day, from: date)) + "-" +
        String(Calendar.current.component(.hour, from: date)) + "-" +
        String(Calendar.current.component(.minute, from: date))
}
