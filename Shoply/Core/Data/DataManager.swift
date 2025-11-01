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

/// Gestionnaire de données - Couche d'accès aux données (DAL)
/// Implémente la persistance des données avec Core Data
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // MARK: - Core Data Stack
    // Core Data est optionnel - on utilise UserDefaults pour éviter les blocages
    lazy var persistentContainer: NSPersistentContainer? = {
        // Essayer de charger Core Data de manière asynchrone et non-bloquante
        // Si ça échoue, l'app continuera sans Core Data
        let container: NSPersistentContainer
        do {
            container = NSPersistentContainer(name: "ShoplyDataModel")
            container.loadPersistentStores { description, error in
                if let error = error {
                    print("⚠️ Erreur de chargement Core Data: \(error.localizedDescription)")
                    // L'app continuera sans Core Data
                }
            }
            container.viewContext.automaticallyMergesChangesFromParent = true
            return container
        } catch {
            print("⚠️ Impossible de créer le container Core Data: \(error)")
            return nil
        }
    }()
    
    var viewContext: NSManagedObjectContext? {
        return persistentContainer?.viewContext
    }
    
    // MARK: - Initialisation
    private init() {
        // Initialisation privée pour le singleton
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
        return loadUserProfile() != nil && !loadUserProfile()!.firstName.isEmpty
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
        
        // Favoris
        data["favorites"] = getAllFavorites().map { $0.uuidString }
        
        // Préférences
        let prefs = getUserPreferences()
        data["preferences"] = [
            "mood": prefs.mood ?? "",
            "weather": prefs.weather ?? ""
        ]
        
        // Profil utilisateur
        if let profile = loadUserProfile() {
            data["profile"] = [
                "firstName": profile.firstName,
                "age": profile.age,
                "gender": profile.gender.rawValue
            ]
        }
        
        // Garde-robe
        let wardrobe = loadWardrobeItems()
        data["wardrobeCount"] = wardrobe.count
        
        return data
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
    }
}

