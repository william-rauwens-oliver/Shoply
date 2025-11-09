//
//  Lookbook.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import UIKit

/// Lookbook PDF exportable
struct Lookbook: Codable, Identifiable {
    let id: UUID
    var title: String
    var description: String?
    var outfits: [LookbookOutfit]
    var coverImageURL: String?
    var createdAt: Date
    var theme: LookbookTheme
    
    enum LookbookTheme: String, Codable, CaseIterable {
        case minimal = "Minimal"
        case elegant = "Élégant"
        case casual = "Décontracté"
        case seasonal = "Saisonnier"
        case professional = "Professionnel"
        
        var colorScheme: (primary: String, secondary: String) {
            switch self {
            case .minimal: return ("#FFFFFF", "#000000")
            case .elegant: return ("#2C2C2C", "#D4AF37")
            case .casual: return ("#F5F5F5", "#4A90E2")
            case .seasonal: return ("#FFE5B4", "#8B4513")
            case .professional: return ("#1A1A1A", "#C0C0C0")
            }
        }
    }
    
    init(id: UUID = UUID(), title: String, description: String? = nil, outfits: [LookbookOutfit] = [], coverImageURL: String? = nil, createdAt: Date = Date(), theme: LookbookTheme = .minimal) {
        self.id = id
        self.title = title
        self.description = description
        self.outfits = outfits
        self.coverImageURL = coverImageURL
        self.createdAt = createdAt
        self.theme = theme
    }
}

struct LookbookOutfit: Codable, Identifiable {
    let id: UUID
    let outfitId: UUID
    var photos: [String] // URLs des photos
    var title: String
    var description: String?
    var occasion: String?
    var items: [LookbookItem]
    
    init(id: UUID = UUID(), outfitId: UUID, photos: [String] = [], title: String, description: String? = nil, occasion: String? = nil, items: [LookbookItem] = []) {
        self.id = id
        self.outfitId = outfitId
        self.photos = photos
        self.title = title
        self.description = description
        self.occasion = occasion
        self.items = items
    }
}

struct LookbookItem: Codable {
    let itemId: UUID
    let name: String
    let category: String
    let color: String
    let brand: String?
}

