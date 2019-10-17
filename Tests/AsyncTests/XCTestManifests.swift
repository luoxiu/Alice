import XCTest

#if !canImport(ObjectiveC)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(FutureTests.allTests),
        testCase(OperatorsTests.allTests),
        testCase(AsyncTests.allTests)
    ]
}
#endif
