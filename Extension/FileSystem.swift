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

func createFolderIfNotExists(url: URL) {
    let manager = FileManager.default

    do {
        if !manager.fileExists(atPath: url.relativePath) {
            try manager.createDirectory(
                at: url,
                withIntermediateDirectories: false,
                attributes: nil
            )
        }
    }
    catch {
        print("createFolderIfNotExists()", error)
    }
}

func writeToFile(url: URL, data: Data) {
    do {
        let json = String(data: data, encoding: .utf8) ?? ""
        try json.write(to: url, atomically: true, encoding: .utf8)
    }
    catch {
        print("writeToFile()", error)
    }
}

func readFromFile(url: URL) -> Data {
    do {
        let outData = try String(contentsOf: url, encoding: .utf8)
        let data = outData.data(using: .utf8)!
        return data
    }
    catch {
        return Data()
    }
}

func readFromFolder(_ folder: String) -> [String] {
    var result: [String] = []
    let documentDirectoryPath: String = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
    let myFilesPath = "\(documentDirectoryPath)/" + folder
    let files = FileManager.default.enumerator(atPath: myFilesPath)

    while let file = files?.nextObject() as? String {
        result.append(String(file))
    }

    return result
}
