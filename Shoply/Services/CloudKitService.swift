//
//  CloudKitService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import CloudKit
import Combine
import UIKit

/// Service de synchronisation CloudKit pour sauvegarder toutes les données dans iCloud
class CloudKitService: ObservableObject {
    static let shared = CloudKitService()
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    
    @Published var isSignedIn: Bool = false
    @Published var syncStatus: String = ""
    
    private init() {
        container = CKContainer.default()
        privateDatabase = container.privateCloudDatabase
        // Ne pas vérifier le statut iCloud au démarrage pour éviter les crashes
        // La vérification sera faite uniquement quand nécessaire (depuis SettingsScreen)
        // checkAccountStatus() - DÉSACTIVÉ pour éviter les crashes
    }
    
    // MARK: - Vérification du compte iCloud
    
    func checkIfDataExists() async throws -> Bool {
        // Vérifier si un profil utilisateur existe dans iCloud
        let recordID = CKRecord.ID(recordName: "userProfile")
        do {
            let _ = try await privateDatabase.record(for: recordID)
            return true // Des données existent
        } catch {
            if let ckError = error as? CKError, ckError.code == .unknownItem {
                return false // Aucune donnée
            }
            throw error
        }
    }
    
    func checkAccountStatus() {
        // Utiliser un timeout pour éviter que l'app reste bloquée
        container.accountStatus { [weak self] status, error in
            guard let self = self else { return }
            
            // Vérifier s'il y a une erreur
            if let error = error {
                print("⚠️ Erreur vérification statut iCloud: \(error.localizedDescription)")
                DispatchQueue.main.async {
                    self.isSignedIn = false
                }
                return
            }
            
            DispatchQueue.main.async {
                switch status {
                case .available:
                    self.isSignedIn = true
                    print("✅ iCloud disponible")
                case .noAccount:
                    self.isSignedIn = false
                    print("⚠️ Aucun compte iCloud")
                case .restricted:
                    self.isSignedIn = false
                    print("⚠️ Compte iCloud restreint")
                case .couldNotDetermine:
                    self.isSignedIn = false
                    print("⚠️ Statut iCloud indéterminé")
                case .temporarilyUnavailable:
                    self.isSignedIn = false
                    print("⚠️ Compte iCloud temporairement indisponible")
                @unknown default:
                    self.isSignedIn = false
                    print("⚠️ Statut iCloud inconnu")
                }
            }
        }
    }
    
    // MARK: - Sauvegarde des données utilisateur
    
    /// Sauvegarde complète de toutes les données utilisateur
    func syncAllUserData() async throws {
        // Vérifier le statut iCloud d'abord
        await MainActor.run {
            checkAccountStatus()
        }
        
        // Attendre un peu pour que le statut soit mis à jour
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 secondes
        
        // Vérifier le statut de connexion iCloud
        if !isSignedIn {
            // Si pas connecté, essayer de vérifier à nouveau
            await MainActor.run {
                checkAccountStatus()
            }
            try await Task.sleep(nanoseconds: 500_000_000)
            
            // Vérifier à nouveau après le délai
            guard isSignedIn else {
                throw CloudKitError.notSignedIn
            }
        }
        
        await MainActor.run {
            syncStatus = "Synchronisation en cours...".localized
        }
        
        do {
            // Sauvegarder le profil utilisateur
            try await saveUserProfile()
            
            // Sauvegarder la garde-robe
            try await saveWardrobe()
            
            // Sauvegarder les conversations IA
            try await saveConversations()
            
            // Sauvegarder l'historique des outfits
            try await saveOutfitHistory()
            
            // Sauvegarder les favoris
            try await saveFavorites()
            
            await MainActor.run {
                syncStatus = "Synchronisation terminée".localized
            }
            print("✅ Toutes les données ont été synchronisées avec succès dans iCloud")
        } catch {
            await MainActor.run {
                syncStatus = "Erreur de synchronisation: \(error.localizedDescription)".localized
            }
            throw error
        }
    }
    
    // MARK: - Profil utilisateur
    
