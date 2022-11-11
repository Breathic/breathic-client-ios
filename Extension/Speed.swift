import Foundation
import CoreLocation
import SwiftUI

class Speed: NSObject, ObservableObject, CLLocationManagerDelegate {
    @ObservedObject private var store: Store = .shared

    let locationManager = CLLocationManager()
    var last: CLLocation?
    var timer: Timer?
    var readings: [Reading] = []
    let metric: String = "speed"

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
        readings = []
    }

    func process(current: CLLocation) {
        guard last != nil else {
            last = current
            return
        }

        let metricValue: Float = Float(current.speed)
        readings = updateMetric(store: store, metric: metric, metricValue: metricValue, readings: readings)
        last = current
    }
}

extension Speed {
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
