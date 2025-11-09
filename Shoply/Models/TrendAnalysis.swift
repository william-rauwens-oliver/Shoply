//
//  TrendAnalysis.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation

/// Analyse de tendances et prédictions
struct TrendAnalysis: Codable, Identifiable {
    let id: UUID
    var season: Season
    var year: Int
    var trends: [FashionTrend]
    var predictions: [TrendPrediction]
    var yourStyleScore: Double // 0.0 - 100.0
    var recommendations: [TrendRecommendation]
    var analyzedAt: Date
    
    init(id: UUID = UUID(), season: Season, year: Int, trends: [FashionTrend] = [], predictions: [TrendPrediction] = [], yourStyleScore: Double = 0.0, recommendations: [TrendRecommendation] = [], analyzedAt: Date = Date()) {
        self.id = id
        self.season = season
        self.year = year
        self.trends = trends
        self.predictions = predictions
        self.yourStyleScore = yourStyleScore
        self.recommendations = recommendations
        self.analyzedAt = analyzedAt
    }
}

struct FashionTrend: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let category: ClothingCategory
    let popularity: Double // 0.0 - 1.0
    let trendDirection: TrendDirection
    let colorPalette: [String]
    let examples: [String] // URLs d'images
    
    enum TrendDirection: String, Codable {
        case rising = "En hausse"
        case stable = "Stable"
        case declining = "En baisse"
        case emerging = "Émergent"
    }
    
    init(id: UUID = UUID(), name: String, description: String, category: ClothingCategory, popularity: Double, trendDirection: TrendDirection, colorPalette: [String] = [], examples: [String] = []) {
        self.id = id
        self.name = name
        self.description = description
        self.category = category
        self.popularity = popularity
        self.trendDirection = trendDirection
        self.colorPalette = colorPalette
        self.examples = examples
    }
}

struct TrendPrediction: Codable, Identifiable {
    let id: UUID
    let trend: String
    let confidence: Double // 0.0 - 1.0
    let timeframe: String // "3 mois", "6 mois", etc.
    let impact: ImpactLevel
    
    enum ImpactLevel: String, Codable {
        case high = "Élevé"
        case medium = "Moyen"
        case low = "Faible"
    }
    
    init(id: UUID = UUID(), trend: String, confidence: Double, timeframe: String, impact: ImpactLevel) {
        self.id = id
        self.trend = trend
        self.confidence = confidence
        self.timeframe = timeframe
        self.impact = impact
    }
}

struct TrendRecommendation: Codable, Identifiable {
    let id: UUID
    let action: String
    let reason: String
    let priority: Int // 1-5
    let category: ClothingCategory?
    
    init(id: UUID = UUID(), action: String, reason: String, priority: Int = 3, category: ClothingCategory? = nil) {
        self.id = id
        self.action = action
        self.reason = reason
        self.priority = priority
        self.category = category
    }
}

