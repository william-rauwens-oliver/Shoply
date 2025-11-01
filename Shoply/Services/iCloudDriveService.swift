//
//  iCloudDriveService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import Combine
import SwiftUI

/// Service de sauvegarde sur iCloud Drive
class iCloudDriveService: ObservableObject {
    static let shared = iCloudDriveService()
    
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: Error?
    
    private let fileManager = FileManager.default
    private let documentsURL: URL?
    
    private init() {
        // URL vers iCloud Drive
        documentsURL = fileManager.url(forUbiquityContainerIdentifier: nil)?
            .appendingPathComponent("Documents")
            .appendingPathComponent("ShoplyBackup")
        
        // Créer le dossier s'il n'existe pas
        if let url = documentsURL {
            try? fileManager.createDirectory(at: url, withIntermediateDirectories: true)
        }
    }
    
    // MARK: - Sauvegarde complète
    
    func backupAllData() async throws {
        await MainActor.run {
            isSyncing = true
            syncError = nil
        }
        
        guard let documentsURL = documentsURL else {
            throw iCloudError.noAccess
        }
        
        do {
            // 1. Sauvegarder le profil utilisateur
            if let profile = DataManager.shared.loadUserProfile() {
                try await saveProfile(profile, to: documentsURL)
            }
            
            // 2. Sauvegarder la garde-robe
            let wardrobeItems = DataManager.shared.loadWardrobeItems()
            try await saveWardrobe(wardrobeItems, to: documentsURL)
            
            // 3. Sauvegarder les photos (optionnel - peut être lourd)
            // try await savePhotos(to: documentsURL)
            
            // 4. Créer un fichier de métadonnées
            try await saveMetadata(to: documentsURL)
            
            await MainActor.run {
                lastSyncDate = Date()
                isSyncing = false
            }
        } catch {
            await MainActor.run {
                syncError = error
                isSyncing = false
            }
            throw error
        }
    }
    
    // MARK: - Restauration
    
    func restoreFromiCloud() async throws {
        await MainActor.run {
            isSyncing = true
            syncError = nil
        }
        
        guard let documentsURL = documentsURL else {
            throw iCloudError.noAccess
        }
        
        do {
            // 1. Restaurer le profil
            if let profile = try await loadProfile(from: documentsURL) {
                DataManager.shared.saveUserProfile(profile)
            }
            
            // 2. Restaurer la garde-robe
            if let wardrobeItems = try await loadWardrobe(from: documentsURL) {
                DataManager.shared.saveWardrobeItems(wardrobeItems)
            }
            
            await MainActor.run {
                lastSyncDate = Date()
                isSyncing = false
            }
        } catch {
            await MainActor.run {
                syncError = error
                isSyncing = false
            }
            throw error
        }
    }
    
    // MARK: - Méthodes privées
    
    private func saveProfile(_ profile: UserProfile, to url: URL) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(profile)
        let fileURL = url.appendingPathComponent("userProfile.json")
        try data.write(to: fileURL)
    }
    
    private func loadProfile(from url: URL) async throws -> UserProfile? {
        let fileURL = url.appendingPathComponent("userProfile.json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(UserProfile.self, from: data)
    }
    
    private func saveWardrobe(_ items: [WardrobeItem], to url: URL) async throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(items)
        let fileURL = url.appendingPathComponent("wardrobeItems.json")
        try data.write(to: fileURL)
    }
    
    private func loadWardrobe(from url: URL) async throws -> [WardrobeItem]? {
        let fileURL = url.appendingPathComponent("wardrobeItems.json")
        guard fileManager.fileExists(atPath: fileURL.path) else { return nil }
        let data = try Data(contentsOf: fileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode([WardrobeItem].self, from: data)
    }
    
    private func saveMetadata(to url: URL) async throws {
        let metadata: [String: Any] = [
            "version": "1.0.0",
            "lastBackup": Date().iso8601,
            "deviceName": UIDevice.current.name
        ]
        
        let data = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
        let fileURL = url.appendingPathComponent("metadata.json")
        try data.write(to: fileURL)
    }
    
    // MARK: - Vérification de disponibilité
    
    func isiCloudAvailable() -> Bool {
        return documentsURL != nil
    }
}

enum iCloudError: Error {
    case noAccess
    case fileNotFound
    case decodingError
    case encodingError
}

extension Date {
    var iso8601: String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: self)
    }
    
    init?(iso8601: String) {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: iso8601) else { return nil }
        self = date
    }
}

