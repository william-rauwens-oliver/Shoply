//
//  StyleAnalyticsService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import SwiftUI
import Combine

/// Service d'analyse des statistiques de style
class StyleAnalyticsService: ObservableObject {
    static let shared = StyleAnalyticsService()
    
    private let wardrobeService = WardrobeService()
    private let outfitService = OutfitService()
    
    private init() {}
    
    // MARK: - Calcul des Statistiques
    
    /// Calcule les statistiques complètes de style
    func calculateStatistics() -> StyleStatistics {
        let items = wardrobeService.items
        let outfits = outfitService.getAllOutfits()
        
        var stats = StyleStatistics()
        stats.totalItems = items.count
        stats.totalOutfits = outfits.count
        
        // Couleurs les plus portées
        stats.mostWornColors = calculateColorFrequency(items: items)
        
        // Catégories les plus portées
        stats.mostWornCategories = calculateCategoryFrequency(items: items)
        
        // Matières les plus portées
        stats.mostWornMaterials = calculateMaterialFrequency(items: items)
        
        // Niveaux de confort et style moyens
        let (avgComfort, avgStyle) = calculateAverageRatings(outfits: outfits)
        stats.averageComfortLevel = avgComfort
        stats.averageStyleLevel = avgStyle
        
        // Types d'outfits favoris
        stats.favoriteOutfitTypes = calculateOutfitTypeFrequency(outfits: outfits)
        
        // Distribution saisonnière
        stats.seasonalDistribution = calculateSeasonalDistribution(items: items)
        
        // Fréquence de port
        stats.wearFrequency = calculateWearFrequency(items: items)
        
        stats.lastUpdated = Date()
        
        return stats
    }
    
    /// Calcule l'impact environnemental
    func calculateEnvironmentalImpact() -> EnvironmentalImpact {
        let items = wardrobeService.items
        let now = Date()
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: now) ?? now
        let ninetyDaysAgo = Calendar.current.date(byAdding: .day, value: -90, to: now) ?? now
        
        let itemsWornThisMonth = items.filter { item in
            guard let lastWorn = item.lastWorn else { return false }
            return lastWorn >= thirtyDaysAgo
        }
        
        let itemsNotWorn30Days = items.filter { item in
            guard let lastWorn = item.lastWorn else { return true }
            return lastWorn < thirtyDaysAgo
        }
        
        let itemsNotWorn90Days = items.filter { item in
            guard let lastWorn = item.lastWorn else { return true }
            return lastWorn < ninetyDaysAgo
        }
        
        let totalWearCount = items.reduce(0) { $0 + $1.wearCount }
        let averageWearPerItem = items.isEmpty ? 0.0 : Double(totalWearCount) / Double(items.count)
        
        // Score de durabilité (0-100)
        let sustainabilityScore = calculateSustainabilityScore(
            items: items,
            averageWear: averageWearPerItem,
            itemsNotWorn30: itemsNotWorn30Days.count
        )
        
        // Réduction d'empreinte carbone (estimation)
        let carbonFootprintReduction = Double(itemsWornThisMonth.count) * 2.5 // kg CO2 par vêtement réutilisé
        
