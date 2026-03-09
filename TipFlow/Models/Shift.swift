import Foundation

/// A complete work shift containing all earnings and interactions.
struct Shift: Identifiable, Codable, Equatable {
    let id: UUID
    let date: Date
    var startTime: Date
    var endTime: Date?
    var earnings: [Earning]
    var interactions: [Interaction]
    var goalAmount: Double

    /// Total earnings across all categories.
    var totalEarnings: Double {
        earnings.reduce(0) { $0 + $1.amount }
    }

    /// Total earnings from lap dances only.
    var lapDanceEarnings: Double {
        earnings.filter { $0.category == .lapDance }.reduce(0) { $0 + $1.amount }
    }

    /// Total earnings from stage tips only.
    var stageTipEarnings: Double {
        earnings.filter { $0.category == .stageTip }.reduce(0) { $0 + $1.amount }
    }

    /// Total earnings from random tips only.
    var randomTipEarnings: Double {
        earnings.filter { $0.category == .randomTip }.reduce(0) { $0 + $1.amount }
    }

    /// Number of recorded interactions.
    var interactionCount: Int {
        interactions.count
    }

    /// Ratio of interactions that resulted in a dance or VIP booking.
    var conversionRate: Double {
        let completed = interactions.filter { $0.endTime != nil }
        guard !completed.isEmpty else { return 0 }
        let conversions = completed.filter {
            $0.outcome == .oneDance || $0.outcome == .multipleDances || $0.outcome == .vipRoom
        }
        return Double(conversions.count) / Double(completed.count)
    }

    init(
        id: UUID = UUID(),
        date: Date = Date(),
        startTime: Date = Date(),
        endTime: Date? = nil,
        earnings: [Earning] = [],
        interactions: [Interaction] = [],
        goalAmount: Double = 400
    ) {
        self.id = id
        self.date = date
        self.startTime = startTime
        self.endTime = endTime
        self.earnings = earnings
        self.interactions = interactions
        self.goalAmount = goalAmount
    }
}
