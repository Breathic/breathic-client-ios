import Foundation
import SwiftUI
import CoreMotion

class Step {
    @StateObject private var store: Store = .shared

    var pedometer = CMPedometer()
    var readings = [Reading]()
    let metric: String = "step"
    var lastUpdateDate: DispatchTime = .now()
    var timer: Timer?

    var isStepCountingAvailable: Bool {
        get {
            return CMPedometer.isStepCountingAvailable()
        }
    }

    func stop() {
        pedometer.stopUpdates()
        readings = []
        timer?.invalidate()
        timer = nil
    }

    func start() {
        if self.isStepCountingAvailable {
            stop()

            pedometer.startUpdates(from: Date(), withHandler: { (data, error) in
                if data != nil {
                    DispatchQueue.main.async {
                        self.setPedometerData(value: Float(truncating: data!.numberOfSteps))
                        self.lastUpdateDate = .now()
                    }
                }
            })

            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
                if self.lastUpdateDate.distance(to: .now()).toDouble() > READER_INACTIVITY_S {
                    self.readings = []
                    self.store.state.setMetricValue(self.metric, 0)
                }
            }
        }
    }

    func setPedometerData(value: Float) {
        readings = updateMetric(
            store: store,
            metric: metric,
            metricValue: value,
            readings: readings
        )
    }
}
