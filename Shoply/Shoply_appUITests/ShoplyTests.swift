//
//  ShoplyTests.swift
//  ShoplyTests
//
//  Portable tests with conditional imports.
//

#if canImport(Testing)
import Testing
@testable import Shoply

@Suite("Shoply Unit Tests")
struct ShoplyTestsSuite {
    @Test("Example test")
    func example() async throws {
        #expect(true)
    }
}

#elseif canImport(XCTest)
import XCTest
@testable import Shoply

final class ShoplyTestsSuite: XCTestCase {
    func testExample() throws {
        XCTAssertTrue(true)
    }
}

#else
// Neither Testing nor XCTest available; define no-op to keep build green.
#endif
