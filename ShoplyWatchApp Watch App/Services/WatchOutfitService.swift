//
//  WatchOutfitService.swift
//  ShoplyWatchApp
//
//  Created by William on 01/11/2025.
//

import Foundation
import Combine

enum OutfitStyle: String, CaseIterable {
    case casual = "Décontracté"
    case professional = "Professionnel"
    case sport = "Sport"
    case evening = "Soirée"
}

class WatchOutfitService: ObservableObject {
    static let shared = WatchOutfitService()
    
    private let dataManager = WatchDataManager.shared
    
    private init() {}
    
    // MARK: - Get Today's Suggestion
    func getTodaySuggestion() async -> WatchOutfitSuggestion? {
        // Vérifier s'il y a une suggestion sauvegardée pour aujourd'hui
        let savedSuggestions = dataManager.getSavedSuggestions()
        let today = Calendar.current.startOfDay(for: Date())
        
        if let todaySuggestion = savedSuggestions.first(where: { suggestion in
            Calendar.current.isDate(suggestion.timestamp, inSameDayAs: today)
        }) {
            return todaySuggestion
        }
        
        // Générer une nouvelle suggestion
        return await generateSuggestion(style: .casual, weather: nil)
    }
    
    // MARK: - Generate Suggestions
    func generateSuggestions(style: OutfitStyle, weather: WatchWeather?) async -> [WatchOutfitSuggestion] {
        let wardrobeItems = dataManager.getWardrobeItems()
        
        // Algorithme simple de génération d'outfit
        var suggestions: [WatchOutfitSuggestion] = []
        
        // Générer 2-3 suggestions
        for i in 1...3 {
            let items = generateOutfitItems(from: wardrobeItems, style: style, weather: weather)
            let title = "Outfit \(style.rawValue) #\(i)"
            let description = generateDescription(style: style, weather: weather)
            
            let suggestion = WatchOutfitSuggestion(
                title: title,
                description: description,
                items: items,
                style: style.rawValue,
                weatherCondition: weather?.condition,
                timestamp: Date()
            )
            
            suggestions.append(suggestion)
        }
        
        return suggestions
    }
    
    // MARK: - Private Helpers
    func generateSuggestion(style: OutfitStyle, weather: WatchWeather?) async -> WatchOutfitSuggestion {
        let wardrobeItems = dataManager.getWardrobeItems()
        let items = generateOutfitItems(from: wardrobeItems, style: style, weather: weather)
        
        return WatchOutfitSuggestion(
            title: "Outfit du jour",
            description: generateDescription(style: style, weather: weather),
            items: items,
            style: style.rawValue,
            weatherCondition: weather?.condition,
            timestamp: Date()
        )
    }
    
    private func generateOutfitItems(from wardrobe: [WatchWardrobeItem], style: OutfitStyle, weather: WatchWeather?) -> [String] {
        var items: [String] = []
        
        // Filtrer par catégorie
        let tops = wardrobe.filter { $0.category == .top }
        let bottoms = wardrobe.filter { $0.category == .bottom }
        let shoes = wardrobe.filter { $0.category == .shoes }
        let accessories = wardrobe.filter { $0.category == .accessories }
        
        // Sélectionner des items aléatoirement
        if let top = tops.randomElement() {
            items.append("Haut: \(top.name)")
        }
        
        if let bottom = bottoms.randomElement() {
            items.append("Bas: \(bottom.name)")
        }
        
        if let shoe = shoes.randomElement() {
            items.append("Chaussures: \(shoe.name)")
        }
        
        if let accessory = accessories.randomElement() {
            items.append("Accessoire: \(accessory.name)")
        }
        
        // Si pas assez d'items, ajouter des suggestions génériques
        if items.isEmpty {
            items = generateGenericItems(style: style, weather: weather)
        }
        
        return items
    }
    
    private func generateGenericItems(style: OutfitStyle, weather: WatchWeather?) -> [String] {
        var items: [String] = []
        
        switch style {
        case .casual:
            items = ["T-shirt", "Jean", "Baskets"]
        case .professional:
            items = ["Chemise", "Pantalon", "Chaussures de ville"]
        case .sport:
            items = ["T-shirt sport", "Short", "Baskets de sport"]
        case .evening:
            items = ["Haut élégant", "Pantalon habillé", "Chaussures habillées"]
        }
        
        // Adapter selon la météo
        if let weather = weather {
            if weather.temperature < 10 {
                items.append("Manteau")
            } else if weather.condition.lowercased().contains("pluie") {
                items.append("Veste imperméable")
            }
        }
        
        return items
    }
    
    private func generateDescription(style: OutfitStyle, weather: WatchWeather?) -> String {
        var description = "Style \(style.rawValue.lowercased())"
        
        if let weather = weather {
            if weather.temperature < 10 {
                description += " adapté au froid"
            } else if weather.temperature > 25 {
                description += " adapté à la chaleur"
            }
            
            if weather.condition.lowercased().contains("pluie") {
                description += " avec protection contre la pluie"
            }
        }
        
        return description
    }
}

