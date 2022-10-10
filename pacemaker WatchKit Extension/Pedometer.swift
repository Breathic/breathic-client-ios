import Foundation
import SwiftUI
import CoreMotion

class Pedometer {
    @ObservedObject private var store: AppStore = .shared
    
    var pedometer = CMPedometer()
    var steps = [Step]()

    var isStepCountingAvailable: Bool {
        get {
            return CMPedometer.isStepCountingAvailable()
        }
    }
    
    func setPedometerData(data: CMPedometerData) {
        let step = Step()
        step.time = .now()
        step.count = Int(truncating: data.numberOfSteps)
        steps.append(step)
        
        if steps.count > MAX_READING_COUNT {
            steps = Array(steps.suffix(MAX_READING_COUNT))
        }

        if steps.count > 1 {
            let prevStepMetric = store.state.stepMetric
            let intervalDuration: DispatchTimeInterval = steps[0].time.distance(to: step.time)
            let intervalSteps = Double(steps[steps.count - 1].count - steps[0].count)
            store.state.stepMetric = Float(intervalDuration.toDouble()) / Float(intervalSteps)

            if (store.state.stepMetric != prevStepMetric) {
                store.state.lastDataChangeTime = .now()
            }
        }
    }
    
    func stop() {
        pedometer.stopUpdates()
    }

    func start() {
        if self.isStepCountingAvailable {
            stop()
            steps = []

            pedometer.startUpdates(from: Date(), withHandler: { (data, error) in
                if data != nil {
                    DispatchQueue.main.async {
                        self.setPedometerData(data: data!)
                    }
                }
            })
        }
    }
}
