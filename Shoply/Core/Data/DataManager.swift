//
//  DataManager.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import CoreData
import SwiftUI
import Combine
#if !WIDGET_EXTENSION
import ObjectiveC
#endif

/// Gestionnaire de données - Couche d'accès aux données (DAL)
/// Implémente la persistance des données avec Core Data
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // MARK: - État de l'onboarding
    @Published var onboardingCompleted: Bool = false
    
    // MARK: - Core Data Stack
    // Core Data est optionnel - on utilise UserDefaults pour éviter les blocages
    lazy var persistentContainer: NSPersistentContainer? = {
        // Essayer de charger Core Data de manière asynchrone et non-bloquante
        // Si ça échoue, l'app continuera sans Core Data
        let container = NSPersistentContainer(name: "ShoplyDataModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                print("⚠️ Erreur de chargement Core Data: \(error.localizedDescription)")
                // L'app continuera sans Core Data
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var viewContext: NSManagedObjectContext? {
        return persistentContainer?.viewContext
    }
    
            // MARK: - Initialisation
    private init() {
        // Initialisation privée pour le singleton
        // Charger l'état initial de l'onboarding
        self.onboardingCompleted = hasCompletedOnboarding()
    }
    
    // Initialisation asynchrone pour éviter les blocages au démarrage
    func initializeIfNeeded() async {
        // Précharger le contexte Core Data de manière asynchrone
        // Ne fait rien de bloquant pour éviter les timeouts
        return
    }
    
    // MARK: - Méthodes de persistance
    func saveContext() {
        guard let context = viewContext, context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            let nsError = error as NSError
            // Ne pas crasher l'app, juste logger l'erreur
            print("⚠️ Erreur de sauvegarde Core Data: \(nsError), \(nsError.userInfo)")
        }
    }
    
    // MARK: - Gestion des favoris (RGPD compliant)
    // Utiliser UserDefaults comme fallback si Core Data n'est pas disponible
    private let favoritesKey = "favoriteOutfits"
    
    func addFavorite(outfitId: UUID) {
        var favorites = getFavoriteUUIDs()
        if !favorites.contains(outfitId) {
            favorites.append(outfitId)
            saveFavoriteUUIDs(favorites)
        }
    }
    
    func removeFavorite(outfitId: UUID) {
        var favorites = getFavoriteUUIDs()
        favorites.removeAll { $0 == outfitId }
        saveFavoriteUUIDs(favorites)
    }
    
    func isFavorite(outfitId: UUID) -> Bool {
        return getFavoriteUUIDs().contains(outfitId)
    }
    
    func getAllFavorites() -> [UUID] {
        return getFavoriteUUIDs()
    }
    
    private func getFavoriteUUIDs() -> [UUID] {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey),
              let uuids = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return uuids.compactMap { UUID(uuidString: $0) }
    }
    
    private func saveFavoriteUUIDs(_ uuids: [UUID]) {
        let strings = uuids.map { $0.uuidString }
        if let data = try? JSONEncoder().encode(strings) {
            UserDefaults.standard.set(data, forKey: favoritesKey)
        }
    }
    
    // MARK: - Gestion des préférences utilisateur (RGPD)
    func saveUserPreferences(mood: String?, weather: String?) {
        UserDefaults.standard.set(mood, forKey: "lastSelectedMood")
        UserDefaults.standard.set(weather, forKey: "lastSelectedWeather")
    }
    
    func getUserPreferences() -> (mood: String?, weather: String?) {
        return (
            mood: UserDefaults.standard.string(forKey: "lastSelectedMood"),
            weather: UserDefaults.standard.string(forKey: "lastSelectedWeather")
        )
    }
    
    // MARK: - Gestion du profil utilisateur
    func saveUserProfile(_ profile: UserProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
            // Notifier que l'onboarding est terminé
            DispatchQueue.main.async {
                self.onboardingCompleted = true
                self.objectWillChange.send()
            }
            // Synchroniser avec iCloud
            // La synchronisation est gérée manuellement depuis SettingsScreen
            // pour éviter les erreurs de compilation dans le widget extension
        }
    }
    
    func loadUserProfile() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: "userProfile"),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return nil
        }
        return profile
    }
    
    func hasCompletedOnboarding() -> Bool {
        let completed = loadUserProfile() != nil && !loadUserProfile()!.firstName.isEmpty
        // Synchroniser avec la propriété published
        if completed != onboardingCompleted {
            DispatchQueue.main.async {
                self.onboardingCompleted = completed
            }
        }
        return completed
    }
    
    // MARK: - Gestion de la garde-robe
    func saveWardrobeItems(_ items: [WardrobeItem]) {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "wardrobeItems")
        }
    }
    
    func loadWardrobeItems() -> [WardrobeItem] {
        guard let data = UserDefaults.standard.data(forKey: "wardrobeItems"),
              let items = try? JSONDecoder().decode([WardrobeItem].self, from: data) else {
            return []
        }
        return items
    }
    
    // MARK: - Export des données utilisateur (RGPD)
    func exportUserData() -> [String: Any] {
        var data: [String: Any] = [:]
        
        // Version du format d'export pour compatibilité future
        data["exportVersion"] = "1.0"
        data["exportDate"] = ISO8601DateFormatter().string(from: Date())
        
        // Favoris
        data["favorites"] = getAllFavorites().map { $0.uuidString }
        
        // Préférences
        let prefs = getUserPreferences()
        data["preferences"] = [
            "mood": prefs.mood ?? "",
            "weather": prefs.weather ?? ""
        ]
        
        // Profil utilisateur complet
        if let profile = loadUserProfile() {
            if let profileDict = try? encodeProfileToDict(profile) {
                data["profile"] = profileDict
            }
        }
        
        // Garde-robe complète
        let wardrobe = loadWardrobeItems()
        if let wardrobeData = try? JSONEncoder().encode(wardrobe),
           let wardrobeArray = try? JSONSerialization.jsonObject(with: wardrobeData) as? [[String: Any]] {
            data["wardrobe"] = wardrobeArray
        }
        data["wardrobeCount"] = wardrobe.count
        
        #if !WIDGET_EXTENSION
        // Conversations de chat
        if let conversationsData = UserDefaults.standard.data(forKey: "chatConversations") {
            // Utiliser AnyCodable pour éviter les problèmes de type dans le widget extension
            if let conversationsArray = try? JSONSerialization.jsonObject(with: conversationsData) as? [[String: Any]] {
                data["chatConversations"] = conversationsArray
            }
        }
        
        // Historique des outfits
        if let historyData = UserDefaults.standard.data(forKey: "historicalOutfits") {
            // Utiliser AnyCodable pour éviter les problèmes de type dans le widget extension
            if let historyArray = try? JSONSerialization.jsonObject(with: historyData) as? [[String: Any]] {
                data["historicalOutfits"] = historyArray
            }
        }
        #endif
        
        return data
    }
    
    // Helper pour encoder le profil en dictionnaire
    private func encodeProfileToDict(_ profile: UserProfile) throws -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["firstName"] = profile.firstName
        dict["age"] = profile.age
        dict["gender"] = profile.gender.rawValue
        if let email = profile.email {
            dict["email"] = email
        }
        dict["createdAt"] = ISO8601DateFormatter().string(from: profile.createdAt)
        if let lastWeatherUpdate = profile.lastWeatherUpdate {
            dict["lastWeatherUpdate"] = ISO8601DateFormatter().string(from: lastWeatherUpdate)
        }
        
        // Encoder les préférences
        if let prefsData = try? JSONEncoder().encode(profile.preferences),
           let prefsDict = try? JSONSerialization.jsonObject(with: prefsData) as? [String: Any] {
            dict["preferences"] = prefsDict
        }
        
        return dict
    }
    
    // MARK: - Import des données utilisateur
    func importUserData(from jsonData: Data) throws {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NSError(domain: "DataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Format JSON invalide"])
        }
        
        // Importer le profil
        if let profileDict = jsonObject["profile"] as? [String: Any] {
            if let profile = try? decodeProfileFromDict(profileDict) {
                saveUserProfile(profile)
            }
        }
        
        // Importer la garde-robe
        if let wardrobeArray = jsonObject["wardrobe"] as? [[String: Any]] {
            if let wardrobeData = try? JSONSerialization.data(withJSONObject: wardrobeArray),
               let wardrobe = try? JSONDecoder().decode([WardrobeItem].self, from: wardrobeData) {
                saveWardrobeItems(wardrobe)
            }
        }
        
        #if !WIDGET_EXTENSION
        // Importer les conversations
        if let conversationsArray = jsonObject["chatConversations"] as? [[String: Any]] {
            if let conversationsData = try? JSONSerialization.data(withJSONObject: conversationsArray) {
                UserDefaults.standard.set(conversationsData, forKey: "chatConversations")
            }
        }
        
        // Importer l'historique des outfits
        if let historyArray = jsonObject["historicalOutfits"] as? [[String: Any]] {
            if let historyData = try? JSONSerialization.data(withJSONObject: historyArray) {
                UserDefaults.standard.set(historyData, forKey: "historicalOutfits")
            }
        }
        #endif
        
        // Importer les favoris
        if let favoritesArray = jsonObject["favorites"] as? [String] {
            let favoriteUUIDs = favoritesArray.compactMap { UUID(uuidString: $0) }
            saveFavoriteUUIDs(favoriteUUIDs)
        }
        
        // Importer les préférences
        if let prefsDict = jsonObject["preferences"] as? [String: Any] {
            let mood = prefsDict["mood"] as? String
            let weather = prefsDict["weather"] as? String
            saveUserPreferences(mood: mood, weather: weather)
        }
        
        // Notifier le changement
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // Helper pour décoder le profil depuis un dictionnaire
    private func decodeProfileFromDict(_ dict: [String: Any]) throws -> UserProfile {
        let firstName = dict["firstName"] as? String ?? ""
        let age = dict["age"] as? Int ?? 0
        let genderString = dict["gender"] as? String ?? "Non spécifié"
        let gender = Gender(rawValue: genderString) ?? .notSpecified
        let email = dict["email"] as? String
        
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = (dict["createdAt"] as? String).flatMap { dateFormatter.date(from: $0) } ?? Date()
        let lastWeatherUpdate = (dict["lastWeatherUpdate"] as? String).flatMap { dateFormatter.date(from: $0) }
        
        var preferences = UserPreferences()
        if let prefsDict = dict["preferences"] as? [String: Any],
           let prefsData = try? JSONSerialization.data(withJSONObject: prefsDict),
           let decodedPrefs = try? JSONDecoder().decode(UserPreferences.self, from: prefsData) {
            preferences = decodedPrefs
        }
        
        return UserProfile(
            firstName: firstName,
            age: age,
            gender: gender,
            email: email,
            createdAt: createdAt,
            preferences: preferences
        )
    }
    
    // MARK: - Suppression des données utilisateur (RGPD)
    func deleteAllUserData() {
        // Supprimer tous les favoris
        UserDefaults.standard.removeObject(forKey: favoritesKey)
        
        // Supprimer les préférences
        UserDefaults.standard.removeObject(forKey: "lastSelectedMood")
        UserDefaults.standard.removeObject(forKey: "lastSelectedWeather")
        UserDefaults.standard.removeObject(forKey: "userProfile")
        UserDefaults.standard.removeObject(forKey: "wardrobeItems")
        
        // Supprimer les conversations de chat
        UserDefaults.standard.removeObject(forKey: "chatConversations")
        
        // Supprimer l'historique des outfits
        UserDefaults.standard.removeObject(forKey: "historicalOutfits")
        
        // Réinitialiser l'onboarding
        DispatchQueue.main.async {
            self.onboardingCompleted = false
            self.objectWillChange.send()
        }
    }
}

