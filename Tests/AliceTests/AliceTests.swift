import XCTest
@testable import Alice

final class AliceTests: XCTestCase {
    func testExample() {
        XCTAssertEqual(Alice.version, "0.0.1")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
