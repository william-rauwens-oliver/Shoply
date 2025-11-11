//
//  SQLDatabaseService.swift
//  Shoply
//
//  Service SQLite optionnel pour démonstration RNCP37873 (Bloc 2.3/2.4)
//  Non activé en production; encapsule un CRUD minimal Wardrobe/Outfits.
//

import Foundation
import SQLite3

final class SQLDatabaseService {
    static let shared = SQLDatabaseService()
    
    private var db: OpaquePointer?
    private let queue = DispatchQueue(label: "sql-db-queue")
    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return dir.appendingPathComponent("shoply.sqlite")
    }()
    
    private init() {
        _ = openIfNeeded()
        _ = createTablesIfNeeded()
    }
    
    // MARK: - Core
    @discardableResult
    private func openIfNeeded() -> Bool {
        guard db == nil else { return true }
        var result = false
        queue.sync {
            if sqlite3_open(fileURL.path, &db) == SQLITE_OK {
                result = true
            } else {
                _ = close()
            }
        }
        return result
    }
    
    @discardableResult
    private func close() -> Bool {
        var result = false
        if let db {
            if sqlite3_close(db) == SQLITE_OK {
                self.db = nil
                result = true
            }
        }
        return result
    }
    
    // MARK: - Schema
    @discardableResult
    private func createTablesIfNeeded() -> Bool {
        let createWardrobe = """
        CREATE TABLE IF NOT EXISTS wardrobe_items (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            category TEXT,
            color TEXT,
            created_at DOUBLE NOT NULL
        );
        """
        let createOutfits = """
        CREATE TABLE IF NOT EXISTS outfits (
            id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            notes TEXT,
            created_at DOUBLE NOT NULL
        );
        """
        return execute(sql: createWardrobe) && execute(sql: createOutfits)
    }
    
    // MARK: - Exec helpers
    @discardableResult
    private func execute(sql: String, params: [String] = []) -> Bool {
        guard openIfNeeded(), let db else { return false }
        var ok = false
        queue.sync {
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                for (i, p) in params.enumerated() {
                    sqlite3_bind_text(stmt, Int32(i+1), (p as NSString).utf8String, -1, nil)
                }
                ok = sqlite3_step(stmt) == SQLITE_DONE
            }
            sqlite3_finalize(stmt)
        }
        return ok
    }
    
    private func query(sql: String, params: [String] = []) -> [[String: String]] {
        guard openIfNeeded(), let db else { return [] }
        var rows: [[String: String]] = []
        queue.sync {
            var stmt: OpaquePointer?
            if sqlite3_prepare_v2(db, sql, -1, &stmt, nil) == SQLITE_OK {
                for (i, p) in params.enumerated() {
                    sqlite3_bind_text(stmt, Int32(i+1), (p as NSString).utf8String, -1, nil)
                }
                while sqlite3_step(stmt) == SQLITE_ROW {
                    var row: [String: String] = [:]
                    for col in 0..<sqlite3_column_count(stmt) {
                        if let nameC = sqlite3_column_name(stmt, col) {
                            let name = String(cString: nameC)
                            if let textC = sqlite3_column_text(stmt, col) {
                                row[name] = String(cString: textC)
                            } else {
                                row[name] = ""
                            }
                        }
                    }
                    rows.append(row)
                }
            }
            sqlite3_finalize(stmt)
        }
        return rows
    }
    
    // MARK: - Public API (Wardrobe)
    @discardableResult
    func insertWardrobeItem(id: String, name: String, category: String?, color: String?, createdAt: TimeInterval) -> Bool {
        let sql = "INSERT OR REPLACE INTO wardrobe_items (id, name, category, color, created_at) VALUES (?, ?, ?, ?, ?);"
        return execute(sql: sql, params: [id, name, category ?? "", color ?? "", "\(createdAt)"])
    }
    
    func listWardrobeItems() -> [[String: String]] {
        query(sql: "SELECT * FROM wardrobe_items ORDER BY created_at DESC;")
    }
    
    @discardableResult
    func deleteWardrobeItem(id: String) -> Bool {
        execute(sql: "DELETE FROM wardrobe_items WHERE id = ?;", params: [id])
    }
    
    // MARK: - Public API (Outfits)
    @discardableResult
    func insertOutfit(id: String, title: String, notes: String?, createdAt: TimeInterval) -> Bool {
        let sql = "INSERT OR REPLACE INTO outfits (id, title, notes, created_at) VALUES (?, ?, ?, ?);"
        return execute(sql: sql, params: [id, title, notes ?? "", "\(createdAt)"])
    }
    
    func listOutfits() -> [[String: String]] {
        query(sql: "SELECT * FROM outfits ORDER BY created_at DESC;")
    }
    
    @discardableResult
    func deleteOutfit(id: String) -> Bool {
        execute(sql: "DELETE FROM outfits WHERE id = ?;", params: [id])
    }
}


