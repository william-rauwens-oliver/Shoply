//
//  TravelMode.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation

/// Mode voyage avec checklist
struct TravelPlan: Codable, Identifiable {
    let id: UUID
    var destination: String
    var startDate: Date
    var endDate: Date
    var duration: Int // En jours
    var weatherForecast: [DayWeather]
    var plannedOutfits: [PlannedOutfit]
    var checklist: [TravelChecklistItem]
    var notes: String?
    var createdAt: Date
    
    init(id: UUID = UUID(), destination: String, startDate: Date, endDate: Date, weatherForecast: [DayWeather] = [], plannedOutfits: [PlannedOutfit] = [], checklist: [TravelChecklistItem] = [], notes: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.duration = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        self.weatherForecast = weatherForecast
        self.plannedOutfits = plannedOutfits
        self.checklist = checklist
        self.notes = notes
        self.createdAt = createdAt
    }
}

struct DayWeather: Codable, Identifiable {
    let id: UUID
    let date: Date
    let temperature: Double
    let condition: String
    let icon: String
    
    init(id: UUID = UUID(), date: Date, temperature: Double, condition: String, icon: String) {
        self.id = id
        self.date = date
        self.temperature = temperature
        self.condition = condition
        self.icon = icon
    }
}

struct PlannedOutfit: Codable, Identifiable {
    let id: UUID
    let date: Date
    var itemIds: [UUID]
    var occasion: String?
    var notes: String?
    
    init(id: UUID = UUID(), date: Date, itemIds: [UUID] = [], occasion: String? = nil, notes: String? = nil) {
        self.id = id
        self.date = date
        self.itemIds = itemIds
        self.occasion = occasion
        self.notes = notes
    }
}

struct TravelChecklistItem: Codable, Identifiable {
    let id: UUID
    var item: String
    var category: ChecklistCategory
    var isChecked: Bool
    var quantity: Int?
    
    init(id: UUID = UUID(), item: String, category: ChecklistCategory, isChecked: Bool = false, quantity: Int? = nil) {
        self.id = id
        self.item = item
        self.category = category
        self.isChecked = isChecked
        self.quantity = quantity
    }
}

enum ChecklistCategory: String, Codable, CaseIterable {
    case clothing = "Vêtements"
    case accessories = "Accessoires"
    case toiletries = "Toilettes"
    case documents = "Documents"
    case electronics = "Électronique"
    case other = "Autre"
    
    var icon: String {
        switch self {
        case .clothing: return "tshirt.fill"
        case .accessories: return "bag.fill"
        case .toiletries: return "drop.fill"
        case .documents: return "doc.fill"
        case .electronics: return "iphone"
        case .other: return "ellipsis.circle.fill"
        }
    }
}

