//
//  IntegrationFlowsTests.swift
//  ShoplyTests
//
//  Tests d'intégration simples pour démontrer les flux de base.
//

import XCTest
@testable import Shoply

final class IntegrationFlowsTests: XCTestCase {
    
    func test_SQLite_Wardrobe_CRUD() throws {
        let sql = SQLDatabaseService.shared
        let id = UUID().uuidString
        XCTAssertTrue(sql.insertWardrobeItem(id: id, name: "T-shirt", category: "tops", color: "blue", createdAt: Date().timeIntervalSince1970))
        let list = sql.listWardrobeItems()
        XCTAssertTrue(list.contains(where: { $0["id"] == id }))
        XCTAssertTrue(sql.deleteWardrobeItem(id: id))
    }
    
    func test_NoSQL_SaveAndQuery() async throws {
        let nosql = NoSQLDatabaseService.shared
        let id = UUID().uuidString
        try await nosql.save(collection: "conversations", id: id, data: ["title": "Test", "owner": "user"])
        let fetched = try await nosql.fetch(collection: "conversations", id: id)
        XCTAssertNotNil(fetched)
        let query = try await nosql.query(collection: "conversations", whereKey: "owner", equals: "user")
        XCTAssertTrue(query.contains(where: { $0.id == id }))
        try await nosql.delete(collection: "conversations", id: id)
    }
}


