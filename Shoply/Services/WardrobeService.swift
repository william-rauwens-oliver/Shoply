//
//  WardrobeService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import SwiftUI
import Combine
import PhotosUI

/// Service de gestion de la garde-robe
class WardrobeService: ObservableObject {
    @Published var items: [WardrobeItem] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let dataManager = DataManager.shared
    private let photoManager = PhotoManager.shared
    
    init() {
        loadItems()
    }
    
    // MARK: - CRUD Operations
    
    func addItem(_ item: WardrobeItem) {
        items.append(item)
        saveItems()
        // Forcer la mise à jour de la vue
        objectWillChange.send()
    }
    
    func updateItem(_ item: WardrobeItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            saveItems()
            // Forcer la mise à jour de la vue
            objectWillChange.send()
        }
    }
    
    func deleteItem(_ item: WardrobeItem) {
        items.removeAll { $0.id == item.id }
        // Supprimer aussi la photo
        if let photoURL = item.photoURL {
            photoManager.deletePhoto(at: photoURL)
        }
        saveItems()
    }
    
    // MARK: - Gestion des photos
    
    func savePhoto(_ photo: UIImage, for item: WardrobeItem) async throws -> String {
        let url = try await photoManager.savePhoto(photo, itemId: item.id)
        var updatedItem = item
        updatedItem.photoURL = url
        updateItem(updatedItem)
        return url
    }
    
    // MARK: - Recherche et filtrage
    
    func getItemsByCategory(_ category: ClothingCategory) -> [WardrobeItem] {
        return items.filter { $0.category == category }
    }
    
    func searchItems(query: String) -> [WardrobeItem] {
        guard !query.isEmpty else { return items }
        return items.filter {
            $0.name.localizedCaseInsensitiveContains(query) ||
            $0.color.localizedCaseInsensitiveContains(query) ||
            $0.brand?.localizedCaseInsensitiveContains(query) ?? false ||
            $0.tags.contains { $0.localizedCaseInsensitiveContains(query) }
        }
    }
    
    // MARK: - Statistiques
    
    func getWardrobeStats() -> WardrobeStats {
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

struct WardrobeStats {
    let totalItems: Int
    let categoryCounts: [ClothingCategory: Int]
    let favoriteItems: Int
    let totalPhotos: Int
}

