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

// MARK: - ExpenseType

enum ExpenseType: String, Codable, CaseIterable {
    case houseFee  = "House Fee"
    case tipOut    = "Tip Out"
    case outfit    = "Outfit"
    case transport = "Uber / Transport"
    case food      = "Food / Drink"
    case other     = "Other"

    var icon: String {
        switch self {
        case .houseFee:  return "building.2"
        case .tipOut:    return "dollarsign.arrow.trianglehead.counterclockwise.rotate.90"
        case .outfit:    return "tshirt"
        case .transport: return "car.fill"
        case .food:      return "fork.knife"
        case .other:     return "ellipsis.circle"
        }
    }
}

// MARK: - Expense

struct Expense: Identifiable, Codable {
    let id: UUID
    let type: ExpenseType
    let amount: Double
    let note: String
    let timestamp: Date

    init(type: ExpenseType, amount: Double, note: String = "") {
        self.id = UUID(); self.type = type; self.amount = amount
        self.note = note; self.timestamp = Date()
    }
}

// MARK: - EarningsEntry

struct EarningsEntry: Identifiable, Codable {
    let id: UUID
    let type: EarningsType
    let amount: Double
    let timestamp: Date
    var interactionID: UUID?
    var outfitSessionId: UUID?

    private enum CodingKeys: String, CodingKey {
        case id, type, amount, timestamp, interactionID, outfitSessionId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id              = try c.decode(UUID.self, forKey: .id)
        type            = try c.decode(EarningsType.self, forKey: .type)
        amount          = try c.decode(Double.self, forKey: .amount)
        timestamp       = try c.decode(Date.self, forKey: .timestamp)
        interactionID   = try? c.decode(UUID.self, forKey: .interactionID)
        outfitSessionId = try? c.decode(UUID.self, forKey: .outfitSessionId)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,        forKey: .id)
        try c.encode(type,      forKey: .type)
        try c.encode(amount,    forKey: .amount)
        try c.encode(timestamp, forKey: .timestamp)
        try? c.encode(interactionID,   forKey: .interactionID)
        try? c.encode(outfitSessionId, forKey: .outfitSessionId)
    }

    init(type: EarningsType, amount: Double, interactionID: UUID? = nil, outfitSessionId: UUID? = nil) {
        self.id              = UUID()
        self.type            = type
        self.amount          = amount
        self.timestamp       = Date()
        self.interactionID   = interactionID
        self.outfitSessionId = outfitSessionId
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

// MARK: - HourlyEarning

struct HourlyEarning: Identifiable {
    var id: Int { hour }
    let hour: Int
    let total: Double
}

// MARK: - OutfitStyle / FabricFinish

enum OutfitStyle: String, Codable, CaseIterable {
    case bikini   = "Bikini"
    case bodysuit = "Bodysuit"
    case strappy  = "Strappy"
    case harness  = "Harness"
    case other    = "Other"
}

enum FabricFinish: String, Codable, CaseIterable {
    case matte        = "Matte"
    case holographic  = "Holographic"
    case glitter      = "Glitter"
    case mesh         = "Mesh"
    case other        = "Other"
}

// MARK: - OutfitSession

struct OutfitSession: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    var endTime: Date?
    var name: String
    var primaryColor: String
    var secondaryColor: String
    var style: OutfitStyle?
    var fabricFinish: FabricFinish?
    var shoes: String
    var hair: String
    var nails: String
    var photoFilename: String?
    var confidenceRating: Int  // 1–5
    var comfortRating: Int     // 1–5, set at session end

    var isActive: Bool { endTime == nil }
    var duration: TimeInterval { (endTime ?? Date()).timeIntervalSince(startTime) }

    var durationFormatted: String {
        let total = Int(duration)
        let h = total / 3600
        let m = (total % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }

    init(name: String = "", primaryColor: String = "", secondaryColor: String = "",
         style: OutfitStyle? = nil, fabricFinish: FabricFinish? = nil,
         shoes: String = "", hair: String = "", nails: String = "",
         photoFilename: String? = nil, confidenceRating: Int = 3) {
        self.id               = UUID()
        self.startTime        = Date()
        self.name             = name
        self.primaryColor     = primaryColor
        self.secondaryColor   = secondaryColor
        self.style            = style
        self.fabricFinish     = fabricFinish
        self.shoes            = shoes
        self.hair             = hair
        self.nails            = nails
        self.photoFilename    = photoFilename
        self.confidenceRating = confidenceRating
        self.comfortRating    = 0
    }
}

// MARK: - Shift

struct Shift: Identifiable, Codable {
    let id: UUID
    let startDate: Date
    var entries: [EarningsEntry]
    var interactions: [InteractionSession]
    var expenses: [Expense]
    var outfitSessions: [OutfitSession]
    var isStarted: Bool

    var totalEarnings: Double   { entries.reduce(0) { $0 + $1.amount } }
    var lapDanceTotal: Double   { entries.filter { $0.type == .lapDance }.reduce(0) { $0 + $1.amount } }
    var stageTipTotal: Double   { entries.filter { $0.type == .stageTip }.reduce(0) { $0 + $1.amount } }
    var randomTipTotal: Double  { entries.filter { $0.type == .randomTip || $0.type == .custom }.reduce(0) { $0 + $1.amount } }

    var totalExpenses: Double   { expenses.reduce(0) { $0 + $1.amount } }
    var netProfit: Double       { totalEarnings - totalExpenses }

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

    var shiftDurationHours: Double {
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: startDate)
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

    var hourlyBreakdown: [HourlyEarning] {
        var hourTotals: [Int: Double] = [:]
        for entry in entries {
            let hour = Calendar.current.component(.hour, from: entry.timestamp)
            hourTotals[hour, default: 0] += entry.amount
        }
        return hourTotals
            .map { HourlyEarning(hour: $0.key, total: $0.value) }
            .sorted {
                let a = $0.hour < 6 ? $0.hour + 24 : $0.hour
                let b = $1.hour < 6 ? $1.hour + 24 : $1.hour
                return a < b
            }
    }

    var activeOutfitSession: OutfitSession? {
        outfitSessions.last(where: { $0.isActive })
    }

    func earningsForOutfit(_ session: OutfitSession) -> Double {
        entries.filter { $0.outfitSessionId == session.id }.reduce(0) { $0 + $1.amount }
    }

    func danceCountForOutfit(_ session: OutfitSession) -> Int {
        entries.filter { $0.outfitSessionId == session.id && $0.type == .lapDance }.count
    }

    // MARK: Codable

    private enum CodingKeys: String, CodingKey {
        case id, startDate, entries, interactions, expenses, outfitSessions, isStarted
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id             = try c.decode(UUID.self, forKey: .id)
        startDate      = try c.decode(Date.self, forKey: .startDate)
        entries        = try c.decode([EarningsEntry].self, forKey: .entries)
        interactions   = try c.decode([InteractionSession].self, forKey: .interactions)
        expenses       = (try? c.decode([Expense].self, forKey: .expenses)) ?? []
        outfitSessions = (try? c.decode([OutfitSession].self, forKey: .outfitSessions)) ?? []
        isStarted      = (try? c.decode(Bool.self, forKey: .isStarted)) ?? false
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,             forKey: .id)
        try c.encode(startDate,      forKey: .startDate)
        try c.encode(entries,        forKey: .entries)
        try c.encode(interactions,   forKey: .interactions)
        try c.encode(expenses,       forKey: .expenses)
        try c.encode(outfitSessions, forKey: .outfitSessions)
        try c.encode(isStarted,      forKey: .isStarted)
    }

    init() {
        self.id             = UUID()
        self.startDate      = Date()
        self.entries        = []
        self.interactions   = []
        self.expenses       = []
        self.outfitSessions = []
        self.isStarted      = false
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
    let netProfit: Double
    var outfitSessions: [OutfitSession]

    private enum CodingKeys: String, CodingKey {
        case id, date, totalEarnings, interactionCount, conversionRate, durationHours, netProfit, outfitSessions
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id               = try c.decode(UUID.self,   forKey: .id)
        date             = try c.decode(Date.self,   forKey: .date)
        totalEarnings    = try c.decode(Double.self, forKey: .totalEarnings)
        interactionCount = try c.decode(Int.self,    forKey: .interactionCount)
        conversionRate   = try c.decode(Double.self, forKey: .conversionRate)
        durationHours    = try c.decode(Double.self, forKey: .durationHours)
        netProfit        = (try? c.decode(Double.self, forKey: .netProfit)) ?? totalEarnings
        outfitSessions   = (try? c.decode([OutfitSession].self, forKey: .outfitSessions)) ?? []
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id,               forKey: .id)
        try c.encode(date,             forKey: .date)
        try c.encode(totalEarnings,    forKey: .totalEarnings)
        try c.encode(interactionCount, forKey: .interactionCount)
        try c.encode(conversionRate,   forKey: .conversionRate)
        try c.encode(durationHours,    forKey: .durationHours)
        try c.encode(netProfit,        forKey: .netProfit)
        try c.encode(outfitSessions,   forKey: .outfitSessions)
    }

    init(from shift: Shift) {
        self.id               = shift.id
        self.date             = shift.startDate
        self.totalEarnings    = shift.totalEarnings
        self.interactionCount = shift.interactions.count
        self.conversionRate   = shift.conversionRate
        self.durationHours    = shift.shiftDurationHours
        self.netProfit        = shift.netProfit
        self.outfitSessions   = shift.outfitSessions
    }
}
