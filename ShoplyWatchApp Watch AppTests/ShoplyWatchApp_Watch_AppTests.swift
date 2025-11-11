//
//  ShoplyWatchApp_Watch_AppTests.swift
//  ShoplyWatchApp Watch AppTests
//
//  Created by William on 11/11/2025.
//

#if canImport(XCTest)
import XCTest
@testable import ShoplyWatchApp_Watch_App

final class ShoplyWatchApp_Watch_AppTests: XCTestCase {

    func testExample() throws {
        // Write your test here and use APIs like `XCTAssert` to check expected conditions.
        XCTAssertTrue(true)
    }

}

#else
// XCTest non disponible - les tests ne peuvent pas s'exécuter
// Ce cas ne devrait normalement pas se produire pour watchOS
// Pas de warning car c'est normal pour certains targets watchOS
#endif
