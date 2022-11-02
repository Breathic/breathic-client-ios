import Foundation
import SwiftUI
import HealthKit

class Heart: ObservableObject {
    @ObservedObject private var store: AppStore = .shared

    private var healthStore = HKHealthStore()
    let heartRateQuantity = HKUnit(from: "count/min")
    var hearts: [Double] = []
    var query: HKAnchoredObjectQuery? = nil

    func start() {
        autorizeHealthKit()
        stop()
        hearts = []
        query = createHeartRateQuery(quantityTypeIdentifier: .heartRate)
        healthStore.execute(query!)
    }

    func stop() {
        if (query != nil) {
            healthStore.stop(query!)
            query = nil
        }

        hearts = []
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
                let heart = sample.quantity.doubleValue(for: heartRateQuantity)

                if heart >= 0 {
                    let prevHeart = store.state.heart

                    hearts.append(heart)
                    hearts = Array(hearts.suffix(MAX_READING_COUNT))

                    let res = hearts.reduce(0) { Float($0) + Float($1) } / Float(hearts.count)
                    if res >= 0 && !res.isInfinite && !res.isNaN {
                        store.state.heart = res

                        if store.state.heart != prevHeart {
                            store.state.lastDataChangeTime = .now()
                        }
                    }
                }
            }
        }
    }
}
