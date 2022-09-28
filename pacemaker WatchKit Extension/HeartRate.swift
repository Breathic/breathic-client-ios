import Foundation
import SwiftUI
import HealthKit

class HeartRate: ObservableObject {
    @ObservedObject private var store: AppStore = .shared

    private var healthStore = HKHealthStore()
    let heartRateQuantity = HKUnit(from: "count/min")
    var heartRates: [Double] = []

    func start() {
        autorizeHealthKit()
        startHeartRateQuery(quantityTypeIdentifier: .heartRate)
    }

    func autorizeHealthKit() {
        let healthKitTypes: Set = [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        ]

        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { _, _ in }
    }

    private func startHeartRateQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) {
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
            query, samples, deletedObjects, queryAnchor, error in
            guard let samples = samples as? [HKQuantitySample] else {
                return
            }

            DispatchQueue.main.async {
                self.process(samples, type: quantityTypeIdentifier)
            }
        }
        let query = HKAnchoredObjectQuery(
            type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!,
            predicate: devicePredicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit,
            resultsHandler: updateHandler
        )
        query.updateHandler = updateHandler
        healthStore.execute(query)
    }

    private func process(_ samples: [HKQuantitySample], type: HKQuantityTypeIdentifier) {
        for sample in samples {
            if type == .heartRate {
                let heartRate = sample.quantity.doubleValue(for: heartRateQuantity) / 60

                if (heartRate >= 0) {
                    let minValue = 0.1

                    heartRates.append(heartRate)
                    heartRates = Array(heartRates.suffix(MAX_READING_COUNT))
                    store.state.averageHeartRatePerSecond = heartRates.reduce(0) { $0 + $1 } / Double(heartRates.count)

                    if store.state.averageMetersPerSecond < minValue {
                        store.state.averageHeartRatePerSecond = minValue
                    }
                }
            }
        }
    }
}
