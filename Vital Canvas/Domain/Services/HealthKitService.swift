import Foundation
import HealthKit

final class HealthKitService {
    private let store = HKHealthStore()

    // MARK: - Sleep

    func sleepHours(for date: Date) async -> Double? {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        let interval = dayInterval(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end)
        let samples = await fetchCategorySamples(type: type, predicate: predicate)
        let asleepSamples = samples.filter {
            if #available(iOS 16.0, *) {
                let v = HKCategoryValueSleepAnalysis(rawValue: $0.value)
                return v == .asleepCore || v == .asleepDeep || v == .asleepREM || v == .asleepUnspecified
            } else {
                return $0.value == HKCategoryValueSleepAnalysis.asleep.rawValue
            }
        }
        let totalSeconds = asleepSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        return totalSeconds > 0 ? totalSeconds / 3600 : nil
    }

    // MARK: - Heart Rate

    func averageHeartRate(for date: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return nil }
        let interval = dayInterval(for: date)
        return await averageQuantity(type: type, unit: HKUnit(from: "count/min"), start: interval.start, end: interval.end)
    }

    func restingHeartRate(for date: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return nil }
        let interval = dayInterval(for: date)
        return await latestQuantity(type: type, unit: HKUnit(from: "count/min"), start: interval.start, end: interval.end)
    }

    // MARK: - HRV

    func hrv(for date: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return nil }
        let interval = dayInterval(for: date)
        return await averageQuantity(type: type, unit: .secondUnit(with: .milli), start: interval.start, end: interval.end)
    }

    // MARK: - Steps

    func stepCount(for date: Date) async -> Double? {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return nil }
        let interval = dayInterval(for: date)
        return await sumQuantity(type: type, unit: .count(), start: interval.start, end: interval.end)
    }

    // MARK: - Workout

    func workoutMinutes(for date: Date) async -> Double? {
        let interval = dayInterval(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end)
        let workouts = await fetchWorkouts(predicate: predicate)
        let total = workouts.reduce(0.0) { $0 + $1.duration }
        return total > 0 ? total / 60 : nil
    }

    // MARK: - Mindful

    func mindfulMinutes(for date: Date) async -> Double? {
        guard let type = HKObjectType.categoryType(forIdentifier: .mindfulSession) else { return nil }
        let interval = dayInterval(for: date)
        let predicate = HKQuery.predicateForSamples(withStart: interval.start, end: interval.end)
        let samples = await fetchCategorySamples(type: type, predicate: predicate)
        let total = samples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        return total > 0 ? total / 60 : nil
    }

    // MARK: - Helpers

    private func dayInterval(for date: Date) -> (start: Date, end: Date) {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        return (start, end)
    }

    private func averageQuantity(type: HKQuantityType, unit: HKUnit, start: Date, end: Date) async -> Double? {
        await withCheckedContinuation { cont in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, stats, _ in
                let val = stats?.averageQuantity()?.doubleValue(for: unit)
                cont.resume(returning: val)
            }
            store.execute(query)
        }
    }

    private func latestQuantity(type: HKQuantityType, unit: HKUnit, start: Date, end: Date) async -> Double? {
        await withCheckedContinuation { cont in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteMax) { _, stats, _ in
                let val = stats?.maximumQuantity()?.doubleValue(for: unit)
                cont.resume(returning: val)
            }
            store.execute(query)
        }
    }

    private func sumQuantity(type: HKQuantityType, unit: HKUnit, start: Date, end: Date) async -> Double? {
        await withCheckedContinuation { cont in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, stats, _ in
                let val = stats?.sumQuantity()?.doubleValue(for: unit)
                cont.resume(returning: val)
            }
            store.execute(query)
        }
    }

    private func fetchCategorySamples(type: HKCategoryType, predicate: NSPredicate) async -> [HKCategorySample] {
        await withCheckedContinuation { cont in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                cont.resume(returning: (samples as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }
    }

    private func fetchWorkouts(predicate: NSPredicate) async -> [HKWorkout] {
        await withCheckedContinuation { cont in
            let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                cont.resume(returning: (samples as? [HKWorkout]) ?? [])
            }
            store.execute(query)
        }
    }
}