    func saveUserProfile() async throws {
        guard let profile = DataManager.shared.loadUserProfile() else { return }
        
        let recordID = CKRecord.ID(recordName: "userProfile")
        let record = CKRecord(recordType: "UserProfile", recordID: recordID)
        
        record["firstName"] = profile.firstName
        record["age"] = profile.age
        record["gender"] = profile.gender.rawValue
        if let email = profile.email {
            record["email"] = email
        }
        record["createdAt"] = profile.createdAt
        record["preferences"] = try encodeJSON(profile.preferences)
        
        try await privateDatabase.save(record)
        print("✅ Profil sauvegardé dans iCloud")
    }
    
    func loadUserProfile() async throws -> UserProfile? {
        let recordID = CKRecord.ID(recordName: "userProfile")
        
        do {
            let record = try await privateDatabase.record(for: recordID)
            
            guard let firstName = record["firstName"] as? String,
                  let age = record["age"] as? Int,
                  let genderString = record["gender"] as? String,
                  let createdAt = record["createdAt"] as? Date else {
                return nil
            }
            
            let gender = Gender(rawValue: genderString) ?? .notSpecified
            let email = record["email"] as? String
            var preferences = UserPreferences()
            
            if let prefsData = record["preferences"] as? String,
               let prefsJson = prefsData.data(using: .utf8),
               let decoded = try? JSONDecoder().decode(UserPreferences.self, from: prefsJson) {
                preferences = decoded
            }
            
            return UserProfile(
                firstName: firstName,
                age: age,
                gender: gender,
                email: email,
                createdAt: createdAt,
                preferences: preferences
            )
        } catch {
            if let ckError = error as? CKError, ckError.code == .unknownItem {
                return nil // Pas encore de profil sauvegardé
            }
            throw error
        }
    }
    
    // MARK: - Garde-robe
    
    private func saveWardrobe() async throws {
        // Utiliser DataManager pour charger les items de la garde-robe
        let items = DataManager.shared.loadWardrobeItems()
        guard !items.isEmpty else { return }
        
        // Supprimer les anciens enregistrements
        try await deleteRecords(type: "WardrobeItem")
        
        // Sauvegarder chaque item
        for item in items {
            let recordID = CKRecord.ID(recordName: item.id.uuidString)
            let record = CKRecord(recordType: "WardrobeItem", recordID: recordID)
            
            record["name"] = item.name as CKRecordValue
            record["category"] = item.category.rawValue as CKRecordValue
            record["color"] = item.color as CKRecordValue
            record["material"] = (item.material ?? "") as CKRecordValue
            record["season"] = item.season.map { $0.rawValue } as CKRecordValue
            record["isFavorite"] = item.isFavorite as CKRecordValue
            record["createdAt"] = item.createdAt as CKRecordValue
            
            // Sauvegarder la photo en base64 si disponible
            if let photoURL = item.photoURL,
               let image = PhotoManager.shared.loadPhoto(at: photoURL),
               let imageData = image.jpegData(compressionQuality: 0.8) {
                record["photoData"] = CKAsset(fileURL: createTempFile(data: imageData, name: "\(item.id.uuidString).jpg"))
            }
            
            try await privateDatabase.save(record)
        }
        
        print("✅ \(items.count) vêtements sauvegardés dans iCloud")
    }
    
    func loadWardrobe() async throws -> [WardrobeItem] {
        let query = CKQuery(recordType: "WardrobeItem", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "createdAt", ascending: false)]
        
        let (matchResults, _) = try await privateDatabase.records(matching: query)
        
        var items: [WardrobeItem] = []
        
        for (_, result) in matchResults {
            do {
                let record = try result.get()
                guard let name = record["name"] as? String,
                      let categoryString = record["category"] as? String,
                      let color = record["color"] as? String,
                      let createdAt = record["createdAt"] as? Date else {
                    continue
                }
                
                guard let category = ClothingCategory(rawValue: categoryString) else {
                    continue
                }
                let material = record["material"] as? String
                let seasonsStrings = record["season"] as? [String] ?? []
                let seasons = seasonsStrings.compactMap { Season(rawValue: $0) }
                let isFavorite = record["isFavorite"] as? Bool ?? false
                
                var item = WardrobeItem(
                    name: name,
                    category: category,
                    color: color,
                    brand: nil,
                    season: seasons,
                    material: material
                )
                item.createdAt = createdAt
                item.isFavorite = isFavorite
                
                // Charger la photo si disponible
                if let photoAsset = record["photoData"] as? CKAsset,
                   let imageData = try? Data(contentsOf: photoAsset.fileURL!) {
                    if let image = UIImage(data: imageData) {
                        Task {
                            if let photoURL = try? await PhotoManager.shared.savePhoto(image, itemId: item.id) {
                                item.photoURL = photoURL
                            }
                        }
                    }
                }
                
                items.append(item)
            } catch {
                print("⚠️ Erreur chargement item: \(error)")
            }
        }
        
