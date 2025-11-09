//
//  WardrobeCollectionService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import Combine

/// Service de gestion des collections de garde-robe
class WardrobeCollectionService: ObservableObject {
    static let shared = WardrobeCollectionService()
    
    @Published var collections: [WardrobeCollection] = []
    
    private let wardrobeService = WardrobeService()
    
    private init() {
        loadCollections()
        initializeDefaultCollections()
    }
    
    // MARK: - Collections
    
    func addCollection(_ collection: WardrobeCollection) {
        collections.append(collection)
        saveCollections()
    }
    
    func updateCollection(_ collection: WardrobeCollection) {
        if let index = collections.firstIndex(where: { $0.id == collection.id }) {
            collections[index] = collection
            saveCollections()
        }
    }
    
    func deleteCollection(_ collection: WardrobeCollection) {
        collections.removeAll { $0.id == collection.id }
        saveCollections()
    }
    
    func addItemToCollection(itemId: UUID, collectionId: UUID) {
        if let index = collections.firstIndex(where: { $0.id == collectionId }) {
            if !collections[index].itemIds.contains(itemId) {
                collections[index].itemIds.append(itemId)
                saveCollections()
            }
        }
    }
    
    func removeItemFromCollection(itemId: UUID, collectionId: UUID) {
        if let index = collections.firstIndex(where: { $0.id == collectionId }) {
            collections[index].itemIds.removeAll { $0 == itemId }
            saveCollections()
        }
    }
    
    func getItemsForCollection(_ collection: WardrobeCollection) -> [WardrobeItem] {
        let allItems = wardrobeService.items
        return allItems.filter { collection.itemIds.contains($0.id) }
    }
    
    // MARK: - Collections Prédéfinies
    
    private func initializeDefaultCollections() {
        // Créer les collections prédéfinies si elles n'existent pas
        for predefined in PredefinedCollection.allCases {
            if !collections.contains(where: { $0.name == predefined.rawValue && $0.isDefault }) {
                let collection = WardrobeCollection(
                    name: predefined.rawValue,
                    description: "Collection \(predefined.rawValue)",
                    icon: predefined.icon,
                    color: predefined.color,
                    isDefault: true
                )
                collections.append(collection)
            }
        }
        saveCollections()
    }
    
    // MARK: - Persistance
    
    private func saveCollections() {
        if let encoded = try? JSONEncoder().encode(collections) {
            UserDefaults.standard.set(encoded, forKey: "wardrobe_collections")
        }
    }
    
    private func loadCollections() {
        if let data = UserDefaults.standard.data(forKey: "wardrobe_collections"),
           let decoded = try? JSONDecoder().decode([WardrobeCollection].self, from: data) {
            collections = decoded
        }
    }
}

