import Foundation

final class SnapshotBuilder {
    private let healthKit = HealthKitService()

    // Plain struct — Sendable, safe to pass across actor boundaries
    struct RawHealthValues: Sendable {
        var sleepHours: Double?
        var averageHeartRate: Double?
        var restingHeartRate: Double?
        var hrv: Double?
        var stepCount: Double?
        var workoutMinutes: Double?
        var mindfulMinutes: Double?
    }

    // Collect raw values on the cooperative thread pool (HealthKit callbacks).
    // Caller is responsible for creating HealthSnapshot on the correct actor.
    func fetchValues(for date: Date) async -> RawHealthValues {
        async let sleep   = healthKit.sleepHours(for: date)
        async let avgHR   = healthKit.averageHeartRate(for: date)
        async let restHR  = healthKit.restingHeartRate(for: date)
        async let hrv     = healthKit.hrv(for: date)
        async let steps   = healthKit.stepCount(for: date)
        async let workout = healthKit.workoutMinutes(for: date)
        async let mindful = healthKit.mindfulMinutes(for: date)

        return RawHealthValues(
            sleepHours:       await sleep,
            averageHeartRate: await avgHR,
            restingHeartRate: await restHR,
            hrv:              await hrv,
            stepCount:        await steps,
            workoutMinutes:   await workout,
            mindfulMinutes:   await mindful
        )
    }
}
