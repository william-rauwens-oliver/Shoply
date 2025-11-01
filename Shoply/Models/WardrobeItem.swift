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
    var photoURL: String? // Chemin vers la photo
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
        self.createdAt = createdAt
        self.lastWorn = lastWorn
        self.wearCount = wearCount
        self.isFavorite = isFavorite
        self.tags = tags
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
        case .bottom: return "pants.fill"
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

