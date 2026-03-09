import XCTest
@testable import TipFlowModels

final class EarningTests: XCTestCase {

    func testEarningInitialization() {
        let earning = Earning(amount: 20, category: .lapDance)
        XCTAssertEqual(earning.amount, 20)
        XCTAssertEqual(earning.category, .lapDance)
        XCTAssertNotNil(earning.id)
    }

    func testEarningCodable() throws {
        let earning = Earning(amount: 40, category: .stageTip)
        let data = try JSONEncoder().encode(earning)
        let decoded = try JSONDecoder().decode(Earning.self, from: data)
        XCTAssertEqual(decoded.id, earning.id)
        XCTAssertEqual(decoded.amount, earning.amount)
        XCTAssertEqual(decoded.category, earning.category)
    }

    func testEarningCategoryRawValues() {
        XCTAssertEqual(EarningCategory.lapDance.rawValue, "Lap Dance")
        XCTAssertEqual(EarningCategory.stageTip.rawValue, "Stage Tip")
        XCTAssertEqual(EarningCategory.randomTip.rawValue, "Random Tip")
        XCTAssertEqual(EarningCategory.custom.rawValue, "Custom")
    }

    func testEarningCategoryAllCases() {
        XCTAssertEqual(EarningCategory.allCases.count, 4)
    }

    func testEarningEquatable() {
        let id = UUID()
        let date = Date()
        let e1 = Earning(id: id, amount: 20, category: .lapDance, timestamp: date)
        let e2 = Earning(id: id, amount: 20, category: .lapDance, timestamp: date)
        XCTAssertEqual(e1, e2)
    }
}
