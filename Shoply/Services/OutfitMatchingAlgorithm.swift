//
//  OutfitMatchingAlgorithm.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import Combine

/// Algorithme intelligent de matching d'outfits (utilise IntelligentOutfitMatchingAlgorithm en local)
class OutfitMatchingAlgorithm: ObservableObject {
    
    private let wardrobeService: WardrobeService
    private let weatherService: WeatherService
    private let userProfile: UserProfile
    
    init(wardrobeService: WardrobeService, weatherService: WeatherService, userProfile: UserProfile) {
        self.wardrobeService = wardrobeService
        self.weatherService = weatherService
        self.userProfile = userProfile
    }
    
    // MARK: - Génération d'outfits
    
    /// Génère 5 outfits optimaux en utilisant ChatGPT si activé, sinon l'algorithme intelligent local
    func generateOutfits() async -> [MatchedOutfit] {
        guard let morningWeather = weatherService.morningWeather,
              let afternoonWeather = weatherService.afternoonWeather else {
            return []
        }
        
        guard !wardrobeService.items.isEmpty else {
            return []
        }
        
        let avgTemperature = (morningWeather.temperature + afternoonWeather.temperature) / 2
        let dominantCondition = determineDominantCondition(
            morning: morningWeather.condition,
            afternoon: afternoonWeather.condition
        )
        
        // Utiliser TOUS les items (avec ou sans photos) pour ChatGPT
        // ChatGPT peut travailler avec juste les descriptions même sans photos
        let itemsWithPhotos = wardrobeService.items.filter { $0.photoURL != nil && !($0.photoURL?.isEmpty ?? true) }
        
        // Essayer ChatGPT d'abord s'il est activé (même avec 2 articles), sinon fallback local
        if OpenAIService.shared.isEnabled && !wardrobeService.items.isEmpty {
            do {
                // Générer avec ChatGPT en utilisant TOUS les items (pas seulement ceux avec photos)
                // ChatGPT peut créer des outfits même avec peu d'articles
                let suggestions = try await OpenAIService.shared.generateOutfitSuggestions(
                    wardrobeItems: wardrobeService.items, // Utiliser TOUS les items
                    weather: WeatherData(
                        temperature: avgTemperature,
                        condition: dominantCondition,
                        humidity: 50,
                        windSpeed: 0
                    ),
                    userProfile: userProfile
                )
                
                // Convertir les suggestions ChatGPT en MatchedOutfit
                var outfits: [MatchedOutfit] = []
                
                for suggestion in suggestions.prefix(5) {
                    // Utiliser TOUS les items pour le parsing
                    if let outfit = parseChatGPTSuggestion(suggestion, from: wardrobeService.items) {
                        outfits.append(outfit)
                    }
                }
                
                // Si on n'a pas assez d'outfits, compléter avec l'algorithme local
                if outfits.count < 5 {
                    let localAlgorithm = IntelligentOutfitMatchingAlgorithm(
                        wardrobeService: wardrobeService,
                        weatherService: weatherService,
                        userProfile: userProfile
                    )
                    let localOutfits = await localAlgorithm.generateOutfits()
                    outfits.append(contentsOf: localOutfits)
                }
                
                // Éliminer les doublons et retourner les 5 meilleurs
                var uniqueOutfits: [MatchedOutfit] = []
                var seenCombinations: Set<Set<UUID>> = []
                
                for outfit in outfits.prefix(5) {
                    let itemIds = Set(outfit.items.map { $0.id })
                    if !seenCombinations.contains(itemIds) {
                        seenCombinations.insert(itemIds)
                        uniqueOutfits.append(outfit)
                    }
                }
                
                return uniqueOutfits.sorted { $0.score > $1.score }
                
            } catch {
                print("⚠️ Erreur ChatGPT: \(error), utilisation de l'algorithme local")
                // Fallback sur l'algorithme local
                let intelligentAlgorithm = IntelligentOutfitMatchingAlgorithm(
                    wardrobeService: wardrobeService,
                    weatherService: weatherService,
                    userProfile: userProfile
                )
                return await intelligentAlgorithm.generateOutfits()
            }
        } else {
            // Utiliser l'algorithme local intelligent
            let intelligentAlgorithm = IntelligentOutfitMatchingAlgorithm(
                wardrobeService: wardrobeService,
                weatherService: weatherService,
                userProfile: userProfile
            )
            return await intelligentAlgorithm.generateOutfits()
        }
    }
    
