import Foundation

final class SnapshotBuilder {
    private let healthKit = HealthKitService()

    func buildSnapshot(for date: Date) async -> HealthSnapshot {
        let snapshot = HealthSnapshot(date: date)

        async let sleep = healthKit.sleepHours(for: date)
        async let avgHR = healthKit.averageHeartRate(for: date)
        async let restHR = healthKit.restingHeartRate(for: date)
        async let hrv = healthKit.hrv(for: date)
        async let steps = healthKit.stepCount(for: date)
        async let workout = healthKit.workoutMinutes(for: date)
        async let mindful = healthKit.mindfulMinutes(for: date)

        snapshot.sleepHours = await sleep
        snapshot.averageHeartRate = await avgHR
        snapshot.restingHeartRate = await restHR
        snapshot.hrv = await hrv
        snapshot.stepCount = await steps
        snapshot.workoutMinutes = await workout
        snapshot.mindfulMinutes = await mindful

        return snapshot
    }
}
