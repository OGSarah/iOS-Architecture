import Foundation
import Observation
import SwiftData

/// Presentation state for the finished match list.
///
/// The ViewModel owns the fetch instead of the view using `@Query`, so the
/// list is unit testable with an in memory container.
@Observable
@MainActor
final class MatchHistoryViewModel {

    /// The finished matches, newest first.
    private(set) var records: [MatchRecord] = []

    private let modelContext: ModelContext

    /// Creates the ViewModel reading from a SwiftData context.
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    /// Fetches the records, newest first.
    func reload() {
        let descriptor = FetchDescriptor<MatchRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        records = (try? modelContext.fetch(descriptor)) ?? []
    }

    /// Deletes a record and refreshes the list.
    func delete(_ record: MatchRecord) {
        modelContext.delete(record)
        try? modelContext.save()
        reload()
    }
}
