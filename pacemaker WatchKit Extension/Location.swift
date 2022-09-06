import Foundation
import CoreLocation
import SwiftUI

class Location: NSObject, ObservableObject, CLLocationManagerDelegate {
    @ObservedObject private var store: AppStore = .shared
    
    let locationManager = CLLocationManager()
    var last: CLLocation?
    var speeds: [Double] = []
    
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
        locationManager.delegate = self
        requestAuthorisation()
        
        Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            self.locationManager.requestLocation()
        }
    }
    
    func process(current: CLLocation) {
        guard last != nil else {
            last = current
            return
        }
        
        if (current.speed >= 0) {
            let minValue = 0.1
            
            speeds.append(current.speed)
            speeds = Array(speeds.suffix(MAX_INTERVALS))
            store.state.averageMetersPerSecond = speeds.reduce(0) { $0 + $1 } / Double(speeds.count)
            
            if store.state.averageMetersPerSecond < minValue {
                store.state.averageMetersPerSecond = minValue
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
