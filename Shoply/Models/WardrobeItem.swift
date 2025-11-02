//
//  WardrobeItem.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import SwiftUI
import CoreData
import UIKit

/// Élément de garde-robe avec photo
struct WardrobeItem: Identifiable, Codable {
    let id: UUID
    var name: String
    var category: ClothingCategory
    var color: String
    var brand: String?
    var season: [Season]
    var material: String?
    var photoURL: String? // Chemin vers la photo (déprécié, utiliser photoURLs)
    var photoURLs: [String] // Chemins vers les photos (support multi-photos)
    var createdAt: Date
    var lastWorn: Date?
    var wearCount: Int
    var isFavorite: Bool
    var tags: [String]
    
    init(
        id: UUID = UUID(),
        name: String,
        category: ClothingCategory,
        color: String,
        brand: String? = nil,
        season: [Season] = [],
        material: String? = nil,
        photoURL: String? = nil,
        photoURLs: [String] = [],
        createdAt: Date = Date(),
        lastWorn: Date? = nil,
        wearCount: Int = 0,
        isFavorite: Bool = false,
        tags: [String] = []
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.color = color
        self.brand = brand
        self.season = season
        self.material = material
        self.photoURL = photoURL
        // Si photoURL existe mais photoURLs est vide, migrer vers photoURLs
        if let photoURL = photoURL, photoURLs.isEmpty {
            self.photoURLs = [photoURL]
        } else {
            self.photoURLs = photoURLs
        }
        // Mettre à jour photoURL pour compatibilité
        if !self.photoURLs.isEmpty && photoURL == nil {
            self.photoURL = self.photoURLs.first
        }
        self.createdAt = createdAt
        self.lastWorn = lastWorn
        self.wearCount = wearCount
        self.isFavorite = isFavorite
        self.tags = tags
    }
    
    // MARK: - Codable personnalisé pour compatibilité backward
    enum CodingKeys: String, CodingKey {
        case id, name, category, color, brand, season, material
        case photoURL, photoURLs
        case createdAt, lastWorn, wearCount, isFavorite, tags
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(ClothingCategory.self, forKey: .category)
        color = try container.decode(String.self, forKey: .color)
        brand = try container.decodeIfPresent(String.self, forKey: .brand)
        season = try container.decode([Season].self, forKey: .season)
        material = try container.decodeIfPresent(String.self, forKey: .material)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastWorn = try container.decodeIfPresent(Date.self, forKey: .lastWorn)
        wearCount = try container.decode(Int.self, forKey: .wearCount)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        tags = try container.decodeIfPresent([String].self, forKey: .tags) ?? []
        
        // Gérer photoURLs et photoURL pour compatibilité
        if let photoURLs = try? container.decode([String].self, forKey: .photoURLs) {
            self.photoURLs = photoURLs
            self.photoURL = photoURLs.first
        } else if let photoURL = try? container.decodeIfPresent(String.self, forKey: .photoURL), !photoURL.isEmpty {
            self.photoURL = photoURL
            self.photoURLs = [photoURL]
        } else {
            self.photoURL = nil
            self.photoURLs = []
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(category, forKey: .category)
        try container.encode(color, forKey: .color)
        try container.encodeIfPresent(brand, forKey: .brand)
        try container.encode(season, forKey: .season)
        try container.encodeIfPresent(material, forKey: .material)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(lastWorn, forKey: .lastWorn)
        try container.encode(wearCount, forKey: .wearCount)
        try container.encode(isFavorite, forKey: .isFavorite)
        try container.encode(tags, forKey: .tags)
        
        // Encoder photoURLs (priorité) et photoURL (compatibilité)
        if !photoURLs.isEmpty {
            try container.encode(photoURLs, forKey: .photoURLs)
            try container.encodeIfPresent(photoURLs.first, forKey: .photoURL)
        } else if let photoURL = photoURL {
            try container.encode([photoURL], forKey: .photoURLs)
            try container.encodeIfPresent(photoURL, forKey: .photoURL)
        }
    }
}

/// Catégorie de vêtement
enum ClothingCategory: String, Codable, CaseIterable, Identifiable {
    case top = "Haut"
    case bottom = "Bas"
    case shoes = "Chaussures"
    case outerwear = "Veste/Manteau"
    case accessory = "Accessoire"
    case underwear = "Sous-vêtements"
    case bag = "Sac"
    case jewelry = "Bijoux"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .top: return "tshirt.fill"
        case .bottom: return "rectangle.fill" // Icône pour les bas/pantalons
        case .shoes: return "shoe.fill"
        case .outerwear: return "wind"
        case .accessory: return "sparkles"
        case .underwear: return "circle.fill"
        case .bag: return "bag.fill"
        case .jewelry: return "star.fill"
        }
    }
}

enum Season: String, Codable, CaseIterable {
    case spring = "Printemps"
    case summer = "Été"
    case autumn = "Automne"
    case winter = "Hiver"
    case allSeason = "Toutes saisons"
}

/// Catégorie de niveau pour le matching
enum ClothingLevel: Int, Codable {
    case base = 1       // Sous-vêtements
    case bottom = 2     // Pantalon, jupe
    case top = 3        // T-shirt, chemise
    case outerwear = 4  // Veste, manteau
    case shoes = 5      // Chaussures
    case accessory = 6  // Accessoires
}

