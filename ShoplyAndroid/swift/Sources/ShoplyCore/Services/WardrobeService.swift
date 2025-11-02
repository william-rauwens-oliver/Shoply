//
//  WardrobeService.swift
//  ShoplyCore - Android Compatible
//
//  Service de gestion de la garde-robe - Compatible Android

import Foundation
#if canImport(Combine)
import Combine
#endif

// Note: ObservableObject nécessite Combine, mais sur Android on peut utiliser des callbacks

/// Service de gestion de la garde-robe - Compatible Android
public class WardrobeService {
    public static let shared = WardrobeService()
    
    public var items: [WardrobeItem] = []
    public var isLoading = false
    public var error: Error?
    
    private let dataManager = DataManager.shared
    
    private init() {
        loadItems()
    }
    
    // MARK: - CRUD Operations
    
    public func addItem(_ item: WardrobeItem) {
        items.append(item)
        saveItems()
    }
    
    public func updateItem(_ item: WardrobeItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            saveItems()
        }
    }
    
    public func deleteItem(_ item: WardrobeItem) {
        items.removeAll { $0.id == item.id }
        // Note: Photo deletion handled by Android side
        saveItems()
    }
    
    // MARK: - Recherche et filtrage
    
    public func getItemsByCategory(_ category: ClothingCategory) -> [WardrobeItem] {
        return items.filter { $0.category == category }
    }
    
    public func searchItems(query: String) -> [WardrobeItem] {
        guard !query.isEmpty else { return items }
        return items.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.color.localizedCaseInsensitiveContains(query) ||
            $0.brand?.localizedCaseInsensitiveContains(query) ?? false ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    // MARK: - Statistiques
    
    public func getWardrobeStats() -> WardrobeStats {
        let categories = Dictionary(grouping: items, by: { $0.category })
        var categoryCounts: [ClothingCategory: Int] = [:]
        
        for (category, items) in categories {
            categoryCounts[category] = items.count
        }
        
        return WardrobeStats(
            totalItems: items.count,
            categoryCounts: categoryCounts,
            favoriteItems: items.filter { $0.isFavorite }.count,
            totalPhotos: items.filter { $0.photoURL != nil }.count
        )
    }
    
    // MARK: - Persistance
    
    private func loadItems() {
        items = dataManager.loadWardrobeItems()
    }
    
    private func saveItems() {
        dataManager.saveWardrobeItems(items)
    }
}

public struct WardrobeStats {
    public let totalItems: Int
    public let categoryCounts: [ClothingCategory: Int]
    public let favoriteItems: Int
    public let totalPhotos: Int
    
    public init(totalItems: Int, categoryCounts: [ClothingCategory: Int], favoriteItems: Int, totalPhotos: Int) {
        self.totalItems = totalItems
        self.categoryCounts = categoryCounts
        self.favoriteItems = favoriteItems
        self.totalPhotos = totalPhotos
    }
}

