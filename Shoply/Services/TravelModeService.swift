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
        
        // Générer la checklist par défaut
        plan.checklist = generateDefaultChecklist(duration: plan.duration)
        
        // Générer les prévisions météo (si disponibles)
        Task {
            await generateWeatherForecast(for: &plan)
        }
        
        travelPlans.append(plan)
        saveTravelPlans()
        
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
    
    private func generateWeatherForecast(for plan: inout TravelPlan) async {
        // Générer des prévisions météo pour chaque jour du voyage
        let calendar = Calendar.current
        var currentDate = plan.startDate
        var forecasts: [DayWeather] = []
        
        while currentDate <= plan.endDate {
            // Utiliser le service météo pour obtenir les prévisions
            // Pour l'instant, générer des données de test
            let temperature = Double.random(in: 10...30)
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
        
        plan.weatherForecast = forecasts
        saveTravelPlans()
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