        return EnvironmentalImpact(
            totalItems: items.count,
            itemsWornThisMonth: itemsWornThisMonth.count,
            averageWearPerItem: averageWearPerItem,
            itemsNotWornIn30Days: itemsNotWorn30Days.count,
            itemsNotWornIn90Days: itemsNotWorn90Days.count,
            sustainabilityScore: sustainabilityScore,
            carbonFootprintReduction: carbonFootprintReduction
        )
    }
    
    /// Calcule le coût par port pour chaque vêtement
    func calculateCostPerWear(items: [WardrobeItem]) -> [CostPerWear] {
        return items.compactMap { item in
            // Le prix doit être stocké dans les tags ou notes (à implémenter)
            // Pour l'instant, on retourne nil si pas de prix
            guard let priceString = item.tags.first(where: { $0.contains("price:") }),
                  let price = Double(priceString.replacingOccurrences(of: "price:", with: "")) else {
                return nil
            }
            
            let costPerWear = item.wearCount > 0 ? price / Double(item.wearCount) : price
            let totalValue = price
            
            return CostPerWear(
                itemId: item.id,
                itemName: item.name,
                purchasePrice: price,
                wearCount: item.wearCount,
                costPerWear: costPerWear,
                totalValue: totalValue
            )
        }
    }
    
    // MARK: - Calculs Privés
    
    private func calculateColorFrequency(items: [WardrobeItem]) -> [ColorFrequency] {
        var colorCounts: [String: Int] = [:]
        
        for item in items {
            colorCounts[item.color, default: 0] += item.wearCount
        }
        
        let total = colorCounts.values.reduce(0, +)
        
        return colorCounts.map { color, count in
            ColorFrequency(
                color: color,
                count: count,
                percentage: total > 0 ? Double(count) / Double(total) * 100 : 0
            )
        }.sorted { $0.count > $1.count }
    }
    
    private func calculateCategoryFrequency(items: [WardrobeItem]) -> [CategoryFrequency] {
        var categoryCounts: [String: Int] = [:]
        
        for item in items {
            let categoryName = item.category.rawValue
            categoryCounts[categoryName, default: 0] += item.wearCount
        }
        
        let total = categoryCounts.values.reduce(0, +)
        
        return categoryCounts.map { category, count in
            CategoryFrequency(
                category: category,
                count: count,
                percentage: total > 0 ? Double(count) / Double(total) * 100 : 0
            )
        }.sorted { $0.count > $1.count }
    }
    
    private func calculateMaterialFrequency(items: [WardrobeItem]) -> [MaterialFrequency] {
        var materialCounts: [String: Int] = [:]
        
        for item in items {
            guard let material = item.material, !material.isEmpty else { continue }
            materialCounts[material, default: 0] += item.wearCount
        }
        
        let total = materialCounts.values.reduce(0, +)
        
        return materialCounts.map { material, count in
            MaterialFrequency(
                material: material,
                count: count,
                percentage: total > 0 ? Double(count) / Double(total) * 100 : 0
            )
        }.sorted { $0.count > $1.count }
    }
    
    private func calculateAverageRatings(outfits: [Outfit]) -> (comfort: Double, style: Double) {
        guard !outfits.isEmpty else { return (0, 0) }
        
        let totalComfort = outfits.reduce(0) { $0 + $1.comfortLevel }
        let totalStyle = outfits.reduce(0) { $0 + $1.styleLevel }
        
        return (
            Double(totalComfort) / Double(outfits.count),
            Double(totalStyle) / Double(outfits.count)
        )
    }
    
    private func calculateOutfitTypeFrequency(outfits: [Outfit]) -> [OutfitTypeFrequency] {
        var typeCounts: [String: Int] = [:]
        
        for outfit in outfits {
            typeCounts[outfit.type.rawValue, default: 0] += 1
        }
        
        let total = typeCounts.values.reduce(0, +)
        
        return typeCounts.map { type, count in
            OutfitTypeFrequency(
                type: type,
                count: count,
                percentage: total > 0 ? Double(count) / Double(total) * 100 : 0
            )
        }.sorted { $0.count > $1.count }
    }
    
    private func calculateSeasonalDistribution(items: [WardrobeItem]) -> [SeasonDistribution] {
        var seasonCounts: [String: Int] = [:]
        
        for item in items {
            for season in item.season {
                seasonCounts[season.rawValue, default: 0] += 1
            }
        }
        
        let total = seasonCounts.values.reduce(0, +)
        
        return seasonCounts.map { season, count in
            SeasonDistribution(
                season: season,
                count: count,
                percentage: total > 0 ? Double(count) / Double(total) * 100 : 0
            )
        }.sorted { $0.count > $1.count }
    }
    
    private func calculateWearFrequency(items: [WardrobeItem]) -> [WearFrequency] {
        let now = Date()
        
        return items.map { item in
            let daysSince = item.lastWorn.map { date in
                Calendar.current.dateComponents([.day], from: date, to: now).day ?? 0
            } ?? Int.max
            
            return WearFrequency(
                itemName: item.name,
                wearCount: item.wearCount,
                lastWorn: item.lastWorn,
                daysSinceLastWorn: daysSince
            )
        }.sorted { $0.wearCount > $1.wearCount }
    }
    
    private func calculateSustainabilityScore(items: [WardrobeItem], averageWear: Double, itemsNotWorn30: Int) -> Double {
        guard !items.isEmpty else { return 0.0 }
        
        var score = 0.0
        
        // Score basé sur la fréquence de port (0-40 points)
        let wearScore = min(averageWear / 10.0 * 40, 40)
        score += wearScore
        
        // Score basé sur le pourcentage d'items portés récemment (0-40 points)
        let itemsWorn30 = items.count - itemsNotWorn30
        let usageScore = Double(itemsWorn30) / Double(items.count) * 40
        score += usageScore
        
        // Score basé sur la variété (0-20 points)
        let uniqueCategories = Set(items.map { $0.category }).count
        let varietyScore = min(Double(uniqueCategories) / 8.0 * 20, 20)
        score += varietyScore
        
        return min(score, 100.0)
    }
}

