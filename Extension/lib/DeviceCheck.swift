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
        return SIMULATOR_DEVICE_TOKEN
    }

    return ""
}
