//
//  OutfitMatchingAlgorithm.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import Combine

/// Algorithme intelligent de matching d'outfits
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
    
    /// Génère 5 outfits optimaux pour la journée en utilisant ChatGPT avec toutes les photos
    func generateOutfits() async -> [MatchedOutfit] {
        guard let morningWeather = weatherService.morningWeather,
              let afternoonWeather = weatherService.afternoonWeather else {
            return []
        }
        
        // Vérifier qu'on a des vêtements dans la garde-robe
        guard !wardrobeService.items.isEmpty else {
            return []
        }
        
        // Analyser la météo moyenne de la journée
        let avgTemperature = (morningWeather.temperature + afternoonWeather.temperature) / 2
        let dominantCondition = determineDominantCondition(morning: morningWeather.condition, afternoon: afternoonWeather.condition)
        
        // Utiliser TOUS les items avec photos pour ChatGPT (pas de filtrage préalable)
        let itemsWithPhotos = wardrobeService.items.filter { $0.photoURL != nil && !($0.photoURL?.isEmpty ?? true) }
        
        // Toujours essayer ChatGPT d'abord s'il est activé, sinon fallback
        if OpenAIService.shared.isEnabled && !itemsWithPhotos.isEmpty {
            return await generateOutfitsWithChatGPT(
                items: itemsWithPhotos, // Utiliser TOUS les items avec photos
                temperature: avgTemperature,
                condition: dominantCondition
            )
        } else {
            // Fallback: algorithme local avec filtrage météo
            let suitableItems = filterItemsForWeather(
                items: wardrobeService.items,
                temperature: avgTemperature,
                condition: dominantCondition
            )
            return generateOutfitsLocally(
                items: suitableItems,
                temperature: avgTemperature,
                condition: dominantCondition
            )
        }
    }
    
    /// Génère des outfits avec ChatGPT
    private func generateOutfitsWithChatGPT(
        items: [WardrobeItem],
        temperature: Double,
        condition: WeatherCondition
    ) async -> [MatchedOutfit] {
        do {
            // Obtenir les suggestions de ChatGPT
            let suggestions = try await OpenAIService.shared.generateOutfitSuggestions(
                wardrobeItems: items,
                weather: WeatherData(
                    temperature: temperature,
                    condition: condition,
                    humidity: 50,
                    windSpeed: 0
                ),
                userProfile: userProfile
            )
            
            // Convertir les suggestions en MatchedOutfit
            var outfits: [MatchedOutfit] = []
            
            for suggestion in suggestions.prefix(5) {
                // Parser la suggestion et créer un outfit correspondant
                if let outfit = parseChatGPTSuggestion(suggestion, from: items) {
                    outfits.append(outfit)
                }
            }
            
            // Si on n'a pas assez d'outfits, compléter avec l'algorithme local
            if outfits.count < 5 {
                let localOutfits = generateOutfitsLocally(
                    items: items,
                    temperature: temperature,
                    condition: condition
                )
                outfits.append(contentsOf: localOutfits)
            }
            
            // Éliminer les doublons
            var uniqueOutfits: [MatchedOutfit] = []
            var seenCombinations: Set<Set<UUID>> = []
            
            for outfit in outfits.prefix(5) {
                let itemIds = Set(outfit.items.map { $0.id })
                if !seenCombinations.contains(itemIds) {
                    seenCombinations.insert(itemIds)
                    uniqueOutfits.append(outfit)
                }
            }
            
            return uniqueOutfits
        } catch {
            print("⚠️ Erreur ChatGPT: \(error), utilisation de l'algorithme local")
            return generateOutfitsLocally(
                items: items,
                temperature: temperature,
                condition: condition
            )
        }
    }
    
    /// Génère des outfits avec l'algorithme local
    private func generateOutfitsLocally(
        items: [WardrobeItem],
        temperature: Double,
        condition: WeatherCondition
    ) -> [MatchedOutfit] {
        let itemsByCategory = organizeByCategory(items)
        
        var outfits: [MatchedOutfit] = []
        var usedCombinations: Set<String> = []
        
        for _ in 0..<10 {
            if let outfit = generateSingleOutfit(
                itemsByCategory: itemsByCategory,
                temperature: temperature,
                condition: condition
            ) {
                let combinationKey = outfit.items.map { $0.id.uuidString }.sorted().joined(separator: "-")
                
                // Éviter les doublons
                if !usedCombinations.contains(combinationKey) {
                    usedCombinations.insert(combinationKey)
                    outfits.append(outfit)
                }
                
                if outfits.count >= 5 {
                    break
                }
            }
        }
        
        outfits.sort { $0.score > $1.score }
        return Array(outfits.prefix(5))
    }
    
    /// Parse une suggestion ChatGPT en MatchedOutfit
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
            // Fallback: chercher des mots-clés dans la suggestion
            for item in items {
                let itemNameLower = item.name.lowercased()
                if lowerSuggestion.contains(itemNameLower) && !selectedItems.contains(where: { $0.id == item.id }) {
                    selectedItems.append(item)
                }
            }
        }
        
        // S'assurer qu'on a au moins un haut et un bas
        guard selectedItems.contains(where: { $0.category == .top || $0.category == .outerwear }),
              selectedItems.contains(where: { $0.category == .bottom }),
              selectedItems.contains(where: { $0.category == .shoes }) else {
            return nil
        }
        
        let avgTemp = ((weatherService.morningWeather?.temperature ?? 20.0) + (weatherService.afternoonWeather?.temperature ?? 20.0)) / 2
        let condition = weatherService.morningWeather?.condition ?? .sunny
        
        return MatchedOutfit(
            items: selectedItems,
            score: 90.0, // Score élevé pour les suggestions ChatGPT
            temperature: avgTemp,
            weatherCondition: condition,
            reason: suggestion
        )
    }
    
    /// Mots-clés pour les catégories
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
    
    // MARK: - Génération d'un outfit
    
    private func generateSingleOutfit(
        itemsByCategory: [ClothingCategory: [WardrobeItem]],
        temperature: Double,
        condition: WeatherCondition
    ) -> MatchedOutfit? {
        
        var selectedItems: [WardrobeItem] = []
        
        // 1. Bas (obligatoire)
        if let bottoms = itemsByCategory[.bottom]?.randomElement() {
            selectedItems.append(bottoms)
        } else {
            return nil // Pas d'outfit possible sans bas
        }
        
        // 2. Haut (obligatoire)
        if let tops = itemsByCategory[.top]?.randomElement() {
            selectedItems.append(tops)
        } else {
            return nil
        }
        
        // 3. Veste/Manteau (si nécessaire selon la météo)
        if temperature < 15 || condition == .rainy || condition == .windy {
            if let outerwear = itemsByCategory[.outerwear]?.randomElement() {
                selectedItems.append(outerwear)
            }
        }
        
        // 4. Chaussures (obligatoire)
        if let shoes = itemsByCategory[.shoes]?.randomElement() {
            selectedItems.append(shoes)
        } else {
            return nil
        }
        
        // 5. Accessoires (optionnel, mais recommandé)
        if let accessories = itemsByCategory[.accessory] {
            let selected = accessories.randomElement()
            if let accessory = selected {
                selectedItems.append(accessory)
            }
        }
        
        // Calculer le score de pertinence
        let score = calculateOutfitScore(items: selectedItems, temperature: temperature, condition: condition)
        
        return MatchedOutfit(
            items: selectedItems,
            score: score,
            temperature: temperature,
            weatherCondition: condition,
            reason: generateOutfitReason(outfit: selectedItems, score: score)
        )
    }
    
    // MARK: - Filtrage et scoring
    
    private func filterItemsForWeather(
        items: [WardrobeItem],
        temperature: Double,
        condition: WeatherCondition
    ) -> [WardrobeItem] {
        return items.filter { item in
            // Filtrer selon la température
            let tempSuitable = isItemSuitableForTemperature(item, temperature: temperature)
            
            // Filtrer selon la condition météo
            let conditionSuitable = isItemSuitableForCondition(item, condition: condition)
            
            // Filtrer selon la saison actuelle
            let seasonSuitable = isItemSuitableForSeason(item)
            
            return tempSuitable && conditionSuitable && seasonSuitable
        }
    }
    
    private func isItemSuitableForTemperature(_ item: WardrobeItem, temperature: Double) -> Bool {
        // Logique simplifiée - peut être améliorée
        if temperature < 10 {
            // Hiver - vêtements chauds
            return item.season.contains(.winter) || item.season.contains(.allSeason)
        } else if temperature < 20 {
            // Printemps/Automne
            return item.season.contains(.spring) || item.season.contains(.autumn) || item.season.contains(.allSeason)
        } else {
            // Été
            return item.season.contains(.summer) || item.season.contains(.allSeason)
        }
    }
    
    private func isItemSuitableForCondition(_ item: WardrobeItem, condition: WeatherCondition) -> Bool {
        switch condition {
        case .rainy:
            // Éviter les matériaux qui ne résistent pas à l'eau
            return !(item.material?.lowercased().contains("coton") ?? false) ||
                   item.category == .outerwear // Les vestes sont généralement imperméables
        case .snowy:
            return item.season.contains(.winter)
        case .sunny:
            return true // La plupart des vêtements sont OK
        default:
            return true
        }
    }
    
    private func isItemSuitableForSeason(_ item: WardrobeItem) -> Bool {
        let currentSeason = getCurrentSeason()
        return item.season.contains(currentSeason) || item.season.contains(.allSeason)
    }
    
    private func getCurrentSeason() -> Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 12, 1, 2: return .winter
        case 3, 4, 5: return .spring
        case 6, 7, 8: return .summer
        default: return .autumn
        }
    }
    
    private func organizeByCategory(_ items: [WardrobeItem]) -> [ClothingCategory: [WardrobeItem]] {
        Dictionary(grouping: items, by: { $0.category })
    }
    
    private func determineDominantCondition(morning: WeatherCondition, afternoon: WeatherCondition) -> WeatherCondition {
        // Si c'est le même, retourner celui-ci
        if morning == afternoon {
            return morning
        }
        // Sinon, prioriser celui qui est plus restrictif (pluvieux > nuageux > ensoleillé)
        if morning == .rainy || afternoon == .rainy {
            return .rainy
        }
        if morning == .cloudy || afternoon == .cloudy {
            return .cloudy
        }
        return .sunny
    }
    
    // MARK: - Calcul du score
    
    private func calculateOutfitScore(
        items: [WardrobeItem],
        temperature: Double,
        condition: WeatherCondition
    ) -> Double {
        var score: Double = 0.0
        
        // Score de base
        score += 50.0
        
        // Bonus pour les favoris
        let favoriteCount = items.filter { $0.isFavorite }.count
        score += Double(favoriteCount) * 10.0
        
        // Bonus pour la cohérence des couleurs
        score += calculateColorHarmony(items: items) * 15.0
        
        // Bonus pour l'utilisation récente (éviter les vêtements jamais portés)
        score += calculateWearScore(items: items) * 10.0
        
        // Bonus pour correspondre aux préférences utilisateur
        score += calculatePreferenceScore(items: items) * 15.0
        
        // Pénalité pour les combinaisons impossibles
        if hasConflicts(items: items) {
            score -= 30.0
        }
        
        return max(0, min(100, score))
    }
    
    private func calculateColorHarmony(items: [WardrobeItem]) -> Double {
        // Logique simplifiée de cohérence des couleurs
        // Peut être améliorée avec une vraie théorie des couleurs
        let colors = items.map { $0.color.lowercased() }
        let uniqueColors = Set(colors)
        
        // Moins il y a de couleurs différentes, plus c'est harmonieux (dans une certaine limite)
        if uniqueColors.count <= 3 {
            return 1.0
        } else if uniqueColors.count <= 4 {
            return 0.7
        } else {
            return 0.4
        }
    }
    
    private func calculateWearScore(items: [WardrobeItem]) -> Double {
        // Récompenser les vêtements qui ont été portés récemment (mais pas trop souvent)
        let avgWearCount = items.map { $0.wearCount }.reduce(0, +) / max(items.count, 1)
        if avgWearCount > 0 && avgWearCount < 50 {
            return 1.0
        } else if avgWearCount == 0 {
            return 0.3 // Jamais porté
        } else {
            return 0.6 // Trop porté
        }
    }
    
    private func calculatePreferenceScore(items: [WardrobeItem]) -> Double {
        var score: Double = 0.0
        
        // Vérifier le style préféré
        // (Cette logique peut être améliorée)
        
        // Vérifier les couleurs préférées
        let preferredColors = Set(userProfile.preferences.favoriteColors.map { $0.lowercased() })
        let itemColors = Set(items.map { $0.color.lowercased() })
        let matchingColors = preferredColors.intersection(itemColors)
        
        if !matchingColors.isEmpty {
            score += 0.5
        }
        
        return min(1.0, score)
    }
    
    private func hasConflicts(items: [WardrobeItem]) -> Bool {
        // Détecter les conflits logiques (ex: t-shirt d'hiver avec short d'été)
        // À implémenter selon vos règles
        
        // Exemple simple : détecter si on a un vêtement d'hiver et un d'été
        let hasWinter = items.contains { $0.season.contains(.winter) && !$0.season.contains(.allSeason) }
        let hasSummer = items.contains { $0.season.contains(.summer) && !$0.season.contains(.allSeason) }
        
        return hasWinter && hasSummer
    }
    
    private func generateOutfitReason(outfit: [WardrobeItem], score: Double) -> String {
        var reasons: [String] = []
        
        if score > 80 {
            reasons.append("Excellent choix")
        } else if score > 60 {
            reasons.append("Bon choix")
        } else {
            reasons.append("Choix correct")
        }
        
        if outfit.contains(where: { $0.isFavorite }) {
            reasons.append("Inclut vos favoris")
        }
        
        return reasons.joined(separator: " • ")
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
        let top = items.first(where: { $0.category == .top })?.name ?? "Haut"
        let bottom = items.first(where: { $0.category == .bottom })?.name ?? "Bas"
        return "\(top) + \(bottom)"
    }
}

