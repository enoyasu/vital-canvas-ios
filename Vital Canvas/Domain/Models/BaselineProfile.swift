import Foundation
import SwiftData

@Model
final class BaselineProfile {
    var id: UUID
    var metricName: String
    var median: Double
    var p25: Double
    var p75: Double
    var rollingWindowDays: Int
    var updatedAt: Date

    init(metricName: String, median: Double, p25: Double, p75: Double) {
        self.id = UUID()
        self.metricName = metricName
        self.median = median
        self.p25 = p25
        self.p75 = p75
        self.rollingWindowDays = 28
        self.updatedAt = Date()
    }

    func normalized(_ value: Double) -> Double {
        let iqr = p75 - p25
        guard iqr > 0 else { return 0 }
        let raw = (value - median) / (iqr * 0.7413)
        return max(-2.0, min(2.0, raw))
    }
}
