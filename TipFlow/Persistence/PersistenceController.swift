import Foundation

/// Handles local JSON-based persistence for shifts using UserDefaults.
class PersistenceController {
    static let shared = PersistenceController()

    private let currentShiftKey = "com.tipflow.currentShift"
    private let shiftHistoryKey = "com.tipflow.shiftHistory"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init() {}

    // MARK: - Current Shift

    func saveShift(_ shift: Shift) {
        if let data = try? encoder.encode(shift) {
            UserDefaults.standard.set(data, forKey: currentShiftKey)
        }
    }

    func loadCurrentShift() -> Shift? {
        guard let data = UserDefaults.standard.data(forKey: currentShiftKey),
              let shift = try? decoder.decode(Shift.self, from: data) else {
            return nil
        }
        return shift
    }

    func clearCurrentShift() {
        UserDefaults.standard.removeObject(forKey: currentShiftKey)
    }

    // MARK: - Shift History

    func archiveShift(_ shift: Shift) {
        var history = loadShiftHistory()
        var archivedShift = shift
        archivedShift.endTime = Date()
        history.append(archivedShift)
        if let data = try? encoder.encode(history) {
            UserDefaults.standard.set(data, forKey: shiftHistoryKey)
        }
    }

    func loadShiftHistory() -> [Shift] {
        guard let data = UserDefaults.standard.data(forKey: shiftHistoryKey),
              let shifts = try? decoder.decode([Shift].self, from: data) else {
            return []
        }
        return shifts
    }

    func clearShiftHistory() {
        UserDefaults.standard.removeObject(forKey: shiftHistoryKey)
    }
}
