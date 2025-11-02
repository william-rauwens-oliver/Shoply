//
//  DataManager.swift
//  ShoplyCore - Android Compatible
//
//  Gestionnaire de données - Compatible Android (sans Core Data)

import Foundation
#if canImport(Combine)
import Combine
#endif

/// Gestionnaire de données - Compatible Android
/// Utilise UserDefaults/SharedPreferences au lieu de Core Data
public class DataManager {
    public static let shared = DataManager()
    
    public var onboardingCompleted: Bool = false
    
    // Note: Pour Android, UserDefaults sera mappé vers SharedPreferences via JNI
    
    private init() {
        self.onboardingCompleted = hasCompletedOnboarding()
    }
    
    // MARK: - Gestion des favoris
    
    private let favoritesKey = "favoriteOutfits"
    
    public func addFavorite(outfitId: UUID) {
        var favorites = getFavoriteUUIDs()
        if !favorites.contains(outfitId) {
            favorites.append(outfitId)
            saveFavoriteUUIDs(favorites)
        }
    }
    
    public func removeFavorite(outfitId: UUID) {
        var favorites = getFavoriteUUIDs()
        favorites.removeAll { $0 == outfitId }
        saveFavoriteUUIDs(favorites)
    }
    
    public func isFavorite(outfitId: UUID) -> Bool {
        return getFavoriteUUIDs().contains(outfitId)
    }
    
    public func getAllFavorites() -> [UUID] {
        return getFavoriteUUIDs()
    }
    
    private func getFavoriteUUIDs() -> [UUID] {
        // Pour Android, cette fonction sera remplacée par un appel JNI
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
    
    // MARK: - Gestion des préférences utilisateur
    
    public func saveUserPreferences(mood: String?, weather: String?) {
        UserDefaults.standard.set(mood, forKey: "lastSelectedMood")
        UserDefaults.standard.set(weather, forKey: "lastSelectedWeather")
    }
    
    public func getUserPreferences() -> (mood: String?, weather: String?) {
        return (
            mood: UserDefaults.standard.string(forKey: "lastSelectedMood"),
            weather: UserDefaults.standard.string(forKey: "lastSelectedWeather")
        )
    }
    
    // MARK: - Gestion du profil utilisateur
    
    public func saveUserProfile(_ profile: UserProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
            self.onboardingCompleted = true
        }
    }
    
    public func loadUserProfile() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: "userProfile"),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return nil
        }
        return profile
    }
    
    public func hasCompletedOnboarding() -> Bool {
        let completed = loadUserProfile() != nil && !loadUserProfile()!.firstName.isEmpty
        return completed
    }
    
    // MARK: - Gestion de la garde-robe
    
    public func saveWardrobeItems(_ items: [WardrobeItem]) {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "wardrobeItems")
        }
    }
    
    public func loadWardrobeItems() -> [WardrobeItem] {
        guard let data = UserDefaults.standard.data(forKey: "wardrobeItems"),
              let items = try? JSONDecoder().decode([WardrobeItem].self, from: data) else {
            return []
        }
        return items
    }
    
    // MARK: - Export des données utilisateur (RGPD)
    
    public func exportUserData() -> [String: Any] {
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
}
