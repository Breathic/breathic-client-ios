import Foundation

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
