import DeviceCheck

func generateToken() async -> String {
    let currentDevice = DCDevice.current

    if currentDevice.isSupported {
        do {
            let tokenData = try await currentDevice.generateToken();
            return tokenData.base64EncodedString()
        }
        catch {
            print("generateToken()", error)
        }
    }

    if Platform.isSimulator {
        if let path = Bundle.main.path(
            forResource: String(SIMULATOR_DEVICE_TOKEN.split(separator: ".")[0]),
            ofType: String(SIMULATOR_DEVICE_TOKEN.split(separator: ".")[1])
        ) {
            do {
                let data = try String(contentsOfFile: path, encoding: .utf8)
                return data
            }
            catch {
                print("generateToken()", error)
            }
        }
    }

    return ""
}
