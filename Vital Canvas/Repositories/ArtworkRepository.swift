import Foundation
import SwiftData
import UIKit

@Observable
final class ArtworkRepository {
    private var modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    func fetchAll() -> [CanvasArtwork] {
        let descriptor = FetchDescriptor<CanvasArtwork>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchRecent(limit: Int = 7) -> [CanvasArtwork] {
        var descriptor = FetchDescriptor<CanvasArtwork>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func fetchForDate(_ date: Date) -> CanvasArtwork? {
        let cal = Calendar.current
        let start = cal.startOfDay(for: date)
        let end = cal.date(byAdding: .day, value: 1, to: start)!
        let predicate = #Predicate<CanvasArtwork> { $0.date >= start && $0.date < end }
        var descriptor = FetchDescriptor<CanvasArtwork>(predicate: predicate)
        descriptor.fetchLimit = 1
        return (try? modelContext.fetch(descriptor))?.first
    }

    func save(_ artwork: CanvasArtwork, image: UIImage?) {
        if let image = image, let data = image.pngData() {
            let filename = "\(artwork.id.uuidString).png"
            let url = imageURL(for: filename)
            try? data.write(to: url)
            artwork.localImagePath = filename
        }
        modelContext.insert(artwork)
        try? modelContext.save()
    }

    func loadImage(for artwork: CanvasArtwork) -> UIImage? {
        guard let path = artwork.localImagePath else { return nil }
        let url = imageURL(for: path)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    func delete(_ artwork: CanvasArtwork) {
        if let path = artwork.localImagePath {
            try? FileManager.default.removeItem(at: imageURL(for: path))
        }
        modelContext.delete(artwork)
        try? modelContext.save()
    }

    private func imageURL(for filename: String) -> URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return docs.appendingPathComponent("artworks").appendingPathComponent(filename)
    }

    func ensureArtworksDirectory() {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("artworks")
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }
}
