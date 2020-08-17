import XCTest

import PersistentStateTests

var tests = [XCTestCaseEntry]()
tests += PersistentStateTests.allTests()
XCTMain(tests)
