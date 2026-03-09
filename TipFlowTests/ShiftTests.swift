import XCTest
@testable import TipFlowModels

final class ShiftTests: XCTestCase {

    func testShiftInitialization() {
        let shift = Shift()
        XCTAssertNotNil(shift.id)
        XCTAssertEqual(shift.earnings.count, 0)
        XCTAssertEqual(shift.interactions.count, 0)
        XCTAssertEqual(shift.goalAmount, 400)
        XCTAssertNil(shift.endTime)
    }

    func testTotalEarnings() {
        var shift = Shift()
        shift.earnings.append(Earning(amount: 20, category: .lapDance))
        shift.earnings.append(Earning(amount: 40, category: .lapDance))
        shift.earnings.append(Earning(amount: 5, category: .stageTip))
        XCTAssertEqual(shift.totalEarnings, 65)
    }

    func testLapDanceEarnings() {
        var shift = Shift()
        shift.earnings.append(Earning(amount: 20, category: .lapDance))
        shift.earnings.append(Earning(amount: 40, category: .lapDance))
        shift.earnings.append(Earning(amount: 5, category: .stageTip))
        XCTAssertEqual(shift.lapDanceEarnings, 60)
    }

    func testStageTipEarnings() {
        var shift = Shift()
        shift.earnings.append(Earning(amount: 5, category: .stageTip))
        shift.earnings.append(Earning(amount: 10, category: .stageTip))
        shift.earnings.append(Earning(amount: 20, category: .lapDance))
        XCTAssertEqual(shift.stageTipEarnings, 15)
    }

    func testRandomTipEarnings() {
        var shift = Shift()
        shift.earnings.append(Earning(amount: 20, category: .randomTip))
        shift.earnings.append(Earning(amount: 10, category: .randomTip))
        shift.earnings.append(Earning(amount: 5, category: .stageTip))
        XCTAssertEqual(shift.randomTipEarnings, 30)
    }

    func testConversionRateWithNoDanceConversions() {
        var shift = Shift()
        shift.interactions.append(
            Interaction(startTime: Date(), endTime: Date(), outcome: .noSale)
        )
        shift.interactions.append(
            Interaction(startTime: Date(), endTime: Date(), outcome: .tipOnly)
        )
        XCTAssertEqual(shift.conversionRate, 0)
    }

    func testConversionRateWithSomeDances() {
        var shift = Shift()
        shift.interactions.append(
            Interaction(startTime: Date(), endTime: Date(), outcome: .oneDance, earningsAmount: 20)
        )
        shift.interactions.append(
            Interaction(startTime: Date(), endTime: Date(), outcome: .noSale)
        )
        XCTAssertEqual(shift.conversionRate, 0.5, accuracy: 0.01)
    }

    func testConversionRateWithAllConversions() {
        var shift = Shift()
        shift.interactions.append(
            Interaction(startTime: Date(), endTime: Date(), outcome: .oneDance, earningsAmount: 20)
        )
        shift.interactions.append(
            Interaction(startTime: Date(), endTime: Date(), outcome: .multipleDances, earningsAmount: 80)
        )
        shift.interactions.append(
            Interaction(startTime: Date(), endTime: Date(), outcome: .vipRoom, earningsAmount: 200)
        )
        XCTAssertEqual(shift.conversionRate, 1.0, accuracy: 0.01)
    }

    func testConversionRateWithNoInteractions() {
        let shift = Shift()
        XCTAssertEqual(shift.conversionRate, 0)
    }

    func testConversionRateIgnoresActiveInteractions() {
        var shift = Shift()
        // Active interaction (no endTime) - should be ignored
        shift.interactions.append(Interaction(startTime: Date()))
        // Completed interaction with dance
        shift.interactions.append(
            Interaction(startTime: Date(), endTime: Date(), outcome: .oneDance, earningsAmount: 20)
        )
        XCTAssertEqual(shift.conversionRate, 1.0, accuracy: 0.01)
    }

    func testInteractionCount() {
        var shift = Shift()
        XCTAssertEqual(shift.interactionCount, 0)
        shift.interactions.append(Interaction())
        shift.interactions.append(Interaction())
        XCTAssertEqual(shift.interactionCount, 2)
    }

    func testShiftCodable() throws {
        var shift = Shift(goalAmount: 500)
        shift.earnings.append(Earning(amount: 20, category: .lapDance))
        shift.interactions.append(
            Interaction(startTime: Date(), endTime: Date(), outcome: .oneDance, earningsAmount: 20)
        )

        let data = try JSONEncoder().encode(shift)
        let decoded = try JSONDecoder().decode(Shift.self, from: data)

        XCTAssertEqual(decoded.id, shift.id)
        XCTAssertEqual(decoded.goalAmount, 500)
        XCTAssertEqual(decoded.earnings.count, 1)
        XCTAssertEqual(decoded.interactions.count, 1)
        XCTAssertEqual(decoded.totalEarnings, 20)
    }

    func testCustomGoalAmount() {
        let shift = Shift(goalAmount: 600)
        XCTAssertEqual(shift.goalAmount, 600)
    }

    func testEmptyShiftTotals() {
        let shift = Shift()
        XCTAssertEqual(shift.totalEarnings, 0)
        XCTAssertEqual(shift.lapDanceEarnings, 0)
        XCTAssertEqual(shift.stageTipEarnings, 0)
        XCTAssertEqual(shift.randomTipEarnings, 0)
    }
}
