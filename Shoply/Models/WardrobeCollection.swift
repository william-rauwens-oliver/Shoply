//
//  WardrobeCollection.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation

/// Collection/Thème de garde-robe
struct WardrobeCollection: Codable, Identifiable {
    let id: UUID
    var name: String
    var description: String
    var icon: String
    var color: String
    var itemIds: [UUID]
    var createdAt: Date
    var isDefault: Bool
    
    init(id: UUID = UUID(), name: String, description: String = "", icon: String = "folder.fill", color: String = "blue", itemIds: [UUID] = [], createdAt: Date = Date(), isDefault: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.color = color
        self.itemIds = itemIds
        self.createdAt = createdAt
        self.isDefault = isDefault
    }
}

/// Collections prédéfinies
enum PredefinedCollection: String, CaseIterable {
    case work = "Bureau"
    case weekend = "Week-end"
    case travel = "Voyage"
    case sport = "Sport"
    case evening = "Soirée"
    case casual = "Décontracté"
    
    var icon: String {
        switch self {
        case .work: return "briefcase.fill"
        case .weekend: return "calendar"
        case .travel: return "airplane"
        case .sport: return "figure.run"
        case .evening: return "moon.stars.fill"
        case .casual: return "tshirt.fill"
        }
    }
    
    var color: String {
        switch self {
        case .work: return "blue"
        case .weekend: return "green"
        case .travel: return "orange"
        case .sport: return "red"
        case .evening: return "purple"
        case .casual: return "gray"
        }
    }
}

