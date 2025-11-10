//
//  TravelModeService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import Combine

/// Service de gestion du mode voyage
class TravelModeService: ObservableObject {
    static let shared = TravelModeService()
    
    @Published var travelPlans: [TravelPlan] = []
    private let weatherService = WeatherService.shared
    private let wardrobeService = WardrobeService()
    
    private init() {
        loadTravelPlans()
    }
    
    // MARK: - Gestion des Plans de Voyage
    
    func createTravelPlan(destination: String, startDate: Date, endDate: Date) -> TravelPlan {
        var plan = TravelPlan(
            destination: destination,
            startDate: startDate,
            endDate: endDate
        )
        
        // La checklist sera générée par Gemini, on laisse vide au départ
        plan.checklist = []
        
        // Ajouter le plan d'abord pour qu'il soit visible
        travelPlans.append(plan)
        saveTravelPlans()
        
        // Générer les prévisions météo et la checklist avec Gemini de manière asynchrone
        Task {
            // Trouver l'index du plan dans le tableau (sur MainActor)
            let planIndex = await MainActor.run {
                travelPlans.firstIndex(where: { $0.id == plan.id })
            }
            
            guard let planIndex = planIndex else { return }
            
            // Récupérer le plan (sur MainActor)
            let currentPlan = await MainActor.run {
                travelPlans[planIndex]
            }
            
            // Générer les prévisions météo
            let updatedPlan = await generateWeatherForecast(for: currentPlan)
            
            // Mettre à jour le plan avec les prévisions météo
            await MainActor.run {
                travelPlans[planIndex] = updatedPlan
                saveTravelPlans()
            }
            
            // Générer la checklist avec Gemini après avoir la météo
            await generateGeminiChecklist(planIndex: planIndex)
        }
        
        return plan
    }
    
    func updateTravelPlan(_ plan: TravelPlan) {
        if let index = travelPlans.firstIndex(where: { $0.id == plan.id }) {
            travelPlans[index] = plan
            saveTravelPlans()
        }
    }
    
    func deleteTravelPlan(_ plan: TravelPlan) {
        travelPlans.removeAll { $0.id == plan.id }
        saveTravelPlans()
    }
    
    func deleteAllTravelPlans() {
        travelPlans.removeAll()
        saveTravelPlans()
    }
    
    func removeExpiredPlans() {
        let today = Date()
        let expiredPlans = travelPlans.filter { $0.endDate < today }
        if !expiredPlans.isEmpty {
            travelPlans.removeAll { plan in
                expiredPlans.contains { $0.id == plan.id }
            }
            saveTravelPlans()
        }
    }
    
    // MARK: - Checklist
    
    func toggleChecklistItem(planId: UUID, itemId: UUID) {
        if let planIndex = travelPlans.firstIndex(where: { $0.id == planId }),
           let itemIndex = travelPlans[planIndex].checklist.firstIndex(where: { $0.id == itemId }) {
            travelPlans[planIndex].checklist[itemIndex].isChecked.toggle()
            saveTravelPlans()
        }
    }
    
    func addChecklistItem(planId: UUID, item: TravelChecklistItem) {
        if let planIndex = travelPlans.firstIndex(where: { $0.id == planId }) {
            travelPlans[planIndex].checklist.append(item)
            saveTravelPlans()
        }
    }
    
    // MARK: - Suggestions d'Outfits
    
    func suggestOutfitsForTravel(plan: TravelPlan) -> [PlannedOutfit] {
        let items = wardrobeService.items
        var suggestedOutfits: [PlannedOutfit] = []
        
        let calendar = Calendar.current
        var currentDate = plan.startDate
        
        while currentDate <= plan.endDate {
            // Trouver la météo pour ce jour
            let weather = plan.weatherForecast.first { weather in
                calendar.isDate(weather.date, inSameDayAs: currentDate)
            }
            
            // Suggérer un outfit basé sur la météo
            let outfit = suggestOutfitForDate(date: currentDate, weather: weather, items: items)
            suggestedOutfits.append(outfit)
            
            // Passer au jour suivant
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? plan.endDate
        }
        
        return suggestedOutfits
    }
    
