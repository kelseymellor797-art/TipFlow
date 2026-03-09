// Models.swift — TipFlow
// Core data structures for earnings, interactions, and shifts.

import Foundation

// MARK: - Enums

enum EarningsType: String, Codable, CaseIterable {
    case lapDance   = "Lap Dance"
    case stageTip   = "Stage Tip"
    case randomTip  = "Random Tip"
    case custom     = "Custom"
}

enum InteractionOutcome: String, Codable, CaseIterable {
    case noSale         = "No Sale"
    case tipOnly        = "Tip Only"
    case oneDance       = "1 Dance"
    case multipleDances = "Multiple Dances"
    case vipRoom        = "VIP / Room"

    var emoji: String {
        switch self {
        case .noSale:         return "—"
        case .tipOnly:        return "$"
        case .oneDance:       return "1x"
        case .multipleDances: return "2x+"
        case .vipRoom:        return "VIP"
        }
    }

    /// Default dollar suggestion shown when outcome is selected.
    var earningsSuggestion: Double {
        switch self {
        case .noSale:         return 0
        case .tipOnly:        return 5
        case .oneDance:       return 20
        case .multipleDances: return 40
        case .vipRoom:        return 100
        }
    }
}

// MARK: - EarningsEntry

struct EarningsEntry: Identifiable, Codable {
    let id: UUID
    let type: EarningsType
    let amount: Double
    let timestamp: Date
    var interactionID: UUID?

    init(type: EarningsType, amount: Double, interactionID: UUID? = nil) {
        self.id            = UUID()
        self.type          = type
        self.amount        = amount
        self.timestamp     = Date()
        self.interactionID = interactionID
    }
}

// MARK: - InteractionSession

struct InteractionSession: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    var outcome: InteractionOutcome?
    var earningsAmount: Double

    var duration: TimeInterval? {
        guard let end = endTime else { return nil }
        return end.timeIntervalSince(startTime)
    }

    var isActive: Bool { endTime == nil }

    init() {
        self.id            = UUID()
        self.startTime     = Date()
        self.earningsAmount = 0
    }
}

// MARK: - Shift

struct Shift: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    var entries: [EarningsEntry]
    var interactions: [InteractionSession]

    // MARK: Computed totals
    var totalEarnings: Double   { entries.reduce(0) { $0 + $1.amount } }
    var lapDanceTotal: Double   { entries.filter { $0.type == .lapDance }.reduce(0) { $0 + $1.amount } }
    var stageTipTotal: Double   { entries.filter { $0.type == .stageTip }.reduce(0) { $0 + $1.amount } }
    var randomTipTotal: Double  { entries.filter { $0.type == .randomTip || $0.type == .custom }.reduce(0) { $0 + $1.amount } }

    var completedInteractions: [InteractionSession] { interactions.filter { !$0.isActive } }

    var conversionRate: Double {
        let completed = completedInteractions
        guard !completed.isEmpty else { return 0 }
        let converted = completed.filter { $0.outcome != nil && $0.outcome != .noSale }.count
        return Double(converted) / Double(completed.count)
    }

    var averageInteractionDuration: TimeInterval {
        let durations = completedInteractions.compactMap { $0.duration }
        guard !durations.isEmpty else { return 0 }
        return durations.reduce(0, +) / Double(durations.count)
    }

    /// Total shift window: startDate → 2:00 AM (next occurrence after start).
    /// Gives a consistent denominator for per-hour rate regardless of when entries are logged.
    var shiftDurationHours: Double {
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: startDate)

        // If shift started before 2am (e.g. 12:30am), 2am is the same calendar day.
        // If shift started at/after 2am (e.g. 9pm), 2am is the next calendar day.
        let baseDay: Date
        if startHour < 2 {
            baseDay = startDate
        } else {
            baseDay = calendar.date(byAdding: .day, value: 1, to: startDate) ?? startDate
        }

        var endComponents    = calendar.dateComponents([.year, .month, .day], from: baseDay)
        endComponents.hour   = 2
        endComponents.minute = 0
        endComponents.second = 0

        let shiftEnd = calendar.date(from: endComponents) ?? startDate.addingTimeInterval(5 * 3600)
        return max(0.5, shiftEnd.timeIntervalSince(startDate)) / 3600
    }

    var earningsPerHour: Double {
        let hours = shiftDurationHours
        guard hours > 0 else { return 0 }
        return totalEarnings / hours
    }

    init() {
        self.id           = UUID()
        self.startDate    = Date()
        self.entries      = []
        self.interactions = []
    }
}

// MARK: - ShiftRecord (saved history)

struct ShiftRecord: Identifiable, Codable {
    let id: UUID
    let date: Date
    let totalEarnings: Double
    let interactionCount: Int
    let conversionRate: Double
    let durationHours: Double

    init(from shift: Shift) {
        self.id               = shift.id
        self.date             = shift.startDate
        self.totalEarnings    = shift.totalEarnings
        self.interactionCount = shift.interactions.count
        self.conversionRate   = shift.conversionRate
        self.durationHours    = shift.shiftDurationHours
    }
}