    // MARK: - Parsing ChatGPT
    
    private func parseChatGPTSuggestion(_ suggestion: String, from items: [WardrobeItem]) -> MatchedOutfit? {
        var selectedItems: [WardrobeItem] = []
        let lowerSuggestion = suggestion.lowercased()
        
        // Extraire les parties séparées par "+"
        let parts = suggestion.components(separatedBy: "+")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Pour chaque partie, trouver le vêtement correspondant
        for part in parts {
            let partLower = part.lowercased()
            var bestMatch: WardrobeItem?
            var bestScore = 0
            
            for item in items {
                let itemNameLower = item.name.lowercased()
                var score = 0
                
                // Correspondance exacte
                if partLower == itemNameLower {
                    score = 100
                }
                // Correspondance partielle
                else if partLower.contains(itemNameLower) || itemNameLower.contains(partLower) {
                    score = 50
                }
                // Correspondance de catégorie
                else if partLower.contains(item.category.rawValue.lowercased()) ||
                        partLower.contains(categoryKeywords[item.category] ?? "") {
                    score = 30
                }
                
                if score > bestScore {
                    bestScore = score
                    bestMatch = item
                }
            }
            
            if let match = bestMatch, !selectedItems.contains(where: { $0.id == match.id }) {
                selectedItems.append(match)
            }
        }
        
        // Si on n'a pas trouvé assez d'items, essayer de compléter
        if selectedItems.isEmpty {
            for item in items {
                let itemNameLower = item.name.lowercased()
                if lowerSuggestion.contains(itemNameLower) && !selectedItems.contains(where: { $0.id == item.id }) {
                    selectedItems.append(item)
                }
            }
        }
        
        // S'assurer qu'on a au moins un haut et un bas (chaussures optionnelles si peu d'articles)
        guard selectedItems.contains(where: { $0.category == .top || $0.category == .outerwear }),
              selectedItems.contains(where: { $0.category == .bottom }) else {
            return nil
        }
        
        // Si on n'a pas de chaussures, on peut quand même créer un outfit (optionnel)
        // Mais on essaie d'en avoir si possible
        if !selectedItems.contains(where: { $0.category == .shoes }) {
            // Pas de chaussures, mais on peut quand même créer l'outfit
            print("⚠️ Outfit créé sans chaussures")
        }
        
        let avgTemp = ((weatherService.morningWeather?.temperature ?? 20.0) + (weatherService.afternoonWeather?.temperature ?? 20.0)) / 2
        let condition = weatherService.morningWeather?.condition ?? WeatherCondition.sunny
        
        return MatchedOutfit(
            items: selectedItems,
            score: 90.0, // Score élevé pour les suggestions ChatGPT
            temperature: avgTemp,
            weatherCondition: condition,
            reason: "Suggestion ChatGPT: \(suggestion)"
        )
    }
    
    private var categoryKeywords: [ClothingCategory: String] {
        [
            .top: "haut chemise t-shirt polo pull",
            .bottom: "bas pantalon jean short",
            .shoes: "chaussures baskets bottes",
            .outerwear: "veste manteau",
            .accessory: "accessoire",
            .bag: "sac"
        ]
    }
    
    private func determineDominantCondition(morning: WeatherCondition, afternoon: WeatherCondition) -> WeatherCondition {
        if morning == afternoon {
            return morning
        }
        if morning == .rainy || afternoon == .rainy {
            return .rainy
        }
        if morning == .cold || afternoon == .cold {
            return .cold
        }
        if morning == .cloudy || afternoon == .cloudy {
            return .cloudy
        }
        return .sunny
    }
    
}

/// Outfit généré par l'algorithme
struct MatchedOutfit: Identifiable {
    let id = UUID()
    let items: [WardrobeItem]
    let score: Double // 0-100
    let temperature: Double
    let weatherCondition: WeatherCondition
    let reason: String
    
    var displayName: String {
        let top = items.first(where: { $0.category == .top || $0.category == .outerwear })?.name ?? "Haut"
        let bottom = items.first(where: { $0.category == .bottom })?.name ?? "Bas"
        let shoes = items.first(where: { $0.category == .shoes })?.name ?? "Chaussures"
        return "\(top) + \(bottom) + \(shoes)"
    }
}
