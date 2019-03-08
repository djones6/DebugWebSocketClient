import XCTest

#if !os(macOS)
public func allTests() -> [XCTestCaseEntry] {
    return [
        testCase(kitura_helloworld_clientTests.allTests),
    ]
}
#endif