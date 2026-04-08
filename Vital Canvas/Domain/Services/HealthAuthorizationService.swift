import Foundation
import HealthKit

@Observable
final class HealthAuthorizationService {
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private let readTypes: Set<HKObjectType> = {
        var types = Set<HKObjectType>()
        let identifiers: [HKQuantityTypeIdentifier] = [
            .heartRate,
            .restingHeartRate,
            .heartRateVariabilitySDNN,
            .stepCount
        ]
        for id in identifiers {
            if let t = HKObjectType.quantityType(forIdentifier: id) {
                types.insert(t)
            }
        }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        if let mindful = HKObjectType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindful)
        }
        types.insert(HKObjectType.workoutType())
        return types
    }()

    func requestAuthorization() async throws {
        guard isAvailable else { return }
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    func authorizationStatus(for identifier: HKQuantityTypeIdentifier) -> HKAuthorizationStatus {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return .notDetermined }
        return store.authorizationStatus(for: type)
    }
}
