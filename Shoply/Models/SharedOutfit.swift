//
//  SharedOutfit.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation

/// Outfit partagé avec d'autres utilisateurs
struct SharedOutfit: Codable, Identifiable {
    let id: UUID
    let originalOutfitId: UUID
    var title: String
    var description: String?
    var itemIds: [UUID]
    var photos: [String]
    var sharedBy: String // Nom de l'utilisateur
    var sharedAt: Date
    var likes: Int
    var isPublic: Bool
    var tags: [String]
    
    init(id: UUID = UUID(), originalOutfitId: UUID, title: String, description: String? = nil, itemIds: [UUID], photos: [String] = [], sharedBy: String, sharedAt: Date = Date(), likes: Int = 0, isPublic: Bool = true, tags: [String] = []) {
        self.id = id
        self.originalOutfitId = originalOutfitId
        self.title = title
        self.description = description
        self.itemIds = itemIds
        self.photos = photos
        self.sharedBy = sharedBy
        self.sharedAt = sharedAt
        self.likes = likes
        self.isPublic = isPublic
        self.tags = tags
    }
}

