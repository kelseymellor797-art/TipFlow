import Foundation

/// Categories for earnings logged during a shift.
enum EarningCategory: String, Codable, CaseIterable {
    case lapDance = "Lap Dance"
    case stageTip = "Stage Tip"
    case randomTip = "Random Tip"
    case custom = "Custom"
}

/// A single earnings entry recorded during a shift.
struct Earning: Identifiable, Codable, Equatable {
    let id: UUID
    let amount: Double
    let category: EarningCategory
    let timestamp: Date

    init(id: UUID = UUID(), amount: Double, category: EarningCategory, timestamp: Date = Date()) {
        self.id = id
        self.amount = amount
        self.category = category
        self.timestamp = timestamp
    }
}
