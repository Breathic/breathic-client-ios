import Foundation
import CoreMotion
import SwiftUI

class Motion: NSObject, ObservableObject {
    @ObservedObject private var store: Store = .shared

    var manager: CMMotionManager?
    var timer: Timer?
    var accelerationXReadings: [Reading] = []
    var accelerationYReadings: [Reading] = []
    var accelerationZReadings: [Reading] = []
    var rotationXReadings: [Reading] = []
    var rotationYReadings: [Reading] = []
    var rotationZReadings: [Reading] = []

    override init() {
        super.init()
        self.manager = CMMotionManager()
    }
    
    func requestMotion() {
        if let data = manager?.accelerometerData {
            accelerationXReadings = updateMetric(
                store: store,
                metric: "acceleration-x",
                metricValue: Float(data.acceleration.x),
                readings: accelerationXReadings
            )
            accelerationYReadings = updateMetric(
                store: store,
                metric: "acceleration-y",
                metricValue: Float(data.acceleration.y),
                readings: accelerationYReadings
            )
            accelerationZReadings = updateMetric(
                store: store,
                metric: "acceleration-z",
                metricValue: Float(data.acceleration.z),
                readings: accelerationZReadings
            )
        }

        if let data = manager?.deviceMotion {
            rotationXReadings = updateMetric(
                store: store,
                metric: "rotation-x",
                metricValue: Float(data.rotationRate.x),
                readings: rotationXReadings
            )
            rotationYReadings = updateMetric(
                store: store,
                metric: "rotation-y",
                metricValue: Float(data.rotationRate.y),
                readings: rotationYReadings
            )
            rotationZReadings = updateMetric(
                store: store,
                metric: "rotation-z",
                metricValue: Float(data.rotationRate.z),
                readings: rotationZReadings
            )
        }
    }
    
    func start() {
        stop()
        
        if manager!.isAccelerometerAvailable {
            manager?.startAccelerometerUpdates()
        }
        
        if manager!.isDeviceMotionAvailable {
            manager?.startDeviceMotionUpdates()
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1 / MOTION_UPDATE_FREQUENCY, repeats: true) { timer in
            self.requestMotion()
        }
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
        
        if manager!.isAccelerometerAvailable {
            manager?.stopAccelerometerUpdates()
        }
        
        if manager!.isDeviceMotionAvailable {
            manager?.stopDeviceMotionUpdates()
        }
        
        accelerationXReadings = []
        accelerationYReadings = []
        accelerationZReadings = []
        rotationXReadings = []
        rotationYReadings = []
        rotationZReadings = []
    }
}
