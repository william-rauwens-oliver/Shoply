//
//  WishlistItem.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import SwiftUI

/// Élément de wishlist
struct WishlistItem: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String?
    var category: ClothingCategory
    var price: Double?
    var currency: String
    var storeURL: String?
    var imageURL: String?
    var priority: Priority
    var addedAt: Date
    var purchasedAt: Date?
    var notes: String?
    
    init(id: UUID = UUID(), name: String, description: String? = nil, category: ClothingCategory, price: Double? = nil, currency: String = "EUR", storeURL: String? = nil, imageURL: String? = nil, priority: Priority = .medium, addedAt: Date = Date(), purchasedAt: Date? = nil, notes: String? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.price = price
        self.currency = currency
        self.storeURL = storeURL
        self.imageURL = imageURL
        self.priority = priority
        self.addedAt = addedAt
        self.purchasedAt = purchasedAt
        self.notes = notes
    }
    
    var isPurchased: Bool {
        return purchasedAt != nil
    }
}

enum Priority: String, Codable, CaseIterable {
    case low = "Basse"
    case medium = "Moyenne"
    case high = "Haute"
    case urgent = "Urgente"
    
    var color: Color {
        switch self {
        case .low: return .gray
        case .medium: return .blue
        case .high: return .orange
        case .urgent: return .red
        }
    }
}

