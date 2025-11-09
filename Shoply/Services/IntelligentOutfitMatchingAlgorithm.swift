//
//  IntelligentOutfitMatchingAlgorithm.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import Combine

/// Algorithme local intelligent et avancé de matching d'outfits
/// Utilise des règles sophistiquées pour créer des combinaisons optimales
class IntelligentOutfitMatchingAlgorithm: ObservableObject {
    
    private let wardrobeService: WardrobeService
    private let weatherService: WeatherService
    private let userProfile: UserProfile
    
    // Règles de couleurs harmonieuses (théorie des couleurs)
    private let neutralColors = ["noir", "blanc", "gris", "beige", "crème"]
    private let warmColors = ["rouge", "orange", "jaune", "corail", "pêche"]
    private let coldColors = ["bleu", "vert", "violet", "turquoise", "menthe"]
    
    private func getComplementaryColors(for color: String) -> [String] {
        let colorLower = color.lowercased()
        switch colorLower {
        case "rouge": return ["vert"]
        case "orange": return ["bleu"]
        case "jaune": return ["violet"]
        case "vert": return ["rouge"]
        case "bleu": return ["orange"]
        case "violet": return ["jaune"]
        default: return []
        }
    }
    
    init(wardrobeService: WardrobeService, weatherService: WeatherService, userProfile: UserProfile) {
        self.wardrobeService = wardrobeService
        self.weatherService = weatherService
        self.userProfile = userProfile
    }
    
    // MARK: - Génération principale
    
    func generateOutfits(selectedCollection: WardrobeCollection? = nil) async -> [MatchedOutfit] {
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
        
        // Filtrer les items adaptés à la météo (mais ne pas être trop strict)
        var itemsToFilter = wardrobeService.items
        
        // Si une collection est sélectionnée, utiliser uniquement les items de cette collection
        if let selectedCollection = selectedCollection, !selectedCollection.itemIds.isEmpty {
            let collectionService = WardrobeCollectionService.shared
            let collectionItems = collectionService.getItemsForCollection(selectedCollection)
            if !collectionItems.isEmpty {
                itemsToFilter = collectionItems
            }
        }
        
        let suitableItems = filterItemsIntelligently(
            items: itemsToFilter,
            temperature: avgTemperature,
            condition: dominantCondition
        )
        
        // Si le filtrage est trop strict, utiliser tous les items disponibles
        let itemsToUse = suitableItems.isEmpty ? itemsToFilter : suitableItems
        
        guard !itemsToUse.isEmpty else {
            return []
        }
        
        // Organiser par catégorie avec scoring
        let organizedItems = organizeItemsWithScoring(
            items: itemsToUse,
            temperature: avgTemperature,
            condition: dominantCondition
        )
        
        // Générer 10 combinaisons possibles
        var candidateOutfits: [MatchedOutfit] = []
        
        for _ in 0..<20 {
            if let outfit = generateIntelligentOutfit(
                organizedItems: organizedItems,
                temperature: avgTemperature,
                condition: dominantCondition
            ) {
                candidateOutfits.append(outfit)
            }
        }
        
        // Trier par score et retourner les 3 meilleurs max
        candidateOutfits.sort { $0.score > $1.score }
        
        // Éliminer les doublons
        var uniqueOutfits: [MatchedOutfit] = []
        var seenCombinations: Set<Set<UUID>> = []
        
        // Calculer le nombre max selon la taille de la garde-robe
        let maxOutfits: Int
        if wardrobeService.items.count < 10 {
            maxOutfits = 1
        } else if wardrobeService.items.count < 20 {
            maxOutfits = 2
        } else {
            maxOutfits = 3
        }
        
        for outfit in candidateOutfits {
            let itemIds = Set(outfit.items.map { $0.id })
            if !seenCombinations.contains(itemIds) {
                seenCombinations.insert(itemIds)
                uniqueOutfits.append(outfit)
                
                if uniqueOutfits.count >= maxOutfits {
                    break
                }
            }
        }
        
        return uniqueOutfits
    }
    
    // MARK: - Filtrage intelligent
    
    private func filterItemsIntelligently(
        items: [WardrobeItem],
        temperature: Double,
        condition: WeatherCondition
    ) -> [WardrobeItem] {
        return items.filter { item in
            // Score de compatibilité météo
            let weatherScore = calculateWeatherCompatibility(
                item: item,
                temperature: temperature,
                condition: condition
            )
            
            // Score de saison
            let seasonScore = calculateSeasonCompatibility(item: item)
            
            // Item valide si score > 0.5
            return (weatherScore + seasonScore) / 2.0 > 0.5
        }
    }
    