    private func suggestOutfitForDate(date: Date, weather: DayWeather?, items: [WardrobeItem]) -> PlannedOutfit {
        var selectedItems: [UUID] = []
        
        // Sélectionner des items adaptés à la météo
        if let weather = weather {
            let suitableItems = items.filter { item in
                // Logique de sélection basée sur la météo
                if weather.temperature < 10 {
                    return item.season.contains(.winter) || item.season.contains(.autumn)
                } else if weather.temperature > 25 {
                    return item.season.contains(.summer) || item.season.contains(.spring)
                } else {
                    return true
                }
            }
            
            // Prendre un haut, un bas, des chaussures
            if let top = suitableItems.first(where: { $0.category == .top }) {
                selectedItems.append(top.id)
            }
            if let bottom = suitableItems.first(where: { $0.category == .bottom }) {
                selectedItems.append(bottom.id)
            }
            if let shoes = suitableItems.first(where: { $0.category == .shoes }) {
                selectedItems.append(shoes.id)
            }
        } else {
            // Si pas de météo, prendre les premiers items disponibles
            selectedItems = Array(items.prefix(3).map { $0.id })
        }
        
        return PlannedOutfit(
            date: date,
            itemIds: selectedItems,
            occasion: nil,
            notes: weather != nil ? "Température: \(Int(weather!.temperature))°C" : nil
        )
    }
    
    // MARK: - Helpers
    
    private func generateDefaultChecklist(duration: Int) -> [TravelChecklistItem] {
        var checklist: [TravelChecklistItem] = []
        
        // Vêtements
        checklist.append(TravelChecklistItem(item: "Sous-vêtements", category: .clothing, quantity: duration + 2))
        checklist.append(TravelChecklistItem(item: "T-shirts/Chemises", category: .clothing, quantity: duration))
        checklist.append(TravelChecklistItem(item: "Pantalons/Shorts", category: .clothing, quantity: duration / 2 + 1))
        checklist.append(TravelChecklistItem(item: "Chaussures", category: .clothing, quantity: 2))
        
        // Accessoires
        checklist.append(TravelChecklistItem(item: "Sac à dos/Valise", category: .accessories))
        checklist.append(TravelChecklistItem(item: "Accessoires (ceinture, etc.)", category: .accessories))
        
        // Documents
        checklist.append(TravelChecklistItem(item: "Passeport/Carte d'identité", category: .documents))
        checklist.append(TravelChecklistItem(item: "Billets/Réservations", category: .documents))
        
        // Électronique
        checklist.append(TravelChecklistItem(item: "Chargeur téléphone", category: .electronics))
        checklist.append(TravelChecklistItem(item: "Chargeur appareil photo", category: .electronics))
        
        return checklist
    }
    
    private func generateWeatherForecast(for plan: TravelPlan) async -> TravelPlan {
        // Générer des prévisions météo pour chaque jour du voyage
        let calendar = Calendar.current
        var currentDate = plan.startDate
        var forecasts: [DayWeather] = []
        var updatedPlan = plan
        
        // Générer des données de test basées sur la destination
        while currentDate <= plan.endDate {
            // Générer des températures plus réalistes selon la destination
            let baseTemp: Double
            let destinationLower = plan.destination.lowercased()
            if destinationLower.contains("new york") || destinationLower.contains("paris") || destinationLower.contains("london") {
                baseTemp = 15.0
            } else if destinationLower.contains("tokyo") || destinationLower.contains("seoul") {
                baseTemp = 20.0
            } else if destinationLower.contains("dubai") || destinationLower.contains("singapore") || destinationLower.contains("bangkok") {
                baseTemp = 30.0
            } else if destinationLower.contains("sydney") || destinationLower.contains("melbourne") {
                baseTemp = 18.0
            } else {
                baseTemp = 20.0
            }
            
            let temperature = baseTemp + Double.random(in: -5...5)
            let condition = ["Ensoleillé", "Nuageux", "Pluvieux"].randomElement() ?? "Ensoleillé"
            let icon = condition == "Ensoleillé" ? "sun.max.fill" : (condition == "Pluvieux" ? "cloud.rain.fill" : "cloud.fill")
            
            forecasts.append(DayWeather(
                date: currentDate,
                temperature: temperature,
                condition: condition,
                icon: icon
            ))
            
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate) ?? plan.endDate
        }
        
