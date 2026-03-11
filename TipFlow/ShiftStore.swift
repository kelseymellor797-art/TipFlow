// ShiftStore.swift — TipFlow
import Foundation
import Observation
import UIKit

@Observable
final class ShiftStore {
    var currentShift: Shift = Shift()
    var pastShifts: [ShiftRecord] = []
    var activeInteraction: InteractionSession?
    var interactionElapsed: TimeInterval = 0
    var showOneMinutePrompt: Bool = false
    var showEndInteractionSheet: Bool = false
    var nightlyGoal: Double = 400
    var managerRate: Double = 0.10
    var djRate:      Double = 0.10
    var bouncerRate: Double = 0.05
    var lastInteractionEndTime: Date? = nil
    var showStartShift: Bool = false

    private var timerTask: Task<Void, Never>?
    private var nextPromptAt: TimeInterval = 60

    private enum Keys {
        static let currentShift        = "tipflow.currentShift"
        static let pastShifts          = "tipflow.pastShifts"
        static let nightlyGoal         = "tipflow.nightlyGoal"
        static let managerRate         = "tipflow.managerRate"
        static let djRate              = "tipflow.djRate"
        static let bouncerRate         = "tipflow.bouncerRate"
        static let activeInteraction   = "tipflow.activeInteraction"
        static let interactionElapsed  = "tipflow.interactionElapsed"
    }

    init() { load() }

    func logEarnings(type: EarningsType, amount: Double, interactionID: UUID? = nil) {
        let entry = EarningsEntry(type: type, amount: amount, interactionID: interactionID, outfitSessionId: currentShift.activeOutfitSession?.id)
        currentShift.entries.append(entry)
        saveCurrentShift()
    }

    func logExpense(type: ExpenseType, amount: Double, note: String = "") {
        let expense = Expense(type: type, amount: amount, note: note)
        currentShift.expenses.append(expense)
        saveCurrentShift()
    }

    var isInteractionActive: Bool { activeInteraction != nil }

    func startInteraction() {
        guard activeInteraction == nil else { return }
        activeInteraction  = InteractionSession()
        interactionElapsed = 0
        nextPromptAt       = 300
        showOneMinutePrompt = false
        saveActiveInteraction()
        startTimer()
    }

    func extendInteraction(by minutes: Int) {
        showOneMinutePrompt = false
        nextPromptAt = interactionElapsed + Double(minutes * 60)
    }

    func dismissOneMinutePrompt() {
        showOneMinutePrompt = false
        nextPromptAt = interactionElapsed + 300
    }

    func endInteraction(outcome: InteractionOutcome, amount: Double?) {
        guard var interaction = activeInteraction else { return }
        stopTimer()

        interaction.endTime = Date()
        interaction.outcome = outcome

        if let amt = amount, amt > 0, outcome != .noSale {
            interaction.earningsAmount = amt
            let type: EarningsType = (outcome == .tipOnly) ? .randomTip : .lapDance
            logEarnings(type: type, amount: amt, interactionID: interaction.id)
        }

        currentShift.interactions.append(interaction)
        lastInteractionEndTime = Date()
        activeInteraction   = nil
        interactionElapsed  = 0
        showOneMinutePrompt = false
        showEndInteractionSheet = false
        clearActiveInteraction()
        saveCurrentShift()
    }

    func endShift() {
        if activeInteraction != nil { endInteraction(outcome: .noSale, amount: nil) }
        // Close any active outfit session
        if let idx = currentShift.outfitSessions.indices.last(where: { currentShift.outfitSessions[$0].isActive }) {
            currentShift.outfitSessions[idx].endTime = Date()
        }
        let record = ShiftRecord(from: currentShift)
        pastShifts.insert(record, at: 0)
        currentShift = Shift()
        lastInteractionEndTime = nil
        showStartShift = true
        savePastShifts()
        saveCurrentShift()
    }

