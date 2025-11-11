//
//  NoSQLDatabaseService.swift
//  Shoply
//
//  Service NoSQL optionnel (stubs) pour démonstration RNCP37873 (Bloc 2.4).
//  Non activé en production; interface simple inspirée de CloudKit.
//

import Foundation

final class NoSQLDatabaseService {
    static let shared = NoSQLDatabaseService()
    private init() {}
    
    struct Document: Codable {
        let id: String
        let collection: String
        let data: [String: String]
        let createdAt: Date
    }
    
    // Stockage en mémoire (démonstration)
    private var storage: [String: [String: Document]] = [:] // collection -> id -> doc
    private let queue = DispatchQueue(label: "nosql-db-queue")
    
    // MARK: - API
    func save(collection: String, id: String, data: [String: String]) async throws {
        let doc = Document(id: id, collection: collection, data: data, createdAt: Date())
        queue.sync {
            var col = storage[collection] ?? [:]
            col[id] = doc
            storage[collection] = col
        }
    }
    
    func fetch(collection: String, id: String) async throws -> Document? {
        var result: Document?
        queue.sync {
            result = storage[collection]?[id]
        }
        return result
    }
    
    func query(collection: String, whereKey: String? = nil, equals value: String? = nil) async throws -> [Document] {
        var all: [Document] = []
        queue.sync {
            if let col = storage[collection] {
                all = Array(col.values)
            } else {
                all = []
            }
        }
        guard let key = whereKey, let val = value else {
            return all.sorted { $0.createdAt > $1.createdAt }
        }
        return all.filter { $0.data[key] == val }.sorted { $0.createdAt > $1.createdAt }
    }
    
    func delete(collection: String, id: String) async throws {
        queue.sync {
            storage[collection]?[id] = nil
        }
    }
    
    func deleteCollection(_ collection: String) async throws {
        queue.sync {
            storage[collection] = [:]
        }
    }
}


