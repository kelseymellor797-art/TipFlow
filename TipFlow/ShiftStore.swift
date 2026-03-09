// ShiftStore.swift — TipFlow
// Central state manager. @Observable so SwiftUI views auto-update.
// Persists shift data to UserDefaults as JSON.

import Foundation
import Observation

@Observable
final class ShiftStore {

    // MARK: - Published State

    var currentShift: Shift = Shift()
    var pastShifts: [ShiftRecord] = []

    /// The live interaction being tracked (nil when none is active).
    var activeInteraction: InteractionSession?
    /// Seconds elapsed since the current interaction started.
    var interactionElapsed: TimeInterval = 0

    /// Drives the 1-minute check-in overlay.
    var showOneMinutePrompt: Bool = false
    /// Drives the end-interaction sheet from the overlay.
    var showEndInteractionSheet: Bool = false

    // MARK: - Settings

    var nightlyGoal: Double = 400
    var bouncerRate: Double = 0.05

    // MARK: - Private

    private var timerTask: Task<Void, Never>?
    /// Elapsed threshold at which the next prompt fires.
    private var nextPromptAt: TimeInterval = 60

    private enum Keys {
        static let currentShift        = "tipflow.currentShift"
        static let pastShifts          = "tipflow.pastShifts"
        static let nightlyGoal         = "tipflow.nightlyGoal"
        static let bouncerRate         = "tipflow.bouncerRate"
        static let activeInteraction   = "tipflow.activeInteraction"
        static let interactionElapsed  = "tipflow.interactionElapsed"
    }

    // MARK: - Init

    init() { load() }

    // MARK: - Earnings

    func logEarnings(type: EarningsType, amount: Double, interactionID: UUID? = nil) {
        let entry = EarningsEntry(type: type, amount: amount, interactionID: interactionID)
        currentShift.entries.append(entry)
        saveCurrentShift()
    }

    // MARK: - Interaction lifecycle

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

    /// Extend the timer — next prompt fires after `minutes` more minutes.
    func extendInteraction(by minutes: Int) {
        showOneMinutePrompt = false
        nextPromptAt = interactionElapsed + Double(minutes * 60)
    }

    /// Dismiss the prompt; re-prompt in another minute.
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
        activeInteraction   = nil
        interactionElapsed  = 0
        showOneMinutePrompt = false
        showEndInteractionSheet = false
        clearActiveInteraction()
        saveCurrentShift()
    }

    // MARK: - Shift management

    func endShift() {
        if activeInteraction != nil { endInteraction(outcome: .noSale, amount: nil) }
        let record = ShiftRecord(from: currentShift)
        pastShifts.insert(record, at: 0)
        currentShift = Shift()
        savePastShifts()
        saveCurrentShift()
    }

    // MARK: - Timer (Swift Concurrency)

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

    // MARK: - Persistence

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

        let savedBouncerRate = UserDefaults.standard.double(forKey: Keys.bouncerRate)
        bouncerRate = savedBouncerRate > 0 ? savedBouncerRate : 0.05

        if let data  = UserDefaults.standard.data(forKey: Keys.currentShift),
           let shift = try? JSONDecoder().decode(Shift.self, from: data) {
            currentShift = shift
        }

        if let data    = UserDefaults.standard.data(forKey: Keys.pastShifts),
           let records = try? JSONDecoder().decode([ShiftRecord].self, from: data) {
            pastShifts = records
        }

        // Restore mid-session interaction if the app was killed while one was active.
        if let data        = UserDefaults.standard.data(forKey: Keys.activeInteraction),
           let interaction = try? JSONDecoder().decode(InteractionSession.self, from: data),
           interaction.isActive {
            activeInteraction  = interaction
            // Use real elapsed time since startTime so the clock is accurate on restore.
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

    func updateBouncerRate(_ rate: Double) {
        bouncerRate = rate
        UserDefaults.standard.set(rate, forKey: Keys.bouncerRate)
    }
}
