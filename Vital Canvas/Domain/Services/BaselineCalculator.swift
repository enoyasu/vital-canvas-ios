import Foundation
import SwiftData

final class BaselineCalculator {

    struct NormalizedParams {
        var sleep: Double = 0
        var hrv: Double = 0
        var restingHR: Double = 0
        var activity: Double = 0
        var mindfulness: Double = 0
    }

    func computeBaselines(from snapshots: [HealthSnapshot]) -> [String: BaselineProfile] {
        var profiles = [String: BaselineProfile]()

        func profile(name: String, values: [Double]) -> BaselineProfile? {
            guard values.count >= 3 else { return nil }
            let sorted = values.sorted()
            let median = percentile(sorted, 0.5)
            let p25 = percentile(sorted, 0.25)
            let p75 = percentile(sorted, 0.75)
            return BaselineProfile(metricName: name, median: median, p25: p25, p75: p75)
        }

        let sleepValues = snapshots.compactMap(\.sleepHours)
        if let p = profile(name: "sleepHours", values: sleepValues) { profiles["sleepHours"] = p }

        let hrvValues = snapshots.compactMap(\.hrv)
        if let p = profile(name: "hrv", values: hrvValues) { profiles["hrv"] = p }

        let restHRValues = snapshots.compactMap(\.restingHeartRate)
        if let p = profile(name: "restingHeartRate", values: restHRValues) { profiles["restingHeartRate"] = p }

        let stepsValues = snapshots.compactMap(\.stepCount)
        let workoutValues = snapshots.compactMap(\.workoutMinutes)
        let combinedActivity = zip(stepsValues, workoutValues).map { s, w in s / 1000 + w }
        if let p = profile(name: "activity", values: combinedActivity) { profiles["activity"] = p }

        let mindfulValues = snapshots.compactMap(\.mindfulMinutes)
        if let p = profile(name: "mindfulMinutes", values: mindfulValues) { profiles["mindfulMinutes"] = p }

        return profiles
    }

    func normalize(snapshot: HealthSnapshot, baselines: [String: BaselineProfile]) -> NormalizedParams {
        var params = NormalizedParams()

        if let value = snapshot.sleepHours, let baseline = baselines["sleepHours"] {
            params.sleep = baseline.normalized(value)
        }
        if let value = snapshot.hrv, let baseline = baselines["hrv"] {
            params.hrv = baseline.normalized(value)
        }
        if let value = snapshot.restingHeartRate, let baseline = baselines["restingHeartRate"] {
            // Invert: higher resting HR relative to baseline = more unrest
            params.restingHR = -baseline.normalized(value)
        }
        let steps = snapshot.stepCount ?? 0
        let workout = snapshot.workoutMinutes ?? 0
        let activityScore = steps / 1000 + workout
        if let baseline = baselines["activity"] {
            params.activity = baseline.normalized(activityScore)
        }
        if let value = snapshot.mindfulMinutes, let baseline = baselines["mindfulMinutes"] {
            params.mindfulness = baseline.normalized(value)
        }

        return params
    }

    func normalizeWithDefaults(snapshot: HealthSnapshot) -> NormalizedParams {
        var params = NormalizedParams()

        // Use population averages as fallback defaults
        if let sleep = snapshot.sleepHours {
            params.sleep = clamp((sleep - 7.0) / 1.5)
        }
        if let hrv = snapshot.hrv {
            params.hrv = clamp((hrv - 45) / 25)
        }
        if let rhr = snapshot.restingHeartRate {
            params.restingHR = clamp(-(rhr - 65) / 15)
        }
        let steps = snapshot.stepCount ?? 0
        let workout = snapshot.workoutMinutes ?? 0
        params.activity = clamp((steps / 1000 + workout - 12) / 8)
        if let mindful = snapshot.mindfulMinutes {
            params.mindfulness = clamp((mindful - 5) / 10)
        }

        return params
    }

    private func percentile(_ sorted: [Double], _ p: Double) -> Double {
        guard !sorted.isEmpty else { return 0 }
        let idx = p * Double(sorted.count - 1)
        let lower = Int(idx)
        let upper = min(lower + 1, sorted.count - 1)
        let frac = idx - Double(lower)
        return sorted[lower] * (1 - frac) + sorted[upper] * frac
    }

    private func clamp(_ value: Double) -> Double {
        max(-2.0, min(2.0, value))
    }
}
