//
//  DataManager+WatchSync.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//
//  Extension pour synchroniser les données avec Apple Watch via App Groups

import Foundation

// Extension pour synchronisation Watch
extension DataManager {
    
    // MARK: - Synchronisation Apple Watch
    
    #if !WIDGET_EXTENSION
    /// Synchroniser les données avec Apple Watch via App Groups
    /// Implémentation complète pour l'app principale uniquement
    func syncToWatch() {
        // Synchroniser l'historique
        if let sharedDefaults = UserDefaults(suiteName: "group.William.Shoply") {
            let historyKey = "historicalOutfits"
            if let data = UserDefaults.standard.data(forKey: historyKey),
               let outfits = try? JSONDecoder().decode([ShoplyHistoricalOutfit].self, from: data) {
                let watchOutfits = outfits.map { outfit in
                    WatchHistoricalOutfit(
                        id: outfit.id.uuidString,
                        outfitName: outfit.outfit.displayName,
                        dateWorn: outfit.dateWorn,
                        mood: nil,
                        weather: outfit.outfit.weatherCondition.rawValue
                    )
                }
                if let encoded = try? JSONEncoder().encode(watchOutfits) {
                    sharedDefaults.set(encoded, forKey: "historical_outfits")
                    sharedDefaults.synchronize()
                    NotificationCenter.default.post(name: .watchDataUpdated, object: nil)
                }
            }
        }
        
        // Synchroniser les favoris
        if let sharedDefaults = UserDefaults(suiteName: "group.William.Shoply") {
            let favoriteIds = getAllFavorites()
            let watchFavorites = favoriteIds.map { uuid in
                WatchFavoriteOutfit(
                    id: uuid.uuidString,
                    name: "Outfit \(uuid.uuidString.prefix(8))",
                    description: nil,
                    createdAt: Date()
                )
            }
            if let encoded = try? JSONEncoder().encode(watchFavorites) {
                sharedDefaults.set(encoded, forKey: "favorite_outfits")
                sharedDefaults.synchronize()
                NotificationCenter.default.post(name: .watchDataUpdated, object: nil)
            }
        }
    }
    #endif
}

// MARK: - Models pour Apple Watch

#if !WIDGET_EXTENSION
struct WatchHistoricalOutfit: Identifiable, Codable {
    let id: String
    let outfitName: String
    let dateWorn: Date
    let mood: String?
    let weather: String?
}

struct WatchFavoriteOutfit: Identifiable, Codable {
    let id: String
    let name: String
    let description: String?
    let createdAt: Date
}

// MARK: - Models de données internes (référence aux modèles de l'app principale)

private struct ShoplyHistoricalOutfit: Codable {
    let id: UUID
    let outfit: MatchedOutfit
    let dateWorn: Date
    var isFavorite: Bool
}
#endif

// MARK: - Notification Names

extension Notification.Name {
    static let watchDataUpdated = Notification.Name("watchDataUpdated")
}

