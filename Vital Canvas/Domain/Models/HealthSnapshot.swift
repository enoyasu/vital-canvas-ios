import Foundation
import SwiftData

@Model
final class HealthSnapshot {
    var id: UUID
    var date: Date
    var sleepHours: Double?
    var sleepConsistencyScore: Double?
    var averageHeartRate: Double?
    var restingHeartRate: Double?
    var hrv: Double?
    var stepCount: Double?
    var workoutMinutes: Double?
    var mindfulMinutes: Double?
    var createdAt: Date

    init(date: Date) {
        self.id = UUID()
        self.date = date
        self.createdAt = Date()
    }

    var hasAnyData: Bool {
        sleepHours != nil ||
        averageHeartRate != nil ||
        restingHeartRate != nil ||
        hrv != nil ||
        stepCount != nil ||
        workoutMinutes != nil ||
        mindfulMinutes != nil
    }
}
