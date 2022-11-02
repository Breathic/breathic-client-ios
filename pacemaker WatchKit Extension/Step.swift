import Foundation
import SwiftUI
import CoreMotion

class Step {
    @ObservedObject private var store: AppStore = .shared

    var pedometer = CMPedometer()
    var steps = [StepData]()

    var isStepCountingAvailable: Bool {
        get {
            return CMPedometer.isStepCountingAvailable()
        }
    }

    func setPedometerData(data: CMPedometerData) {
        let step = StepData()
        step.time = .now()
        step.count = Int(truncating: data.numberOfSteps)
        steps.append(step)
        
        if steps.count > MAX_READING_COUNT {
            steps = Array(steps.suffix(MAX_READING_COUNT))
        }

        if steps.count > 1 {
            let prevStep = store.state.step
            let intervalDuration: DispatchTimeInterval = steps[0].time.distance(to: step.time)
            let intervalSteps = Double(steps[steps.count - 1].count - steps[0].count)
            let res = Float(intervalDuration.toDouble()) / Float(intervalSteps) * 60

            if res >= 0 && !res.isInfinite && !res.isNaN {
                store.state.step = res

                if store.state.step != prevStep {
                    store.state.lastDataChangeTime = .now()
                }
            }
        }
    }

    func stop() {
        pedometer.stopUpdates()
        steps = []
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
}
