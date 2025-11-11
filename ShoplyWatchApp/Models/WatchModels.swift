//
//  WatchModels.swift
//  ShoplyWatchApp
//
//  Created by William on 01/11/2025.
//

import Foundation

// MARK: - Outfit Suggestion
struct WatchOutfitSuggestion: Identifiable, Codable {
    let id: UUID
    let title: String
    let description: String
    let items: [String]
    let style: String
    let weatherCondition: String?
    let timestamp: Date
    
    init(id: UUID = UUID(), title: String, description: String = "", items: [String] = [], style: String = "casual", weatherCondition: String? = nil, timestamp: Date = Date()) {
        self.id = id
        self.title = title
        self.description = description
        self.items = items
        self.style = style
        self.weatherCondition = weatherCondition
        self.timestamp = timestamp
    }
}

// MARK: - Weather
struct WatchWeather: Codable {
    let temperature: Double
    let condition: String
    let humidity: Double?
    let windSpeed: Double?
    let location: String?
    
    init(temperature: Double, condition: String, humidity: Double? = nil, windSpeed: Double? = nil, location: String? = nil) {
        self.temperature = temperature
        self.condition = condition
        self.humidity = humidity
        self.windSpeed = windSpeed
        self.location = location
    }
}

// MARK: - Chat Message
struct WatchChatMessage: Identifiable, Codable {
    let id: UUID
    let text: String
    let isUser: Bool
    let timestamp: Date
    
    init(id: UUID = UUID(), text: String, isUser: Bool, timestamp: Date = Date()) {
        self.id = id
        self.text = text
        self.isUser = isUser
        self.timestamp = timestamp
    }
}

// MARK: - Wardrobe Item
struct WatchWardrobeItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let category: WardrobeCategory
    let color: String?
    let brand: String?
    let isFavorite: Bool
    
    init(id: UUID = UUID(), name: String, category: WardrobeCategory, color: String? = nil, brand: String? = nil, isFavorite: Bool = false) {
        self.id = id
        self.name = name
        self.category = category
        self.color = color
        self.brand = brand
        self.isFavorite = isFavorite
    }
}

// MARK: - Wardrobe Category
enum WardrobeCategory: String, Codable, CaseIterable {
    case all = "all"
    case top = "top"
    case bottom = "bottom"
    case shoes = "shoes"
    case accessories = "accessories"
    
    var displayName: String {
        switch self {
        case .all: return "Tous"
        case .top: return "Hauts"
        case .bottom: return "Bas"
        case .shoes: return "Chaussures"
        case .accessories: return "Accessoires"
        }
    }
}