    private func calculateWeatherCompatibility(
        item: WardrobeItem,
        temperature: Double,
        condition: WeatherCondition
    ) -> Double {
        var score: Double = 0.0
        
        // Analyse par température
        switch temperature {
        case ..<5:
            // Très froid
            if item.category == .outerwear || item.category == .top {
                if item.material?.lowercased().contains("laine") == true ||
                   item.material?.lowercased().contains("doublure") == true ||
                   item.season.contains(.winter) {
                    score += 1.0
                }
            }
            if item.category == .bottom {
                if item.material?.lowercased().contains("jean") == true ||
                   item.material?.lowercased().contains("laine") == true {
                    score += 1.0
                }
            }
            
        case 5..<15:
            // Froid
            if item.season.contains(.winter) || item.season.contains(.autumn) || item.season.contains(.allSeason) {
                score += 0.8
            }
            
        case 15..<25:
            // Tempéré
            if item.season.contains(.spring) || item.season.contains(.autumn) || item.season.contains(.allSeason) {
                score += 0.9
            }
            
        case 25...:
            // Chaud
            if item.season.contains(.summer) || item.season.contains(.allSeason) {
                score += 1.0
            }
            if item.material?.lowercased().contains("coton") == true ||
               item.material?.lowercased().contains("lin") == true {
                score += 0.2
            }
            
        default:
            break
        }
        
        // Analyse par condition météo
        switch condition {
        case .rainy:
            if item.material?.lowercased().contains("imperméable") == true ||
               item.material?.lowercased().contains("nylon") == true ||
               item.category == .outerwear {
                score += 0.5
            }
            if item.material?.lowercased().contains("coton") == true && item.category != .outerwear {
                score -= 0.3
            }
            
        case .sunny:
            // Bonus pour les matières légères
            if item.material?.lowercased().contains("lin") == true ||
               item.material?.lowercased().contains("coton") == true {
                score += 0.2
            }
            
        case .cloudy:
            // Pas de bonus/malus spécifique
            break
            
        case .cold:
            if item.category == .outerwear || item.season.contains(.winter) {
                score += 0.5
            }
            
        case .warm:
            if item.season.contains(.summer) {
                score += 0.5
            }
            
        default:
            break
        }
        
        return min(1.0, max(0.0, score))
    }
    
