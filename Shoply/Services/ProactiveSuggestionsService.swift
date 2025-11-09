//
//  ProactiveSuggestionsService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import Combine
import UserNotifications

/// Service de suggestions proactives intelligentes
class ProactiveSuggestionsService: ObservableObject {
    static let shared = ProactiveSuggestionsService()
    
    private let weatherService = WeatherService.shared
    private let wardrobeService = WardrobeService()
    private let outfitService = OutfitService()
    
    private init() {
        requestNotificationPermission()
        scheduleDailySuggestions()
    }
    
    // MARK: - Suggestions Proactives
    
    /// Vérifie et envoie des suggestions basées sur le contexte
    func checkAndSendSuggestions() {
        Task {
            await sendWeatherBasedSuggestion()
            await sendCalendarBasedSuggestion()
            await sendLowWearSuggestion()
        }
    }
    
    /// Suggestion basée sur la météo
    private func sendWeatherBasedSuggestion() async {
        guard let weather = weatherService.currentWeather else { return }
        
        // Si pluie prévue, suggérer un outfit adapté
        let conditionString = weather.condition.rawValue.lowercased()
        if conditionString.contains("pluie") || conditionString.contains("rain") {
            let items = wardrobeService.items
            let suitableItems = items.filter { item in
                // Chercher des vêtements imperméables ou adaptés à la pluie
                let material = item.material?.lowercased() ?? ""
                return material.contains("imperméable") || material.contains("waterproof") || item.category == .outerwear
            }
            
            if !suitableItems.isEmpty {
                sendNotification(
                    title: "🌧️ Pluie prévue aujourd'hui",
                    body: "Je vous suggère de porter un vêtement imperméable. Ouvrez Shoply pour voir mes suggestions !"
                )
            }
        }
        
        // Si température très basse ou très haute
        if weather.temperature < 5 {
            sendNotification(
                title: "❄️ Il fait très froid",
                body: "Pensez à bien vous couvrir ! Je peux vous suggérer des outfits chauds."
            )
        } else if weather.temperature > 30 {
            sendNotification(
                title: "☀️ Il fait très chaud",
                body: "Optez pour des vêtements légers et respirants. Je peux vous aider !"
            )
        }
    }
    
    /// Suggestion basée sur le calendrier iOS
    private func sendCalendarBasedSuggestion() async {
        // Vérifier les événements du calendrier pour aujourd'hui
        // Note: Nécessite l'autorisation d'accès au calendrier
        // Pour l'instant, on simule avec des suggestions génériques
        
        let hour = Calendar.current.component(.hour, from: Date())
        
        // Suggestion matinale (8h-9h)
        if hour >= 8 && hour < 9 {
            sendNotification(
                title: "☀️ Bonjour !",
                body: "Avez-vous pensé à votre outfit du jour ? Je peux vous aider à choisir !"
            )
        }
    }
    
    /// Suggestion pour les vêtements peu portés
    private func sendLowWearSuggestion() async {
        let items = wardrobeService.items
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        let unwornItems = items.filter { item in
            guard let lastWorn = item.lastWorn else { return true }
            return lastWorn < thirtyDaysAgo
        }
        
        if unwornItems.count >= 3 {
            sendNotification(
                title: "👔 Vêtements oubliés",
                body: "Vous avez \(unwornItems.count) vêtements qui n'ont pas été portés depuis 30 jours. Voulez-vous les réutiliser ?"
            )
        }
    }
    
    // MARK: - Planification
    
    private func scheduleDailySuggestions() {
        // Planifier une suggestion quotidienne à 8h du matin
        let content = UNMutableNotificationContent()
        content.title = "👔 Votre outfit du jour"
        content.body = "Je peux vous suggérer un outfit adapté à la météo d'aujourd'hui !"
        content.sound = .default
        
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_outfit_suggestion", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Erreur planification suggestion quotidienne: \(error)")
            }
        }
    }
    
    private func sendNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Erreur envoi notification: \(error)")
            }
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("⚠️ Erreur permission notifications: \(error)")
            }
        }
    }
}

