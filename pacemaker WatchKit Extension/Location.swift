import Foundation
import CoreLocation
import SwiftUI

class Location: NSObject, ObservableObject, CLLocationManagerDelegate {
    @ObservedObject private var store: AppStore = .shared
    
    let locationManager = CLLocationManager()
    var last: CLLocation?
    var speeds: [Double] = []
    var timer: Timer?
    
    override init() {
        super.init()
        
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
    }
    
    var isLocationAvailable: Bool {
        get {
            switch locationManager.authorizationStatus {
                case .authorizedAlways:
                    return true
                case .authorizedWhenInUse:
                    return true
                case .denied:
                    return false
                case .notDetermined:
                    return false
                case .restricted:
                    return false
                @unknown default:
                    return false
                }
        }
    }
    
    public func requestAuthorisation(always: Bool = false) {
        if always {
            self.locationManager.requestAlwaysAuthorization()
        } else {
            self.locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func start() {
        stop()
        locationManager.delegate = self
        requestAuthorisation()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.locationManager.requestLocation()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func process(current: CLLocation) {
        guard last != nil else {
            last = current
            return
        }

        if current.speed >= 0 {
            let prevSpeed = store.state.speed

            speeds.append(current.speed)
            speeds = Array(speeds.suffix(MAX_READING_COUNT))

            let res = speeds.reduce(0) { Float($0) + Float($1) } / Float(speeds.count) * 3.6
            if res >= 0 && !res.isInfinite && !res.isNaN {
                store.state.speed = res

                if store.state.speed != prevSpeed {
                    store.state.lastDataChangeTime = .now()
                }
            }
        }

        last = current
    }
}

extension Location {
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
         print("error: \(error.localizedDescription)")
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if !isLocationAvailable {
            locationManager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        for location in locations {
            DispatchQueue.main.async {
                self.process(current: location)
            }
        }
    }
}
