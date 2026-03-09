import Foundation

/// Possible outcomes when ending a customer interaction.
enum InteractionOutcome: String, Codable, CaseIterable {
    case noSale = "No Sale"
    case tipOnly = "Tip Only"
    case oneDance = "1 Dance"
    case multipleDances = "Multiple Dances"
    case vipRoom = "VIP / Room"
}

/// A customer interaction session with duration tracking and outcome.
struct Interaction: Identifiable, Codable, Equatable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    var outcome: InteractionOutcome?
    var earningsAmount: Double

    /// Duration of the interaction. Uses current time if still active.
    var duration: TimeInterval {
        let end = endTime ?? Date()
        return end.timeIntervalSince(startTime)
    }

    /// Whether this interaction is currently in progress.
    var isActive: Bool {
        endTime == nil
    }

    init(
        id: UUID = UUID(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        outcome: InteractionOutcome? = nil,
        earningsAmount: Double = 0
    ) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.outcome = outcome
        self.earningsAmount = earningsAmount
    }
}
