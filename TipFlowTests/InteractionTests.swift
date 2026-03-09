import XCTest
@testable import TipFlowModels

final class InteractionTests: XCTestCase {

    func testInteractionInitialization() {
        let interaction = Interaction()
        XCTAssertNotNil(interaction.id)
        XCTAssertNil(interaction.endTime)
        XCTAssertNil(interaction.outcome)
        XCTAssertEqual(interaction.earningsAmount, 0)
        XCTAssertTrue(interaction.isActive)
    }

    func testInteractionDurationWhileActive() {
        let start = Date().addingTimeInterval(-120) // 2 minutes ago
        let interaction = Interaction(startTime: start)
        XCTAssertGreaterThanOrEqual(interaction.duration, 119)
    }

    func testInteractionDurationWhenCompleted() {
        let start = Date().addingTimeInterval(-300)
        let end = Date().addingTimeInterval(-60)
        let interaction = Interaction(startTime: start, endTime: end)
        XCTAssertEqual(interaction.duration, 240, accuracy: 1)
        XCTAssertFalse(interaction.isActive)
    }

    func testInteractionCodable() throws {
        let interaction = Interaction(
            startTime: Date(),
            endTime: Date().addingTimeInterval(120),
            outcome: .oneDance,
            earningsAmount: 40
        )
        let data = try JSONEncoder().encode(interaction)
        let decoded = try JSONDecoder().decode(Interaction.self, from: data)
        XCTAssertEqual(decoded.id, interaction.id)
        XCTAssertEqual(decoded.outcome, .oneDance)
        XCTAssertEqual(decoded.earningsAmount, 40)
    }

    func testInteractionOutcomeAllCases() {
        XCTAssertEqual(InteractionOutcome.allCases.count, 5)
    }

    func testInteractionOutcomeRawValues() {
        XCTAssertEqual(InteractionOutcome.noSale.rawValue, "No Sale")
        XCTAssertEqual(InteractionOutcome.tipOnly.rawValue, "Tip Only")
        XCTAssertEqual(InteractionOutcome.oneDance.rawValue, "1 Dance")
        XCTAssertEqual(InteractionOutcome.multipleDances.rawValue, "Multiple Dances")
        XCTAssertEqual(InteractionOutcome.vipRoom.rawValue, "VIP / Room")
    }

    func testInteractionEquatable() {
        let id = UUID()
        let date = Date()
        let i1 = Interaction(id: id, startTime: date)
        let i2 = Interaction(id: id, startTime: date)
        XCTAssertEqual(i1, i2)
    }
}
