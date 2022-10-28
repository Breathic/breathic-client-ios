import Foundation
import SwiftUI

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
        default: return Color.white
    }
}

func getElapsedTime(from: Date, to: Date) -> String {
    let difference = Calendar.current.dateComponents([.hour, .minute, .second], from: from, to: to)
    let elapsedTime = String(format: "%02ld:%02ld:%02ld", difference.hour!, difference.minute!, difference.second!)
    return elapsedTime
}

func readSessionLogs() -> [Session] {
    do {
        let outData = UserDefaults.standard.string(forKey: "SessionLogs") ?? ""
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
    UserDefaults.standard.set(json, forKey: "SessionLogs")
}

func getMonthLabel(index: Int) -> String {
    let months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
    return months[index]
}

func generateSessionId(session: Session) -> String {
    return getMonthLabel(index: Calendar.current.component(.month, from: session.startTime) - 1) + " " +
        String(Calendar.current.component(.day, from: session.startTime)) + " - " +
        String(session.startTime.formatted(.dateTime.hour().minute()))
        .components(separatedBy: " ")[0]
}

func getSessionIds(sessions: [Session]) -> [String] {
    sessions.map { $0.id }
}
