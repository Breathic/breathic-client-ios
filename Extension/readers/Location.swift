import Foundation
import CoreLocation
import SwiftUI

class Location: NSObject, ObservableObject, CLLocationManagerDelegate {
    @ObservedObject private var store: Store = .shared

    let locationManager = CLLocationManager()
    var last: CLLocation?
    var timer: Timer?
    var readings: [String: [Reading]] = [:]
    var startLocation: CLLocation!
    var lastLocation: CLLocation!
    var traveledDistance: Float = 0

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
        readings = [:]
        self.traveledDistance = 0
    }

    func process(metric: String, value: Float) {
        if readings[metric] == nil {
            readings[metric] = []
        }

        readings[metric] = updateMetric(
            store: store,
            metric: metric,
            metricValue: value,
            readings: readings[metric]!
        )
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
                if location.speedAccuracy >= 0 {
                    self.process(metric: "speed", value: Float(location.speed))
                }

                if location.verticalAccuracy > 0 {
                    self.process(metric: "altitude", value: Float(location.altitude))
                }

                self.process(metric: "longitude", value: Float(location.coordinate.longitude))
                self.process(metric: "latitude", value: Float(location.coordinate.latitude))

                if self.startLocation == nil {
                    self.startLocation = locations.first
                }
                else {
                    let lastLocation = locations.last!
                    let distance = self.startLocation.distance(from: lastLocation)
                    self.startLocation = lastLocation
                    self.traveledDistance = self.traveledDistance + Float(distance)
                }

                self.process(metric: "distance", value: self.traveledDistance)
            }
        }
    }
}