    private func startTimer() {
        timerTask?.cancel()
        timerTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 1_000_000_000)
                guard !Task.isCancelled else { break }
                interactionElapsed += 1
                saveActiveInteraction()
                if interactionElapsed >= nextPromptAt && !showOneMinutePrompt {
                    showOneMinutePrompt = true
                    nextPromptAt = interactionElapsed + 60
                }
            }
        }
    }

    private func stopTimer() {
        timerTask?.cancel()
        timerTask = nil
    }

    private func saveCurrentShift() {
        guard let data = try? JSONEncoder().encode(currentShift) else { return }
        UserDefaults.standard.set(data, forKey: Keys.currentShift)
    }

    private func savePastShifts() {
        guard let data = try? JSONEncoder().encode(pastShifts) else { return }
        UserDefaults.standard.set(data, forKey: Keys.pastShifts)
    }

    private func saveActiveInteraction() {
        guard let data = try? JSONEncoder().encode(activeInteraction) else { return }
        UserDefaults.standard.set(data, forKey: Keys.activeInteraction)
        UserDefaults.standard.set(interactionElapsed, forKey: Keys.interactionElapsed)
    }

    private func clearActiveInteraction() {
        UserDefaults.standard.removeObject(forKey: Keys.activeInteraction)
        UserDefaults.standard.removeObject(forKey: Keys.interactionElapsed)
    }

    private func load() {
        nightlyGoal = UserDefaults.standard.double(forKey: Keys.nightlyGoal)
        if nightlyGoal <= 0 { nightlyGoal = 400 }

        let savedManager = UserDefaults.standard.double(forKey: Keys.managerRate)
        managerRate = savedManager > 0 ? savedManager : 0.10

        let savedDJ = UserDefaults.standard.double(forKey: Keys.djRate)
        djRate = savedDJ > 0 ? savedDJ : 0.10

        let savedBouncerRate = UserDefaults.standard.double(forKey: Keys.bouncerRate)
        bouncerRate = savedBouncerRate > 0 ? savedBouncerRate : 0.05

        if let data  = UserDefaults.standard.data(forKey: Keys.currentShift),
           let shift = try? JSONDecoder().decode(Shift.self, from: data) {
            currentShift = shift
        }
        if !currentShift.isStarted { showStartShift = true }

        if let data    = UserDefaults.standard.data(forKey: Keys.pastShifts),
           let records = try? JSONDecoder().decode([ShiftRecord].self, from: data) {
            pastShifts = records
        }

        if let data        = UserDefaults.standard.data(forKey: Keys.activeInteraction),
           let interaction = try? JSONDecoder().decode(InteractionSession.self, from: data),
           interaction.isActive {
            activeInteraction  = interaction
            interactionElapsed = max(
                UserDefaults.standard.double(forKey: Keys.interactionElapsed),
                Date().timeIntervalSince(interaction.startTime)
            )
            nextPromptAt = ceil(interactionElapsed / 300) * 300 + 300
            startTimer()
        }
    }

    func updateGoal(_ goal: Double) {
        nightlyGoal = goal
        UserDefaults.standard.set(goal, forKey: Keys.nightlyGoal)
    }

    func updateManagerRate(_ rate: Double) {
        managerRate = rate
        UserDefaults.standard.set(rate, forKey: Keys.managerRate)
    }

    func updateDJRate(_ rate: Double) {
        djRate = rate
        UserDefaults.standard.set(rate, forKey: Keys.djRate)
    }

    func updateBouncerRate(_ rate: Double) {
        bouncerRate = rate
        UserDefaults.standard.set(rate, forKey: Keys.bouncerRate)
    }

    // MARK: - Outfit Session Management

    func startShift(session: OutfitSession) {
        currentShift.isStarted = true
        currentShift.outfitSessions.append(session)
        showStartShift = false
        saveCurrentShift()
    }

    func skipOutfitTracking() {
        currentShift.isStarted = true
        showStartShift = false
        saveCurrentShift()
    }

    func changeOutfit(endingComfortRating: Int, newSession: OutfitSession) {
        if let idx = currentShift.outfitSessions.indices.last(where: { currentShift.outfitSessions[$0].isActive }) {
            currentShift.outfitSessions[idx].endTime = Date()
            currentShift.outfitSessions[idx].comfortRating = endingComfortRating
        }
        currentShift.outfitSessions.append(newSession)
        saveCurrentShift()
    }

    // MARK: - Photo Helpers

    func saveOutfitPhoto(_ image: UIImage) -> String {
        let filename = "outfit_\(UUID().uuidString).jpg"
        if let data = image.jpegData(compressionQuality: 0.8) {
            let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(filename)
            try? data.write(to: url)
        }
        return filename
    }

    func loadOutfitPhoto(filename: String) -> UIImage? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        return UIImage(contentsOfFile: url.path)
    }
}
