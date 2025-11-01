//
//  Shoply_appTests.swift
//  ShoplyTests
//
//  Portable tests with conditional imports.
//

#if canImport(Testing)
import Testing
@testable import Shoply

@Suite("Additional Shoply Unit Tests")
struct ShoplyAdditionalTestsSuite {
    @Test("Sanity check")
    func sanity() async throws {
        #expect(2 + 2 == 4)
    }
}

#elseif canImport(XCTest)
import XCTest
@testable import Shoply

final class ShoplyAdditionalTestsSuite: XCTestCase {
    func testSanity() throws {
        XCTAssertEqual(2 + 2, 4)
    }
}

#else
// Neither Testing nor XCTest available; define no-op to keep build green.
#endif
