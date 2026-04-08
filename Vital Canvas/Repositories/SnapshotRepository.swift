import Foundation
import SwiftData

@Observable
final class SnapshotRepository {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() -> [HealthSnapshot] {
        let descriptor = FetchDescriptor<HealthSnapshot>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchRecent(days: Int = 28) -> [HealthSnapshot] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date())!
        let predicate = #Predicate<HealthSnapshot> { $0.date >= cutoff }
        let descriptor = FetchDescriptor<HealthSnapshot>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchForDate(_ date: Date) -> HealthSnapshot? {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let predicate = #Predicate<HealthSnapshot> { $0.date >= start && $0.date < end }
        var descriptor = FetchDescriptor<HealthSnapshot>(predicate: predicate)
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }

    func save(_ snapshot: HealthSnapshot) {
        modelContext.insert(snapshot)
        try? modelContext.save()
    }
}
