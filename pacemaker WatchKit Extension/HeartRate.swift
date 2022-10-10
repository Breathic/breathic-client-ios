import Foundation
import SwiftUI
import HealthKit

class HeartRate: ObservableObject {
    @ObservedObject private var store: AppStore = .shared

    private var healthStore = HKHealthStore()
    let heartRateQuantity = HKUnit(from: "count/min")
    var heartRates: [Double] = []
    var query: HKAnchoredObjectQuery? = nil

    func start() {
        autorizeHealthKit()
        stop()
        heartRates = []
        query = createHeartRateQuery(quantityTypeIdentifier: .heartRate)
        healthStore.execute(query!)
    }

    func stop() {
        if (query != nil) {
            healthStore.stop(query!)
            query = nil
        }
    }

    func autorizeHealthKit() {
        let healthKitTypes: Set = [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
        ]

        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { _, _ in }
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
        for sample in samples {
            if type == .heartRate {
                let heartRate = sample.quantity.doubleValue(for: heartRateQuantity) / 60

                if (heartRate > 0) {
                    let prevHeartRateMetric = store.state.heartRateMetric

                    heartRates.append(heartRate)
                    heartRates = Array(heartRates.suffix(MAX_READING_COUNT))
                    store.state.heartRateMetric = heartRates.reduce(0) { Float($0) + Float($1) } / Float(heartRates.count)

                    if (store.state.heartRateMetric != prevHeartRateMetric) {
                        store.state.lastDataChangeTime = .now()
                    }
                }
            }
        }
    }
}
