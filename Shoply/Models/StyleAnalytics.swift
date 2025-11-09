//
//  StyleAnalytics.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import SwiftUI

/// Statistiques de style de l'utilisateur
struct StyleStatistics: Codable {
    var totalOutfits: Int
    var totalItems: Int
    var mostWornColors: [ColorFrequency]
    var mostWornCategories: [CategoryFrequency]
    var mostWornMaterials: [MaterialFrequency]
    var averageComfortLevel: Double
    var averageStyleLevel: Double
    var favoriteOutfitTypes: [OutfitTypeFrequency]
    var seasonalDistribution: [SeasonDistribution]
    var wearFrequency: [WearFrequency]
    var lastUpdated: Date
    
    init() {
        self.totalOutfits = 0
        self.totalItems = 0
        self.mostWornColors = []
        self.mostWornCategories = []
        self.mostWornMaterials = []
        self.averageComfortLevel = 0.0
        self.averageStyleLevel = 0.0
        self.favoriteOutfitTypes = []
        self.seasonalDistribution = []
        self.wearFrequency = []
        self.lastUpdated = Date()
    }
}

struct ColorFrequency: Codable, Identifiable {
    let id: UUID
    let color: String
    var count: Int
    var percentage: Double
    
    init(id: UUID = UUID(), color: String, count: Int, percentage: Double) {
        self.id = id
        self.color = color
        self.count = count
        self.percentage = percentage
    }
}

struct CategoryFrequency: Codable, Identifiable {
    let id: UUID
    let category: String
    var count: Int
    var percentage: Double
    
    init(id: UUID = UUID(), category: String, count: Int, percentage: Double) {
        self.id = id
        self.category = category
        self.count = count
        self.percentage = percentage
    }
}

struct MaterialFrequency: Codable, Identifiable {
    let id: UUID
    let material: String
    var count: Int
    var percentage: Double
    
    init(id: UUID = UUID(), material: String, count: Int, percentage: Double) {
        self.id = id
        self.material = material
        self.count = count
        self.percentage = percentage
    }
}

struct OutfitTypeFrequency: Codable, Identifiable {
    let id: UUID
    let type: String
    var count: Int
    var percentage: Double
    
    init(id: UUID = UUID(), type: String, count: Int, percentage: Double) {
        self.id = id
        self.type = type
        self.count = count
        self.percentage = percentage
    }
}

struct SeasonDistribution: Codable, Identifiable {
    let id: UUID
    let season: String
    var count: Int
    var percentage: Double
    
    init(id: UUID = UUID(), season: String, count: Int, percentage: Double) {
        self.id = id
        self.season = season
        self.count = count
        self.percentage = percentage
    }
}

struct WearFrequency: Codable, Identifiable {
    let id: UUID
    let itemName: String
    var wearCount: Int
    var lastWorn: Date?
    var daysSinceLastWorn: Int
    
    init(id: UUID = UUID(), itemName: String, wearCount: Int, lastWorn: Date?, daysSinceLastWorn: Int) {
        self.id = id
        self.itemName = itemName
        self.wearCount = wearCount
        self.lastWorn = lastWorn
        self.daysSinceLastWorn = daysSinceLastWorn
    }
}

/// Impact environnemental
struct EnvironmentalImpact: Codable {
    var totalItems: Int
    var itemsWornThisMonth: Int
    var averageWearPerItem: Double
    var itemsNotWornIn30Days: Int
    var itemsNotWornIn90Days: Int
    var sustainabilityScore: Double // 0-100
    var carbonFootprintReduction: Double // kg CO2
    
    init(totalItems: Int = 0, itemsWornThisMonth: Int = 0, averageWearPerItem: Double = 0.0, itemsNotWornIn30Days: Int = 0, itemsNotWornIn90Days: Int = 0, sustainabilityScore: Double = 0.0, carbonFootprintReduction: Double = 0.0) {
        self.totalItems = totalItems
        self.itemsWornThisMonth = itemsWornThisMonth
        self.averageWearPerItem = averageWearPerItem
        self.itemsNotWornIn30Days = itemsNotWornIn30Days
        self.itemsNotWornIn90Days = itemsNotWornIn90Days
        self.sustainabilityScore = sustainabilityScore
        self.carbonFootprintReduction = carbonFootprintReduction
    }
}

/// Coût par port
struct CostPerWear: Codable, Identifiable {
    var id: UUID { itemId }
    var itemId: UUID
    var itemName: String
    var purchasePrice: Double?
    var wearCount: Int
    var costPerWear: Double?
    var totalValue: Double
}

