//
//  DatabaseService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//
//  Service d'accès aux données SQL et NoSQL
//  Conforme aux exigences RNCP37873 - Bloc 2 : Développer des composants d'accès aux données SQL et NoSQL
//

import Foundation
import SQLite3
import CloudKit

/// Service de base de données SQL (SQLite) pour la persistance locale
class SQLDatabaseService {
    static let shared = SQLDatabaseService()
    
    private var db: OpaquePointer?
    private let dbPath: String
    
    private init() {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        dbPath = documentsPath.appendingPathComponent("shoply.db").path
        
        if sqlite3_open(dbPath, &db) != SQLITE_OK {
            print("❌ Erreur d'ouverture de la base de données SQLite")
        } else {
            createTables()
        }
    }
    
    // MARK: - CRUD Operations
    
    /// Créer les tables de la base de données
    private func createTables() {
        let createOutfitsTable = """
        CREATE TABLE IF NOT EXISTS outfits (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            description TEXT,
            mood TEXT,
            weather TEXT,
            outfit_type TEXT,
            created_at INTEGER,
            updated_at INTEGER
        );
        """
        
        let createFavoritesTable = """
        CREATE TABLE IF NOT EXISTS favorites (
            id TEXT PRIMARY KEY,
            outfit_id TEXT NOT NULL,
            user_id TEXT,
            created_at INTEGER,
            FOREIGN KEY (outfit_id) REFERENCES outfits(id)
        );
        """
        
        let createUserPreferencesTable = """
        CREATE TABLE IF NOT EXISTS user_preferences (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL,
            updated_at INTEGER
        );
        """
        
        executeSQL(createOutfitsTable)
        executeSQL(createFavoritesTable)
        executeSQL(createUserPreferencesTable)
    }
    
    /// Exécuter une requête SQL
    @discardableResult
    func executeSQL(_ sql: String) -> Bool {
        guard let db = db else { return false }
        
        var statement: OpaquePointer?
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        
        if let error = String(validatingUTF8: sqlite3_errmsg(db)) {
            print("❌ Erreur SQL: \(error)")
        }
        sqlite3_finalize(statement)
        return false
    }
    
    /// Insérer un outfit dans la base de données
    func insertOutfit(id: String, name: String, description: String?, mood: String?, weather: String?, outfitType: String?) -> Bool {
        let sql = """
        INSERT OR REPLACE INTO outfits (id, name, description, mood, weather, outfit_type, created_at, updated_at)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """
        
        guard let db = db else { return false }
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, (id as NSString).utf8String, -1, nil)
            sqlite3_bind_text(statement, 2, (name as NSString).utf8String, -1, nil)
            
            let descValue = (description ?? "") as NSString
            sqlite3_bind_text(statement, 3, descValue.utf8String, -1, nil)
            
            let moodValue = (mood ?? "") as NSString
            sqlite3_bind_text(statement, 4, moodValue.utf8String, -1, nil)
            
            let weatherValue = (weather ?? "") as NSString
            sqlite3_bind_text(statement, 5, weatherValue.utf8String, -1, nil)
            
            let outfitTypeValue = (outfitType ?? "") as NSString
            sqlite3_bind_text(statement, 6, outfitTypeValue.utf8String, -1, nil)
            
            let timestamp = Int(Date().timeIntervalSince1970)
            sqlite3_bind_int64(statement, 7, Int64(timestamp))
            sqlite3_bind_int64(statement, 8, Int64(timestamp))
            