        print("✅ \(items.count) vêtements chargés depuis iCloud")
        return items
    }
    
    // MARK: - Conversations IA
    
    func saveConversations() async throws {
        guard let data = UserDefaults.standard.data(forKey: "chatConversations"),
              let conversations = try? JSONDecoder().decode([ChatConversation].self, from: data) else {
            return
        }
        
        // Supprimer les anciens enregistrements
        try await deleteRecords(type: "ChatConversation")
        
        for conversation in conversations {
            let recordID = CKRecord.ID(recordName: conversation.id.uuidString)
            let record = CKRecord(recordType: "ChatConversation", recordID: recordID)
            
            record["title"] = conversation.title as CKRecordValue
            record["messages"] = try encodeJSON(conversation.messages) as CKRecordValue
            record["createdAt"] = conversation.createdAt as CKRecordValue
            record["lastMessageAt"] = conversation.lastMessageAt as CKRecordValue
            record["aiMode"] = conversation.aiMode as CKRecordValue
            
            do {
                let savedRecord = try await privateDatabase.save(record)
                print("✅ Conversation sauvegardée: \(savedRecord.recordID)")
            } catch {
                print("⚠️ Erreur sauvegarde conversation \(conversation.id): \(error)")
                // Continuer avec les autres conversations même en cas d'erreur
            }
        }
        
        print("✅ \(conversations.count) conversations sauvegardées dans iCloud")
    }
    
    func loadConversations() async throws -> [ChatConversation] {
        let query = CKQuery(recordType: "ChatConversation", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "lastMessageAt", ascending: false)]
        
        let (matchResults, _) = try await privateDatabase.records(matching: query)
        
        var conversations: [ChatConversation] = []
        
        for (_, result) in matchResults {
            do {
                let record = try result.get()
                guard let title = record["title"] as? String,
                      let createdAt = record["createdAt"] as? Date,
                      let _ = record["lastMessageAt"] as? Date,
                      let aiMode = record["aiMode"] as? String,
                      let messagesData = record["messages"] as? String,
                      let messagesJson = messagesData.data(using: .utf8),
                      let messages = try? JSONDecoder().decode([ChatMessage].self, from: messagesJson) else {
                    continue
                }
                
                let conversation = ChatConversation(
                    id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
                    title: title,
                    messages: messages,
                    createdAt: createdAt,
                    aiMode: aiMode
                )
                conversations.append(conversation)
            } catch {
                print("⚠️ Erreur chargement conversation: \(error)")
            }
        }
        
        print("✅ \(conversations.count) conversations chargées depuis iCloud")
        return conversations
    }
    
    // MARK: - Historique des outfits
    
    private func saveOutfitHistory() async throws {
        // L'historique est géré par OutfitHistoryStore
        let historyStore = OutfitHistoryStore()
        let history = historyStore.outfits
        
        try await deleteRecords(type: "OutfitHistory")
        
        for historicalOutfit in history {
            let recordID = CKRecord.ID(recordName: historicalOutfit.id.uuidString)
            let record = CKRecord(recordType: "OutfitHistory", recordID: recordID)
            
            record["outfit"] = try encodeJSON(historicalOutfit.outfit) as CKRecordValue
            record["dateWorn"] = historicalOutfit.dateWorn as CKRecordValue
            record["isFavorite"] = historicalOutfit.isFavorite as CKRecordValue
            
            do {
                let savedRecord = try await privateDatabase.save(record)
                print("✅ Outfit historique sauvegardé: \(savedRecord.recordID)")
            } catch {
                print("⚠️ Erreur sauvegarde outfit historique \(historicalOutfit.id): \(error)")
                // Continuer avec les autres outfits même en cas d'erreur
            }
        }
        
        print("✅ \(history.count) outfits historiques sauvegardés dans iCloud")
    }
    
    func loadOutfitHistory() async throws -> [HistoricalOutfit] {
        let query = CKQuery(recordType: "OutfitHistory", predicate: NSPredicate(value: true))
        query.sortDescriptors = [NSSortDescriptor(key: "dateWorn", ascending: false)]
        
        let (matchResults, _) = try await privateDatabase.records(matching: query)
        
        var outfits: [HistoricalOutfit] = []
        
        for (_, result) in matchResults {
            do {
                let record = try result.get()
                guard let dateWorn = record["dateWorn"] as? Date,
                      let outfitData = record["outfit"] as? String,
                      let outfitJson = outfitData.data(using: .utf8),
                      let outfit = try? JSONDecoder().decode(MatchedOutfit.self, from: outfitJson) else {
                    continue
                }
                
                let isFavorite = record["isFavorite"] as? Bool ?? false
                let historicalOutfit = HistoricalOutfit(
                    id: UUID(uuidString: record.recordID.recordName) ?? UUID(),
                    outfit: outfit,
                    dateWorn: dateWorn,
                    isFavorite: isFavorite
                )
                outfits.append(historicalOutfit)
            } catch {
                print("⚠️ Erreur chargement historique: \(error)")
            }
        }
        
        return outfits
    }
    
    // MARK: - Favoris
    
    private func saveFavorites() async throws {
        let favorites = DataManager.shared.getAllFavorites()
        guard !favorites.isEmpty else {
            print("⚠️ Aucun favori à sauvegarder")
            return
        }
        
        let recordID = CKRecord.ID(recordName: "favorites")
        let record = CKRecord(recordType: "Favorites", recordID: recordID)
        
        record["outfitIds"] = favorites.map { $0.uuidString } as CKRecordValue
        
        do {
            let savedRecord = try await privateDatabase.save(record)
            print("✅ Favoris sauvegardés dans iCloud: \(savedRecord.recordID)")
        } catch {
            print("❌ Erreur sauvegarde favoris: \(error)")
            throw error
        }
    }
    
    // MARK: - Chargement complet
    
    func restoreAllData() async throws {
        guard isSignedIn else {
            throw CloudKitError.notSignedIn
        }
        
        // Charger et restaurer toutes les données
        if let profile = try await loadUserProfile() {
            DataManager.shared.saveUserProfile(profile)
        }
        
        let wardrobe = try await loadWardrobe()
        // Restaurer dans DataManager
        DataManager.shared.saveWardrobeItems(wardrobe)
        
        let conversations = try await loadConversations()
        // Restaurer dans UserDefaults
        if let data = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(data, forKey: "chatConversations")
        }
        
        // Restaurer l'historique des outfits
        let history = try await loadOutfitHistory()
        if let data = try? JSONEncoder().encode(history) {
            UserDefaults.standard.set(data, forKey: "historicalOutfits")
        }
        
        // Restaurer les favoris
        let favoritesRecordID = CKRecord.ID(recordName: "favorites")
        do {
            let record = try await privateDatabase.record(for: favoritesRecordID)
            if let outfitIds = record["outfitIds"] as? [String] {
                let favorites = outfitIds.compactMap { UUID(uuidString: $0) }
                let favoritesData = try JSONEncoder().encode(favorites.map { $0.uuidString })
                UserDefaults.standard.set(favoritesData, forKey: "favoriteOutfits")
            }
        } catch {
            // Pas de favoris sauvegardés, ce n'est pas grave
        }
        
        print("✅ Toutes les données restaurées depuis iCloud")
    }
    
    // MARK: - Helpers
    
    private func deleteRecords(type: String) async throws {
        let query = CKQuery(recordType: type, predicate: NSPredicate(value: true))
        let (matchResults, _) = try await privateDatabase.records(matching: query)
        
        let recordIDs = matchResults.compactMap { try? $0.1.get().recordID }
        
        if !recordIDs.isEmpty {
            _ = try await privateDatabase.modifyRecords(saving: [], deleting: recordIDs)
        }
    }
    
    private func encodeJSON<T: Codable>(_ value: T) throws -> String {
        let data = try JSONEncoder().encode(value)
        return String(data: data, encoding: .utf8) ?? ""
    }
    
    private func createTempFile(data: Data, name: String) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(name)
        try? data.write(to: fileURL)
        return fileURL
    }
}

enum CloudKitError: Error {
    case notSignedIn
    case syncFailed(String)
}