    private func calculateSeasonCompatibility(item: WardrobeItem) -> Double {
        let currentSeason = getCurrentSeason()
        
        if item.season.contains(currentSeason) {
            return 1.0
        } else if item.season.contains(.allSeason) {
            return 0.8
        } else {
            return 0.3
        }
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
    
    // MARK: - Organisation avec scoring
    
    private func organizeItemsWithScoring(
        items: [WardrobeItem],
        temperature: Double,
        condition: WeatherCondition
    ) -> [ClothingCategory: [(item: WardrobeItem, score: Double)]] {
        var organized: [ClothingCategory: [(item: WardrobeItem, score: Double)]] = [:]
        
        for category in ClothingCategory.allCases {
            let categoryItems = items.filter { $0.category == category }
            var scoredItems: [(item: WardrobeItem, score: Double)] = []
            
            for item in categoryItems {
                var score = calculateItemScore(
                    item: item,
                    temperature: temperature,
                    condition: condition
                )
                
                // Bonus pour les favoris
                if item.isFavorite {
                    score += 0.2
                }
                
                // Bonus pour les items récemment portés (mais pas trop)
                if item.wearCount > 0 && item.wearCount < 30 {
                    score += 0.1
                }
                
                // Pénalité pour les items jamais portés
                if item.wearCount == 0 {
                    score -= 0.1
                }
                
                scoredItems.append((item: item, score: score))
            }
            
            // Trier par score décroissant
            scoredItems.sort { $0.score > $1.score }
            organized[category] = scoredItems
        }
        
        return organized
    }
    
    private func calculateItemScore(
        item: WardrobeItem,
        temperature: Double,
        condition: WeatherCondition
    ) -> Double {
        var score = calculateWeatherCompatibility(
            item: item,
            temperature: temperature,
            condition: condition
        )
        
        score += calculateSeasonCompatibility(item: item)
        
        return score / 2.0
    }
    
    // MARK: - Génération d'outfit intelligent
    
    private func generateIntelligentOutfit(
        organizedItems: [ClothingCategory: [(item: WardrobeItem, score: Double)]],
        temperature: Double,
        condition: WeatherCondition
    ) -> MatchedOutfit? {
        
        var selectedItems: [WardrobeItem] = []
        
        // Prendre en compte le style vestimentaire souhaité
        let preferredStyle = userProfile.preferences.preferredStyle
        let customStyle = userProfile.preferences.preferredStyleRawValue
        
        // 1. Bas (obligatoire) - Choisir parmi les meilleurs scores, en respectant le style
        guard let bottoms = selectBestItem(from: organizedItems[.bottom], matchingStyle: preferredStyle, customStyle: customStyle) else {
            return nil
        }
        selectedItems.append(bottoms)
        
        // 2. Haut (obligatoire) - Choisir parmi les meilleurs scores, en respectant le style et la couleur du bas
        guard let tops = selectBestItem(
            from: organizedItems[.top],
            matchingStyle: preferredStyle,
            customStyle: customStyle,
            harmonizingWith: bottoms
        ) else {
            return nil
        }
        selectedItems.append(tops)
        
        // 3. Veste/Manteau (intelligent selon météo et cohérence)
        if shouldIncludeOuterwear(temperature: temperature, condition: condition) {
            if let outerwear = selectBestItem(
                from: organizedItems[.outerwear],
                matchingStyle: preferredStyle,
                customStyle: customStyle,
                harmonizingWith: tops
            ) {
                // Vérifier la cohérence avec le haut
                if isColorHarmonious(item1: tops, item2: outerwear) {
                    selectedItems.append(outerwear)
                }
            }
        }
        
        // 4. Chaussures (optionnelles si pas disponibles) - Cohérentes avec le style
        if let shoes = selectBestShoes(
            from: organizedItems[.shoes],
            outfitStyle: determineOutfitStyle(items: selectedItems, preferredStyle: preferredStyle),
            matchingStyle: preferredStyle,
            customStyle: customStyle
        ) {
            selectedItems.append(shoes)
        } else {
            // Pas de chaussures disponibles, mais on peut quand même créer l'outfit
            print("⚠️ Outfit créé sans chaussures (pas disponibles dans la garde-robe)")
        }
        
        // 5. Accessoires (optionnel mais recommandé si cohérents)
        if let accessories = organizedItems[.accessory] {
            for accessory in accessories.prefix(3) {
                if isColorHarmonious(item1: selectedItems.first!, item2: accessory.item) &&
                   !selectedItems.contains(where: { $0.id == accessory.item.id }) {
                    selectedItems.append(accessory.item)
                    break
                }
            }
        }
        
        // Calculer le score final intelligent
        let finalScore = calculateIntelligentScore(
            items: selectedItems,
            temperature: temperature,
            condition: condition
        )
        
        return MatchedOutfit(
            items: selectedItems,
            score: finalScore,
            temperature: temperature,
            weatherCondition: condition,
            reason: generateIntelligentReason(outfit: selectedItems, score: finalScore)
        )
    }
    
    private func selectBestItem(
        from items: [(item: WardrobeItem, score: Double)]?,
        matchingStyle: OutfitType? = nil,
        customStyle: String? = nil,
        harmonizingWith: WardrobeItem? = nil
    ) -> WardrobeItem? {
        guard let items = items, !items.isEmpty else { return nil }
        
        // Filtrer selon le style si spécifié
        var filteredItems = items
        if let style = matchingStyle {
            // Filtrer les items qui correspondent au style (basé sur la catégorie et les tags)
            filteredItems = items.filter { tupleItem in
                matchesStyle(item: tupleItem.item, style: style)
            }
            // Si aucun item ne correspond, utiliser tous les items
            if filteredItems.isEmpty {
                filteredItems = items
            }
        } else if let customStyle = customStyle, !customStyle.isEmpty {
            // Pour style personnalisé, privilégier les items avec tags correspondants
            filteredItems = items.map { (item, score) in
                let styleScore = item.tags.contains { tag in
                    customStyle.lowercased().contains(tag.lowercased()) || tag.lowercased().contains(customStyle.lowercased())
                } ? score + 0.3 : score
                return (item: item, score: styleScore)
            }
        }
        
        // Si on doit harmoniser avec un autre item, privilégier ceux qui s'harmonisent
        if let harmonizingItem = harmonizingWith {
            filteredItems = filteredItems.map { (item, score) in
                let harmonyScore = isColorHarmonious(item1: harmonizingItem, item2: item) ? score + 0.2 : score
                return (item: item, score: harmonyScore)
            }
        }
        
        // Trier par score
        filteredItems.sort { $0.score > $1.score }
        
        // Prendre parmi les 3 meilleurs (pour varier)
        let topItems = Array(filteredItems.prefix(min(3, filteredItems.count)))
        return topItems.randomElement()?.item
    }
    
    private func matchesStyle(item: WardrobeItem, style: OutfitType) -> Bool {
        // Vérifier si l'item correspond au style demandé
        switch style {
        case .casual:
            // Style décontracté : favorise les catégories casual
            return item.category == .bottom || item.category == .top || item.tags.contains(where: { $0.lowercased().contains("casual") || $0.lowercased().contains("décontracté") })
        case .business:
            // Style business : favorise les vêtements formels
            return item.category == .outerwear || item.tags.contains(where: { $0.lowercased().contains("business") || $0.lowercased().contains("professionnel") || $0.lowercased().contains("formel") })
        case .smartCasual:
            // Smart casual : mélange de casual et formel
            return true // Plus flexible
        case .formal:
            // Formel : vêtements élégants
            return item.tags.contains(where: { $0.lowercased().contains("formel") || $0.lowercased().contains("élégant") || $0.lowercased().contains("soirée") }) || item.category == .outerwear
        case .weekend:
            // Weekend : confortable et décontracté
            return item.tags.contains(where: { $0.lowercased().contains("weekend") || $0.lowercased().contains("détente") || $0.lowercased().contains("confortable") }) || item.category == .bottom
        }
    }
    
    private func shouldIncludeOuterwear(temperature: Double, condition: WeatherCondition) -> Bool {
        if temperature < 15 {
            return true
        }
        if condition == .rainy || condition == .windy {
            return true
        }
        if temperature < 20 && condition == .cloudy {
            return true
        }
        return false
    }
    
    private func selectBestShoes(
        from items: [(item: WardrobeItem, score: Double)]?,
        outfitStyle: String,
        matchingStyle: OutfitType? = nil,
        customStyle: String? = nil
    ) -> WardrobeItem? {
        guard let items = items, !items.isEmpty else { return nil }
        
        // Filtrer selon le style si spécifié
        var filteredItems = items
        if let style = matchingStyle {
            filteredItems = items.filter { matchesStyle(item: $0.item, style: style) }
            if filteredItems.isEmpty {
                filteredItems = items
            }
        }
        
        // Trier par score
        filteredItems.sort { $0.score > $1.score }
        
        // Choisir parmi les 5 meilleurs
        let topItems = Array(filteredItems.prefix(min(5, filteredItems.count)))
        return topItems.randomElement()?.item
    }
    
    private func determineOutfitStyle(items: [WardrobeItem], preferredStyle: OutfitType?) -> String {
        // Si un style est préféré, l'utiliser
        if let style = preferredStyle {
            return style.rawValue.lowercased()
        }
        
        // Sinon, déterminer le style global de l'outfit
        if items.contains(where: { $0.category == .outerwear }) {
            return "casual"
        }
        return "casual"
    }
    
    // MARK: - Analyse des couleurs intelligente
    
    private func isColorHarmonious(item1: WardrobeItem, item2: WardrobeItem) -> Bool {
        let color1 = item1.color.lowercased().trimmingCharacters(in: .whitespaces)
        let color2 = item2.color.lowercased().trimmingCharacters(in: .whitespaces)
        
        // Couleurs identiques
        if color1 == color2 {
            return true
        }
        
        // Neutres s'accordent avec tout
        let neutrals = ["noir", "blanc", "gris", "beige", "crème", "kaki", "marine"]
        if neutrals.contains(color1) || neutrals.contains(color2) {
            return true
        }
        
        // Vérifier les harmonies complémentaires
        let complementaries1 = getComplementaryColors(for: color1)
        let complementaries2 = getComplementaryColors(for: color2)
        
        if complementaries1.contains(color2) || complementaries2.contains(color1) {
            return true
        }
        
        // Vérifier les tons similaires (famille de couleurs)
        let color1Base = extractBaseColor(color1)
        let color2Base = extractBaseColor(color2)
        
        if color1Base == color2Base {
            return true
        }
        
        // Par défaut, considérer comme harmonieux (on ne bloque pas)
        return true
    }
    
    private func extractBaseColor(_ color: String) -> String {
        let colors = color.components(separatedBy: " ")
        if let first = colors.first {
            return first.lowercased()
        }
        return color
    }
    
    // MARK: - Scoring intelligent
    
    private func calculateIntelligentScore(
        items: [WardrobeItem],
        temperature: Double,
        condition: WeatherCondition
    ) -> Double {
        var score: Double = 50.0 // Score de base
        
        // Score météo (30 points max)
        for item in items {
            let weatherCompat = calculateWeatherCompatibility(
                item: item,
                temperature: temperature,
                condition: condition
            )
            score += weatherCompat * 6.0
        }
        
        // Score harmonie des couleurs (20 points max)
        let colorHarmonyScore = calculateAdvancedColorHarmony(items: items)
        score += colorHarmonyScore * 20.0
        
        // Score préférences utilisateur (15 points max)
        let preferenceScore = calculatePreferenceScore(items: items)
        score += preferenceScore * 15.0
        
        // Bonus favoris (10 points max)
        let favoriteCount = items.filter { $0.isFavorite }.count
        score += Double(favoriteCount) * 3.0
        
        // Bonus équilibre de l'outfit (10 points max)
        let balanceScore = calculateOutfitBalance(items: items)
        score += balanceScore * 10.0
        
        // Pénalités
        if hasStyleConflicts(items: items) {
            score -= 20.0
        }
        
        if hasColorConflicts(items: items) {
            score -= 15.0
        }
        
        return max(0.0, min(100.0, score))
    }
    
    private func calculateAdvancedColorHarmony(items: [WardrobeItem]) -> Double {
        guard items.count >= 2 else { return 0.5 }
        
        var harmonyScore: Double = 0.0
        var pairs: Int = 0
        
        for i in 0..<items.count {
            for j in (i+1)..<items.count {
                if isColorHarmonious(item1: items[i], item2: items[j]) {
                    harmonyScore += 1.0
                }
                pairs += 1
            }
        }
        
        return pairs > 0 ? harmonyScore / Double(pairs) : 0.5
    }
    
    private func calculatePreferenceScore(items: [WardrobeItem]) -> Double {
        var score: Double = 0.0
        
        // Vérifier les couleurs préférées
        let preferredColors = Set(userProfile.preferences.favoriteColors.map { $0.lowercased() })
        let itemColors = Set(items.map { $0.color.lowercased() })
        let matchingColors = preferredColors.intersection(itemColors)
        
        if !matchingColors.isEmpty {
            score += Double(matchingColors.count) / Double(max(preferredColors.count, 1))
        }
        
        return min(1.0, score)
    }
    
    private func calculateOutfitBalance(items: [WardrobeItem]) -> Double {
        // Vérifier qu'on a les éléments essentiels
        var score: Double = 0.0
        
        if items.contains(where: { $0.category == .top || $0.category == .outerwear }) {
            score += 0.3
        }
        if items.contains(where: { $0.category == .bottom }) {
            score += 0.3
        }
        if items.contains(where: { $0.category == .shoes }) {
            score += 0.3
        }
        if items.contains(where: { $0.category == .accessory }) {
            score += 0.1
        }
        
        return score
    }
    
    private func hasStyleConflicts(items: [WardrobeItem]) -> Bool {
        // Détecter les conflits de style (ex: formel + décontracté)
        // À implémenter selon vos besoins
        return false
    }
    
    private func hasColorConflicts(items: [WardrobeItem]) -> Bool {
        // Détecter les conflits de couleurs flagrants
        let colors = items.map { $0.color.lowercased() }
        let uniqueColors = Set(colors)
        
        // Trop de couleurs différentes peut être un problème
        return uniqueColors.count > 5
    }
    
    // MARK: - Raison intelligente
    
    private func generateIntelligentReason(outfit: [WardrobeItem], score: Double) -> String {
        var reasons: [String] = []
        
        if score >= 85 {
            reasons.append("Excellent choix")
        } else if score >= 70 {
            reasons.append("Très bon choix")
        } else if score >= 60 {
            reasons.append("Bon choix")
        } else {
            reasons.append("Choix adapté")
        }
        
        // Ajouter des raisons spécifiques
        if outfit.contains(where: { $0.isFavorite }) {
            reasons.append("Inclut vos favoris")
        }
        
        let colorHarmony = calculateAdvancedColorHarmony(items: outfit)
        if colorHarmony > 0.8 {
            reasons.append("Couleurs harmonieuses")
        }
        
        let favoriteCount = outfit.filter { $0.isFavorite }.count
        if favoriteCount >= 2 {
            reasons.append("Multiple favoris")
        }
        
        return reasons.joined(separator: " • ")
    }
    
    private func determineDominantCondition(morning: WeatherCondition, afternoon: WeatherCondition) -> WeatherCondition {
        if morning == afternoon {
            return morning
        }
        
        // Prioriser les conditions restrictives
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

