import XCTest

import AsyncTests

var tests = [XCTestCaseEntry]()
tests += AsyncTests.allTests()
XCTMain(tests)
