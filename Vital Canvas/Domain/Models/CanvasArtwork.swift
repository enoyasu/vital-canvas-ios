import Foundation
import SwiftData

@Model
final class CanvasArtwork {
    var id: UUID
    var date: Date
    var style: String
    var seed: Int
    var title: String
    var subtitle: String
    var summary: String
    var localImagePath: String?

    // Normalized health parameters (-2.0 to +2.0)
    var sleepNormalized: Double
    var hrvNormalized: Double
    var restingHRNormalized: Double
    var activityNormalized: Double
    var mindfulnessNormalized: Double

    init(
        date: Date,
        seed: Int,
        title: String,
        subtitle: String,
        summary: String,
        sleep: Double,
        hrv: Double,
        restingHR: Double,
        activity: Double,
        mindfulness: Double
    ) {
        self.id = UUID()
        self.date = date
        self.style = "garden"
        self.seed = seed
        self.title = title
        self.subtitle = subtitle
        self.summary = summary
        self.sleepNormalized = sleep
        self.hrvNormalized = hrv
        self.restingHRNormalized = restingHR
        self.activityNormalized = activity
        self.mindfulnessNormalized = mindfulness
    }

    var dateLabel: String {
        let f = DateFormatter()
        f.dateFormat = "EEEE"
        return f.string(from: date)
    }

    var dateShort: String {
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }

    var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }
}
