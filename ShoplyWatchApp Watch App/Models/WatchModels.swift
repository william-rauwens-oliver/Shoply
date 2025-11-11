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

// MARK: - Outfit History Item
struct WatchOutfitHistoryItem: Identifiable, Codable {
    let id: UUID
    let date: Date
    let items: [String]
    let isFavorite: Bool
    let style: String?
    
    init(id: UUID = UUID(), date: Date, items: [String], isFavorite: Bool = false, style: String? = nil) {
        self.id = id
        self.date = date
        self.items = items
        self.isFavorite = isFavorite
        self.style = style
    }
}

// MARK: - Wishlist Item
struct WatchWishlistItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let price: Double?
    let priority: Int?
    let notes: String?
    let createdAt: Date
    
    init(id: UUID = UUID(), name: String, price: Double? = nil, priority: Int? = nil, notes: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.name = name
        self.price = price
        self.priority = priority
        self.notes = notes
        self.createdAt = createdAt
    }
}

// MARK: - User Profile (simplified for Watch)
struct WatchUserProfile: Codable {
    let firstName: String
    let isConfigured: Bool
    
    init(firstName: String = "", isConfigured: Bool = false) {
        self.firstName = firstName
        self.isConfigured = isConfigured
    }
}

// MARK: - Chat Conversation
struct WatchChatConversation: Identifiable, Codable {
    let id: UUID
    let title: String
    let lastMessage: String
    let lastMessageDate: Date
    let messages: [WatchChatMessage]
    
    init(id: UUID = UUID(), title: String, lastMessage: String, lastMessageDate: Date, messages: [WatchChatMessage] = []) {
        self.id = id
        self.title = title
        self.lastMessage = lastMessage
        self.lastMessageDate = lastMessageDate
        self.messages = messages
    }
}