        updatedPlan.weatherForecast = forecasts
        return updatedPlan
    }
    
    private func generateGeminiChecklist(planIndex: Int) async {
        // Récupérer le plan sur MainActor
        let plan: TravelPlan? = await MainActor.run {
            guard planIndex < travelPlans.count else { return nil }
            return travelPlans[planIndex]
        }
        
        guard let plan = plan else { return }
        
        let geminiService = GeminiService.shared
        guard geminiService.isEnabled else { return }
        
        let userProfile = DataManager.shared.loadUserProfile() ?? UserProfile()
        
        // Calculer la saison
        let calendar = Calendar.current
        let month = calendar.component(.month, from: plan.startDate)
        let season: String
        switch month {
        case 12, 1, 2: season = "hiver"
        case 3, 4, 5: season = "printemps"
        case 6, 7, 8: season = "été"
        case 9, 10, 11: season = "automne"
        default: season = "printemps"
        }
        
        // Préparer les informations météo
        let avgTemp = plan.weatherForecast.isEmpty ? 20.0 : plan.weatherForecast.map { $0.temperature }.reduce(0, +) / Double(plan.weatherForecast.count)
        let conditions = plan.weatherForecast.isEmpty ? "Non disponible" : plan.weatherForecast.map { $0.condition }.joined(separator: ", ")
        
        do {
            let checklistText = try await geminiService.generateTravelChecklist(
                destination: plan.destination,
                startDate: plan.startDate,
                endDate: plan.endDate,
                duration: plan.duration,
                season: season,
                averageTemperature: avgTemp,
                weatherConditions: conditions,
                userProfile: userProfile
            )
            
            // Parser la réponse de Gemini pour créer les items de checklist
            print("🔍 Réponse Gemini pour \(plan.destination):\n\(checklistText)")
            let checklistItems = parseGeminiChecklist(checklistText)
            print("✅ Items parsés: \(checklistItems.count)")
            
            if !checklistItems.isEmpty {
                await MainActor.run {
                    // Vérifier que l'index est toujours valide
                    guard planIndex < travelPlans.count else { return }
                    var updatedPlan = travelPlans[planIndex]
                    updatedPlan.checklist = checklistItems
                    travelPlans[planIndex] = updatedPlan
        saveTravelPlans()
                    print("✅ Checklist mise à jour pour \(updatedPlan.destination)")
                }
            } else {
                print("⚠️ Aucun item parsé de la réponse Gemini")
            }
        } catch {
            print("❌ Erreur lors de la génération de la checklist Gemini: \(error)")
        }
    }
    
    private func parseGeminiChecklist(_ text: String) -> [TravelChecklistItem] {
        var items: [TravelChecklistItem] = []
        let lines = text.components(separatedBy: .newlines)
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { continue }
            
            // Ignorer les lignes qui ne sont pas des items (titres, descriptions, etc.)
            if trimmed.count > 100 || (trimmed.hasPrefix("#") && !trimmed.hasPrefix("-") && !trimmed.hasPrefix("•")) {
                continue
            }
            
            // Parser les lignes au format "- Item (quantité)" ou "- Item" ou "Item (quantité)"
            var itemText = trimmed
            var quantity: Int? = nil
            var category: ChecklistCategory = .other
            
            // Enlever les puces
            if itemText.hasPrefix("-") || itemText.hasPrefix("•") || itemText.hasPrefix("*") {
                itemText = String(itemText.dropFirst()).trimmingCharacters(in: .whitespaces)
            }
            
            // Détecter la quantité - formats: "(5)", "(quantité: 5)", "x5", "5x", etc.
            if let quantityRange = itemText.range(of: #"\((\d+)\)"#, options: .regularExpression) {
                let quantityStr = String(itemText[quantityRange])
                quantity = Int(quantityStr.replacingOccurrences(of: "[()]", with: "", options: .regularExpression))
                itemText = itemText.replacingOccurrences(of: quantityStr, with: "").trimmingCharacters(in: .whitespaces)
            } else if let quantityMatch = itemText.range(of: #"(\d+)\s*x"#, options: .regularExpression) {
                let quantityStr = String(itemText[quantityMatch])
                quantity = Int(quantityStr.replacingOccurrences(of: "x", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces))
                itemText = itemText.replacingOccurrences(of: quantityStr, with: "").trimmingCharacters(in: .whitespaces)
            } else if let quantityMatch = itemText.range(of: #"x\s*(\d+)"#, options: .regularExpression) {
                let quantityStr = String(itemText[quantityMatch])
                quantity = Int(quantityStr.replacingOccurrences(of: "x", with: "", options: .caseInsensitive).trimmingCharacters(in: .whitespaces))
                itemText = itemText.replacingOccurrences(of: quantityStr, with: "").trimmingCharacters(in: .whitespaces)
            } else if let quantityMatch = itemText.range(of: #"quantité[:\s]+(\d+)"#, options: [.regularExpression, .caseInsensitive]) {
                let quantityStr = String(itemText[quantityMatch])
                quantity = Int(quantityStr.replacingOccurrences(of: #"quantité[:\s]+"#, with: "", options: [.regularExpression, .caseInsensitive]).trimmingCharacters(in: .whitespaces))
                itemText = itemText.replacingOccurrences(of: quantityStr, with: "").trimmingCharacters(in: .whitespaces)
            }
            
            // Détecter la catégorie (ordre important - vérifier les plus spécifiques en premier)
            let lowercased = itemText.lowercased()
            if lowercased.contains("chaussure") || lowercased.contains("soulier") || lowercased.contains("basket") {
                category = .clothing
            } else if lowercased.contains("sous-vêtement") || lowercased.contains("sous vetement") || lowercased.contains("culotte") || lowercased.contains("slip") {
                category = .clothing
            } else if lowercased.contains("vêtement") || lowercased.contains("tshirt") || lowercased.contains("chemise") || lowercased.contains("pantalon") || lowercased.contains("robe") || lowercased.contains("short") || lowercased.contains("jean") || lowercased.contains("pull") || lowercased.contains("sweat") {
                category = .clothing
            } else if lowercased.contains("document") || lowercased.contains("passeport") || lowercased.contains("billet") || lowercased.contains("réservation") || lowercased.contains("reservation") || lowercased.contains("carte d'identité") || lowercased.contains("carte identite") {
                category = .documents
            } else if lowercased.contains("chargeur") || lowercased.contains("téléphone") || lowercased.contains("telephone") || lowercased.contains("appareil photo") || lowercased.contains("ordinateur") || lowercased.contains("tablette") || lowercased.contains("écouteurs") || lowercased.contains("ecouteurs") {
                category = .electronics
            } else if lowercased.contains("dentifrice") || lowercased.contains("shampooing") || lowercased.contains("savon") || lowercased.contains("gel douche") || lowercased.contains("déodorant") || lowercased.contains("deodorant") || lowercased.contains("brosse à dents") || lowercased.contains("brosse a dents") || lowercased.contains("serviette") {
                category = .toiletries
            } else if lowercased.contains("accessoire") || lowercased.contains("sac") || lowercased.contains("valise") || lowercased.contains("ceinture") || lowercased.contains("montre") || lowercased.contains("lunettes") || lowercased.contains("bijou") {
                category = .accessories
            }
            
            items.append(TravelChecklistItem(
                item: itemText,
                category: category,
                quantity: quantity
            ))
        }
        
        return items
    }
    
    // MARK: - Persistance
    
    private func saveTravelPlans() {
        if let encoded = try? JSONEncoder().encode(travelPlans) {
            UserDefaults.standard.set(encoded, forKey: "travel_plans")
        }
    }
    
    private func loadTravelPlans() {
        if let data = UserDefaults.standard.data(forKey: "travel_plans"),
           let decoded = try? JSONDecoder().decode([TravelPlan].self, from: data) {
            travelPlans = decoded
        }
    }
}

