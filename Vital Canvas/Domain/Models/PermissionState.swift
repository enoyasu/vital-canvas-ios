import Foundation
import SwiftData

@Model
final class PermissionState {
    var id: UUID
    var hasRequestedHealth: Bool
    var hasCompletedOnboarding: Bool
    var createdAt: Date

    init() {
        self.id = UUID()
        self.hasRequestedHealth = false
        self.hasCompletedOnboarding = false
        self.createdAt = Date()
    }
}
