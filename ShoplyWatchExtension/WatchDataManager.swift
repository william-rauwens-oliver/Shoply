//
//  WatchDataManager.swift
//  ShoplyWatchExtension
//
//  Created by William on 01/11/2025.
//
//  Gestionnaire de données pour Apple Watch
//  Synchronise les données depuis App Groups

import Foundation
import Combine

class WatchDataManager: ObservableObject {
    static let shared = WatchDataManager()
    
    @Published var historicalOutfits: [WatchHistoricalOutfit] = []
    @Published var favoriteOutfits: [WatchFavoriteOutfit] = []
    
    private let sharedDefaults = UserDefaults(suiteName: "group.William.Shoply")
    
    private init() {
        loadData()
        // Écouter les notifications de mise à jour
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(dataUpdated),
            name: .watchDataUpdated,
            object: nil
        )
    }
    
    func loadData() {
        loadHistory()
        loadFavorites()
    }
    
    private func loadHistory() {
        guard let sharedDefaults = sharedDefaults,
              let data = sharedDefaults.data(forKey: "historical_outfits"),
              let outfits = try? JSONDecoder().decode([WatchHistoricalOutfit].self, from: data) else {
            historicalOutfits = []
            return
        }
        
        DispatchQueue.main.async {
            self.historicalOutfits = outfits
        }
    }
    
    private func loadFavorites() {
        guard let sharedDefaults = sharedDefaults,
              let data = sharedDefaults.data(forKey: "favorite_outfits"),
              let outfits = try? JSONDecoder().decode([WatchFavoriteOutfit].self, from: data) else {
            favoriteOutfits = []
            return
        }
        
        DispatchQueue.main.async {
            self.favoriteOutfits = outfits
        }
    }
    
    @objc private func dataUpdated() {
        loadData()
    }
}

// MARK: - Models pour Apple Watch

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

// MARK: - Notification Names

extension Notification.Name {
    static let watchDataUpdated = Notification.Name("watchDataUpdated")
}

