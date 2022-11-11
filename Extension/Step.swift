import Foundation
import SwiftUI
import CoreMotion

class Step {
    @StateObject private var store: Store = .shared

    var pedometer = CMPedometer()
    var readings = [Reading]()
    let metric: String = "step"

    var isStepCountingAvailable: Bool {
        get {
            return CMPedometer.isStepCountingAvailable()
        }
    }

    func stop() {
        pedometer.stopUpdates()
        readings = []
    }

    func start() {
        if self.isStepCountingAvailable {
            stop()

            pedometer.startUpdates(from: Date(), withHandler: { (data, error) in
                if data != nil {
                    DispatchQueue.main.async {
                        self.setPedometerData(data: data!)
                    }
                }
            })
        }
    }

    func setPedometerData(data: CMPedometerData) {
        readings = updateMetric(
            store: store,
            metric: metric,
            metricValue: Float(truncating: data.numberOfSteps),
            readings: readings
        )
    }
}
