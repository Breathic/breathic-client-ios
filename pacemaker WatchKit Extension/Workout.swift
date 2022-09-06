import Foundation
import SwiftUI
import HealthKit

class Workout: ObservableObject {
    @ObservedObject private var store: AppStore = .shared

    private var healthStore = HKHealthStore()
    let heartRateQuantity = HKUnit(from: "count/min")

    init() {
        autorizeHealthKit()
        startHeartRateQuery(quantityTypeIdentifier: .heartRate)
    }

    func autorizeHealthKit() {
        let healthKitTypes: Set = [
        HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!]

        healthStore.requestAuthorization(toShare: healthKitTypes, read: healthKitTypes) { _, _ in }
    }

    private func startHeartRateQuery(quantityTypeIdentifier: HKQuantityTypeIdentifier) {
        let devicePredicate = HKQuery.predicateForObjects(from: [HKDevice.local()])
        let updateHandler: (HKAnchoredObjectQuery, [HKSample]?, [HKDeletedObject]?, HKQueryAnchor?, Error?) -> Void = {
            query, samples, deletedObjects, queryAnchor, error in
            guard let samples = samples as? [HKQuantitySample] else {
                return
            }
            self.process(samples, type: quantityTypeIdentifier)
        }
        let query = HKAnchoredObjectQuery(type: HKObjectType.quantityType(forIdentifier: quantityTypeIdentifier)!, predicate: devicePredicate, anchor: nil, limit: HKObjectQueryNoLimit, resultsHandler: updateHandler)
        query.updateHandler = updateHandler
        healthStore.execute(query)
    }

    private func process(_ samples: [HKQuantitySample], type: HKQuantityTypeIdentifier) {
        for sample in samples {
            if type == .heartRate {
                store.state.averageHeartRatePerSecond = sample.quantity.doubleValue(for: heartRateQuantity) / 60
            }
        }
    }
}
