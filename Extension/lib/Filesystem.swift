import Foundation

func getDocumentsDirectory() -> URL {
    let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
    return paths[0]
}

func readDistances(_ path: String) -> Distances {
    var res: Distances = [:]

    if let path = Bundle.main.path(forResource: path, ofType: nil) {
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

                        distance.rightId = Int(value[0] as! String)!
                        distance.value = value[1] as! Double

                        distances.append(distance)
                    }

                    res[leftId] = distances
                }
            }
        } catch {}
    }
    
    return res
}

func listAllFiles(_ path: String) -> [String] {
    do {
        if let path = Bundle.main.path(forResource: path, ofType: nil) {
            let folders = try FileManager.default.contentsOfDirectory(
                at: URL(fileURLWithPath: path),
                includingPropertiesForKeys: nil
            )
                .filter { !$0.hasDirectoryPath }
                .map { $0.absoluteString }
            return folders
        }
    } catch {
        print("listAllFiles()", error)
    }

    return []
}

func listAllFolders(_ path: String) -> [String] {
    do {
        if let path = Bundle.main.path(forResource: path, ofType: nil) {
            let folders = try FileManager.default.contentsOfDirectory(
                at: URL(fileURLWithPath: path),
                includingPropertiesForKeys: nil
            )
                .filter { $0.hasDirectoryPath }
                .map { $0.absoluteString }
            return folders
        }
    } catch {
        print("listAllFolders()", error)
    }

    return []
}

func listInstruments(_ path: String) -> Instruments {
    var res: Instruments = [:]

    listAllFiles(path).forEach {
        let pathSeparator = "/"
        let instrumentKey = String(
            $0
                .split(separator: pathSeparator)[
                    $0.split(separator: pathSeparator).count - 1
                ]
                .split(separator: ".")[0]
        )
        res[instrumentKey] = readDistances(path + pathSeparator + instrumentKey + ".json")
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
    let path = "\(documentDirectoryPath)/" + folder
    
    do {
        let files = try FileManager.default.contentsOfDirectory(atPath: path)
        
        for file in files {
            result.append(String(file))
        }
    } catch {
        print("readFromFolder()", error)
    }
    
    return result
}

func deleteFileOrFolder(url: URL) {
    let manager = FileManager.default

    if manager.fileExists(atPath: url.path) {
        do {
            try manager.removeItem(atPath: url.path)
        } catch {
            print("deleteFile(): Could not delete file, probably read-only filesystem")
        }
    }
}
