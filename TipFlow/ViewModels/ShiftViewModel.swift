import Foundation
import Combine

/// Main view model managing shift state, earnings tracking, and interaction timers.
class ShiftViewModel: ObservableObject {

    // MARK: - Published Properties

    @Published var currentShift: Shift
    @Published var activeInteraction: Interaction?
    @Published var interactionElapsedTime: TimeInterval = 0
    @Published var showInteractionPrompt: Bool = false
    @Published var showEndInteractionSheet: Bool = false
    @Published var showCustomAmountSheet: Bool = false

    // MARK: - Private Properties

    private var interactionTimer: Timer?
    private let persistence: PersistenceController

    // MARK: - Init

    init(persistence: PersistenceController = PersistenceController.shared) {
        self.persistence = persistence
        self.currentShift = persistence.loadCurrentShift() ?? Shift()
    }

    // MARK: - Earnings

    /// Add an earning entry to the current shift.
    func addEarning(amount: Double, category: EarningCategory) {
        let earning = Earning(amount: amount, category: category)
        currentShift.earnings.append(earning)
        saveShift()
    }

    // MARK: - Interaction Lifecycle

    /// Start a new customer interaction and begin the timer.
    func startInteraction() {
        let interaction = Interaction()
        activeInteraction = interaction
        interactionElapsedTime = 0
        showInteractionPrompt = false
        startInteractionTimer()
    }

    /// Extend the current interaction by dismissing the time prompt.
    func extendInteraction(minutes: Int) {
        showInteractionPrompt = false
    }

    /// Convert the current interaction directly to a dance.
    func convertToDance() {
        showInteractionPrompt = false
        showEndInteractionSheet = true
    }

    /// End the current interaction with an outcome and optional earnings.
    func endInteraction(outcome: InteractionOutcome, earningsAmount: Double = 0) {
        guard var interaction = activeInteraction else { return }
        interaction.endTime = Date()
        interaction.outcome = outcome
        interaction.earningsAmount = earningsAmount

        currentShift.interactions.append(interaction)

        if earningsAmount > 0 {
            let category: EarningCategory
            switch outcome {
            case .oneDance, .multipleDances, .vipRoom:
                category = .lapDance
            case .tipOnly:
                category = .randomTip
            case .noSale:
                category = .custom
            }
            if outcome != .noSale {
                addEarning(amount: earningsAmount, category: category)
            }
        }

        activeInteraction = nil
        interactionElapsedTime = 0
        showInteractionPrompt = false
        showEndInteractionSheet = false
        stopInteractionTimer()
        saveShift()
    }

    /// Cancel the current interaction without recording it.
    func cancelInteraction() {
        activeInteraction = nil
        interactionElapsedTime = 0
        showInteractionPrompt = false
        showEndInteractionSheet = false
        stopInteractionTimer()
    }

    // MARK: - Timer

    private func startInteractionTimer() {
        stopInteractionTimer()
        interactionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self, let interaction = self.activeInteraction else { return }
            self.interactionElapsedTime = Date().timeIntervalSince(interaction.startTime)

            if self.interactionElapsedTime >= 60 && !self.showInteractionPrompt {
                self.showInteractionPrompt = true
            }
        }
    }

    private func stopInteractionTimer() {
        interactionTimer?.invalidate()
        interactionTimer = nil
    }

    // MARK: - Analytics

    /// Average earnings per hour for the current shift.
    var averageEarningsPerHour: Double {
        let elapsed = Date().timeIntervalSince(currentShift.startTime) / 3600
        guard elapsed > 0 else { return 0 }
        return currentShift.totalEarnings / elapsed
    }

    /// Average duration of completed interactions.
    var averageInteractionLength: TimeInterval {
        let completed = currentShift.interactions.filter { $0.endTime != nil }
        guard !completed.isEmpty else { return 0 }
        let totalDuration = completed.reduce(0.0) { $0 + $1.duration }
        return totalDuration / Double(completed.count)
    }

    /// Progress toward the nightly earnings goal (0.0 to 1.0).
    var progressTowardGoal: Double {
        guard currentShift.goalAmount > 0 else { return 0 }
        return min(currentShift.totalEarnings / currentShift.goalAmount, 1.0)
    }

    // MARK: - Persistence

    func saveShift() {
        persistence.saveShift(currentShift)
    }

    /// Archive the current shift and start a new one.
    func startNewShift() {
        persistence.archiveShift(currentShift)
        currentShift = Shift()
        saveShift()
    }

    // MARK: - Formatting Helpers

    /// Format a time interval as mm:ss.
    static func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Format a dollar amount.
    static func formatCurrency(_ amount: Double) -> String {
        return String(format: "$%.0f", amount)
    }
}
