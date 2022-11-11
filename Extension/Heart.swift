import Foundation
import SwiftUI
import HealthKit

class Heart {
    @ObservedObject private var store: Store = .shared

    var healthStore = HKHealthStore()
    let heartRateQuantity = HKUnit(from: "count/min")
    var readings: [Reading] = []
    var query: HKAnchoredObjectQuery? = nil
    let metric: String = "heart"

    func start() {
        autorizeHealthKit()
        exec()
    }

    func stop() {
        if (query != nil) {
            healthStore.stop(query!)
            query = nil
        }

        readings = []
    }

    func exec() {
        query = createHeartRateQuery(quantityTypeIdentifier: .heartRate)
        healthStore.execute(query!)
    }

    func autorizeHealthKit() {
        let healthKitTypes: Set = [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        ]

        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { result, error in
            if result {
                self.exec()
            } else if let error = error {
                print("healthStore.requestAuthorization: \(error.localizedDescription)")
            } else {
                fatalError("How did we get here?")
            }
        }
    }

    private func createHeartRateQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) -> HKAnchoredObjectQuery {
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
        let q = HKAnchoredObjectQuery(
            type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!,
            predicate: devicePredicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit,
            resultsHandler: updateHandler
        )
        q.updateHandler = updateHandler

        return q
    }

    private func process(_ samples: [HKQuantitySample], type: HKQuantityTypeIdentifier) {
        if type != .heartRate {
            return
        }

        for sample in samples {
            readings = updateMetric(
                store: store,
                metric: metric,
                metricValue: Float(sample.quantity.doubleValue(for: heartRateQuantity)),
                readings: readings
            )
        }
    }
}