            if sqlite3_step(statement) == SQLITE_DONE {
                sqlite3_finalize(statement)
                return true
            }
        }
        
        sqlite3_finalize(statement)
        return false
    }
    
    /// Récupérer tous les outfits
    func fetchAllOutfits() -> [[String: Any]] {
        let sql = "SELECT * FROM outfits ORDER BY created_at DESC"
        return executeQuery(sql)
    }
    
    /// Récupérer les outfits par critères
    func fetchOutfits(mood: String? = nil, weather: String? = nil) -> [[String: Any]] {
        var sql = "SELECT * FROM outfits WHERE 1=1"
        var conditions: [String] = []
        
        if let mood = mood {
            conditions.append("mood = '\(mood)'")
        }
        if let weather = weather {
            conditions.append("weather = '\(weather)'")
        }
        
        if !conditions.isEmpty {
            sql += " AND " + conditions.joined(separator: " AND ")
        }
        
        sql += " ORDER BY created_at DESC"
        return executeQuery(sql)
    }
    
    /// Exécuter une requête SELECT et retourner les résultats
    func executeQuery(_ sql: String) -> [[String: Any]] {
        guard let db = db else { return [] }
        
        var results: [[String: Any]] = []
        var statement: OpaquePointer?
        
        if sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK {
            while sqlite3_step(statement) == SQLITE_ROW {
                var row: [String: Any] = [:]
                let columnCount = sqlite3_column_count(statement)
                
                for i in 0..<columnCount {
                    let columnName = String(cString: sqlite3_column_name(statement, i))
                    
                    switch sqlite3_column_type(statement, i) {
                    case SQLITE_INTEGER:
                        row[columnName] = sqlite3_column_int64(statement, i)
                    case SQLITE_TEXT:
                        if let text = sqlite3_column_text(statement, i) {
                            row[columnName] = String(cString: text)
                        }
                    case SQLITE_NULL:
                        row[columnName] = NSNull()
                    default:
                        break
                    }
                }
                
                results.append(row)
            }
        }
        
        sqlite3_finalize(statement)
        return results
    }
    
    /// Ajouter un favori
    func addFavorite(outfitId: String, userId: String? = nil) -> Bool {
        let id = UUID().uuidString
        let timestamp = Int(Date().timeIntervalSince1970)
        
        let sql = """
        INSERT OR REPLACE INTO favorites (id, outfit_id, user_id, created_at)
        VALUES ('\(id)', '\(outfitId)', '\(userId ?? "default")', \(timestamp))
        """
        
        return executeSQL(sql)
    }
    
    /// Supprimer un favori
    func removeFavorite(outfitId: String) -> Bool {
        let sql = "DELETE FROM favorites WHERE outfit_id = '\(outfitId)'"
        return executeSQL(sql)
    }
    
    /// Récupérer tous les favoris
    func fetchFavorites() -> [[String: Any]] {
        let sql = """
        SELECT f.*, o.name, o.description 
        FROM favorites f
        LEFT JOIN outfits o ON f.outfit_id = o.id
        ORDER BY f.created_at DESC
        """
        return executeQuery(sql)
    }
    
    deinit {
        if let db = db {
            sqlite3_close(db)
        }
    }
}

/// Service de base de données NoSQL (CloudKit)
/// CloudKit est une base de données NoSQL orientée documents d'Apple
class NoSQLDatabaseService {
    static let shared = NoSQLDatabaseService()
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    
    private init() {
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
    }
    
    // MARK: - CloudKit (NoSQL) Operations
    
    /// Sauvegarder un document dans CloudKit (NoSQL)
    func saveDocument(_ document: [String: Any], recordType: String, completion: @escaping (Result<CKRecord, Error>) -> Void) {
        let record = CKRecord(recordType: recordType)
        
        for (key, value) in document {
            if let stringValue = value as? String {
                record[key] = stringValue as CKRecordValue
            } else if let intValue = value as? Int {
                record[key] = intValue as CKRecordValue
            } else if let dateValue = value as? Date {
                record[key] = dateValue as CKRecordValue
            } else if let dataValue = value as? Data {
                record[key] = dataValue as CKRecordValue
            }
        }
        
        privateDatabase.save(record) { savedRecord, error in
            if let error = error {
                completion(.failure(error))
            } else if let savedRecord = savedRecord {
                completion(.success(savedRecord))
            } else {
                completion(.failure(NSError(domain: "NoSQLDatabaseService", code: -1)))
            }
        }
    }
    
    /// Récupérer des documents depuis CloudKit (NoSQL)
    func fetchDocuments(recordType: String, predicate: NSPredicate? = nil, completion: @escaping (Result<[CKRecord], Error>) -> Void) {
        let query = CKQuery(recordType: recordType, predicate: predicate ?? NSPredicate(value: true))
        
        privateDatabase.perform(query, inZoneWith: nil) { records, error in
            if let error = error {
                completion(.failure(error))
            } else if let records = records {
                completion(.success(records))
            } else {
                completion(.success([]))
            }
        }
    }
    
    /// Supprimer un document de CloudKit (NoSQL)
    func deleteDocument(recordID: CKRecord.ID, completion: @escaping (Result<CKRecord.ID, Error>) -> Void) {
        privateDatabase.delete(withRecordID: recordID) { recordID, error in
            if let error = error {
                completion(.failure(error))
            } else if let recordID = recordID {
                completion(.success(recordID))
            } else {
                completion(.failure(NSError(domain: "NoSQLDatabaseService", code: -1)))
            }
        }
    }
    
    /// Mettre à jour un document dans CloudKit (NoSQL)
    func updateDocument(recordID: CKRecord.ID, fields: [String: Any], completion: @escaping (Result<CKRecord, Error>) -> Void) {
        privateDatabase.fetch(withRecordID: recordID) { record, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let record = record else {
                completion(.failure(NSError(domain: "NoSQLDatabaseService", code: -1)))
                return
            }
            
            for (key, value) in fields {
                if let stringValue = value as? String {
                    record[key] = stringValue as CKRecordValue
                } else if let intValue = value as? Int {
                    record[key] = intValue as CKRecordValue
                } else if let dateValue = value as? Date {
                    record[key] = dateValue as CKRecordValue
                }
            }
            
            self.privateDatabase.save(record) { savedRecord, error in
                if let error = error {
                    completion(.failure(error))
                } else if let savedRecord = savedRecord {
                    completion(.success(savedRecord))
                } else {
                    completion(.failure(NSError(domain: "NoSQLDatabaseService", code: -1)))
                }
            }
        }
    }
}

