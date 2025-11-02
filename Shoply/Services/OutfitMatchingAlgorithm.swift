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
        return await generateOutfitsWithProgress { _ in }
    }
    
    /// Génère avec progression pour l'UI
    /// - Parameter forceLocal: Si true, force l'utilisation de l'algorithme local même si ChatGPT est disponible
    func generateOutfitsWithProgress(forceLocal: Bool = false, progressCallback: @escaping (Double) async -> Void) async -> [MatchedOutfit] {
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
        
        // Utiliser le fournisseur IA sélectionné s'il est activé et non forcé en local
        let selectedProvider = AppSettingsManager.shared.aiProvider
        let isAIServiceEnabled = (selectedProvider == .chatGPT && OpenAIService.shared.isEnabled) ||
                                 (selectedProvider == .gemini && GeminiService.shared.isEnabled)
        
        if !forceLocal && isAIServiceEnabled && wardrobeService.items.count >= 2 {
            await progressCallback(0.2) // 20% - Préparation
            
            do {
                // Générer avec le service IA sélectionné (ChatGPT ou Gemini)
                let suggestions: [String]
                
                if selectedProvider == .chatGPT && OpenAIService.shared.isEnabled {
                    suggestions = try await OpenAIService.shared.generateOutfitSuggestions(
                        wardrobeItems: wardrobeService.items,
                        weather: WeatherData(
                            temperature: avgTemperature,
                            condition: dominantCondition,
                            humidity: 50,
                            windSpeed: 0
                        ),
                        userProfile: userProfile,
                        progressCallback: progressCallback
                    )
                } else if selectedProvider == .gemini && GeminiService.shared.isEnabled {
                    suggestions = try await GeminiService.shared.generateOutfitSuggestions(
                        wardrobeItems: wardrobeService.items,
                        weather: WeatherData(
                            temperature: avgTemperature,
                            condition: dominantCondition,
                            humidity: 50,
                            windSpeed: 0
                        ),
                        userProfile: userProfile,
                        progressCallback: progressCallback
                    )
                } else {
                    // Fallback si le service sélectionné n'est pas disponible
                    throw NSError(domain: "OutfitMatching", code: 1, userInfo: [NSLocalizedDescriptionKey: "Service IA non disponible"])
                }
                
                await progressCallback(0.8) // 80% - Suggestions reçues
                
                // Convertir les suggestions IA en MatchedOutfit
                var outfits: [MatchedOutfit] = []
                
                for suggestion in suggestions.prefix(5) {
                    // Utiliser TOUS les items pour le parsing
                    if let outfit = parseAISuggestion(suggestion, from: wardrobeService.items) {
                        outfits.append(outfit)
                    }
                }
                
                // Si on n'a pas assez d'outfits ou si l'IA n'a rien trouvé, compléter avec l'algorithme local
                if outfits.isEmpty || outfits.count < 3 {
                    let localAlgorithm = IntelligentOutfitMatchingAlgorithm(
                        wardrobeService: wardrobeService,
                        weatherService: weatherService,
                        userProfile: userProfile
                    )
                    let localOutfits = await localAlgorithm.generateOutfits()
                    outfits.append(contentsOf: localOutfits)
                }
                
                // Si toujours rien, créer un outfit basique avec haut + bas
                if outfits.isEmpty {
                    let basicOutfit = createBasicOutfit(from: wardrobeService.items)
                    if let basicOutfit = basicOutfit {
                        outfits.append(basicOutfit)
                    }
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
                let providerName = selectedProvider == .chatGPT ? "ChatGPT" : "Gemini"
                print("⚠️ Erreur \(providerName): \(error), utilisation de l'algorithme local")
                await progressCallback(0.3) // 30% - Erreur, fallback local
                // Fallback sur l'algorithme local
                let intelligentAlgorithm = IntelligentOutfitMatchingAlgorithm(
                    wardrobeService: wardrobeService,
                    weatherService: weatherService,
                    userProfile: userProfile
                )
                await progressCallback(0.8) // 80% - Génération locale
                var outfits = await intelligentAlgorithm.generateOutfits()
                
                // Si toujours rien, créer un outfit basique avec haut + bas
                if outfits.isEmpty {
                    let basicOutfit = createBasicOutfit(from: wardrobeService.items)
                    if let basicOutfit = basicOutfit {
                        outfits.append(basicOutfit)
                    }
                }
                
                await progressCallback(1.0) // 100% - Terminé
                return outfits
            }
        } else {
            // Utiliser l'algorithme local intelligent
            await progressCallback(0.3) // 30% - Utilisation algorithme local
            let intelligentAlgorithm = IntelligentOutfitMatchingAlgorithm(
                wardrobeService: wardrobeService,
                weatherService: weatherService,
                userProfile: userProfile
            )
            await progressCallback(0.7) // 70% - Génération locale
                var outfits = await intelligentAlgorithm.generateOutfits()
                
                // Si toujours rien, créer un outfit basique avec haut + bas
                if outfits.isEmpty {
                    let basicOutfit = createBasicOutfit(from: wardrobeService.items)
                    if let basicOutfit = basicOutfit {
                        outfits.append(basicOutfit)
                    }
                }
                
            await progressCallback(1.0) // 100% - Terminé
            return outfits
        }
    }
        
        // MARK: - Création d'outfit basique (fallback)
        
        private func createBasicOutfit(from items: [WardrobeItem]) -> MatchedOutfit? {
            // Chercher un haut
            guard let top = items.first(where: { $0.category == .top || $0.category == .outerwear }) else {
                return nil
            }
            
            // Chercher un bas
            guard let bottom = items.first(where: { $0.category == .bottom }) else {
                return nil
            }
            
            var selectedItems = [top, bottom]
            
            // Ajouter des chaussures si disponibles (optionnel)
            if let shoes = items.first(where: { $0.category == .shoes }) {
                selectedItems.append(shoes)
            }
            
            let avgTemp = ((weatherService.morningWeather?.temperature ?? 20.0) + (weatherService.afternoonWeather?.temperature ?? 20.0)) / 2
            let condition = weatherService.morningWeather?.condition ?? WeatherCondition.sunny
            
            return MatchedOutfit(
                items: selectedItems,
                score: 70.0,
                temperature: avgTemp,
                weatherCondition: condition,
                reason: "Outfit basique créé avec les vêtements disponibles"
            )
        }
    
    // MARK: - Parsing IA
    
    private func parseAISuggestion(_ suggestion: String, from items: [WardrobeItem]) -> MatchedOutfit? {
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
        
        let providerName = AppSettingsManager.shared.aiProvider == .chatGPT ? "ChatGPT" : "Gemini"
        return MatchedOutfit(
            items: selectedItems,
            score: 90.0, // Score élevé pour les suggestions IA
            temperature: avgTemp,
            weatherCondition: condition,
            reason: "Suggestion \(providerName): \(suggestion)"
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
struct MatchedOutfit: Identifiable, Codable {
    let id: UUID
    let items: [WardrobeItem]
    let score: Double // 0-100
    let temperature: Double
    let weatherCondition: WeatherCondition
    let reason: String
    
    init(id: UUID = UUID(), items: [WardrobeItem], score: Double, temperature: Double, weatherCondition: WeatherCondition, reason: String) {
        self.id = id
        self.items = items
        self.score = score
        self.temperature = temperature
        self.weatherCondition = weatherCondition
        self.reason = reason
    }
    
    var displayName: String {
        let top = items.first(where: { $0.category == .top || $0.category == .outerwear })?.name ?? "Haut"
        let bottom = items.first(where: { $0.category == .bottom })?.name ?? "Bas"
        let shoes = items.first(where: { $0.category == .shoes })?.name ?? "Chaussures"
        return "\(top) + \(bottom) + \(shoes)"
    }
}
