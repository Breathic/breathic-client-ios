import Foundation

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
