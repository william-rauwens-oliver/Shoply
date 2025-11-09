//
//  WishlistService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import Combine

/// Service de gestion de la wishlist
class WishlistService: ObservableObject {
    static let shared = WishlistService()
    
    @Published var items: [WishlistItem] = []
    
    private init() {
        loadWishlist()
    }
    
    // MARK: - Gestion des Items
    
    func addItem(_ item: WishlistItem) {
        items.append(item)
        saveWishlist()
    }
    
    func updateItem(_ item: WishlistItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index] = item
            saveWishlist()
        }
    }
    
    func deleteItem(_ item: WishlistItem) {
        items.removeAll { $0.id == item.id }
        saveWishlist()
    }
    
    func markAsPurchased(_ item: WishlistItem) {
        if let index = items.firstIndex(where: { $0.id == item.id }) {
            items[index].purchasedAt = Date()
            saveWishlist()
        }
    }
    
    func getUnpurchasedItems() -> [WishlistItem] {
        return items.filter { !$0.isPurchased }
    }
    
    func getItemsByPriority(_ priority: Priority) -> [WishlistItem] {
        return items.filter { $0.priority == priority && !$0.isPurchased }
    }
    
    // MARK: - Suggestions
    
    /// Suggère des items manquants dans la garde-robe
    func suggestMissingItems(wardrobeItems: [WardrobeItem]) -> [WishlistItem] {
        var suggestions: [WishlistItem] = []
        
        let categories = Set(wardrobeItems.map { $0.category })
        let allCategories = ClothingCategory.allCases
        
        // Suggérer des catégories manquantes
        for category in allCategories {
            if !categories.contains(category) {
                let suggestion = WishlistItem(
                    name: "Nouveau \(category.rawValue)",
                    description: "Complétez votre garde-robe avec un \(category.rawValue.lowercased())",
                    category: category,
                    priority: .medium
                )
                suggestions.append(suggestion)
            }
        }
        
        return suggestions
    }
    
    // MARK: - Persistance
    
    private func saveWishlist() {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "wishlist_items")
        }
    }
    
    private func loadWishlist() {
        if let data = UserDefaults.standard.data(forKey: "wishlist_items"),
           let decoded = try? JSONDecoder().decode([WishlistItem].self, from: data) {
            items = decoded
        }
    }
}

