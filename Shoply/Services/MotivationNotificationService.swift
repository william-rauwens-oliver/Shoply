//
//  MotivationNotificationService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import Combine
import UserNotifications
import CoreLocation

/// Service pour les notifications motivationnelles du matin
class MotivationNotificationService: NSObject, ObservableObject {
    static let shared = MotivationNotificationService()
    
    @Published var isAuthorized = false
    @Published var notificationTime: Date?
    @Published var isEnabled = false
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private let wakeUpTimeKey = "motivation_notification_wake_up_time"
    private let isEnabledKey = "motivation_notification_enabled"
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        loadSettings()
        checkAuthorizationStatus()
    }
    
    // MARK: - Autorisation
    
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                isAuthorized = granted
            }
            if granted {
                await scheduleNextNotification()
            }
            return granted
        } catch {
            print("❌ Erreur demande autorisation notifications: \(error)")
            return false
        }
    }
    
    private func checkAuthorizationStatus() {
        notificationCenter.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }
    
    // MARK: - Gestion de l'heure de réveil
    
    /// Enregistre l'heure où l'utilisateur utilise son téléphone le matin
    func recordWakeUpTime(_ date: Date = Date()) {
        // Ne compter que les heures entre 5h et 11h du matin comme "réveil"
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        guard hour >= 5 && hour < 11 else { return }
        
        // Utiliser seulement l'heure (sans les minutes) pour la notification
        var components = calendar.dateComponents([.hour, .minute], from: date)
        components.second = 0
        
        if let wakeTime = calendar.date(bySettingHour: components.hour ?? 8, minute: components.minute ?? 0, second: 0, of: Date()) {
            UserDefaults.standard.set(wakeTime, forKey: wakeUpTimeKey)
            notificationTime = wakeTime
            Task {
                await scheduleNextNotification()
            }
        }
    }
    
    private func loadSettings() {
        if let wakeTime = UserDefaults.standard.object(forKey: wakeUpTimeKey) as? Date {
            notificationTime = wakeTime
        } else {
            // Par défaut: 8h00
            var components = DateComponents()
            components.hour = 8
            components.minute = 0
            notificationTime = Calendar.current.date(from: components)
        }
        
        // Activer par défaut si pas encore défini
        if UserDefaults.standard.object(forKey: isEnabledKey) == nil {
            isEnabled = true // Activé par défaut
            UserDefaults.standard.set(true, forKey: isEnabledKey)
        } else {
            isEnabled = UserDefaults.standard.bool(forKey: isEnabledKey)
        }
    }
    
    func setNotificationEnabled(_ enabled: Bool) {
        isEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: isEnabledKey)
        
        if enabled {
            Task {
                await scheduleNextNotification()
            }
        } else {
            cancelAllNotifications()
        }
    }
    
    // MARK: - Programmation des notifications
    
    func scheduleNextNotification() async {
        guard isEnabled, isAuthorized else {
            cancelAllNotifications()
            return
        }
        
        guard let wakeTime = notificationTime else { return }
        
        // Annuler les notifications existantes
        cancelAllNotifications()
        
        // Générer une phrase motivationnelle avec l'IA
        let motivationalPhrase = await generateMotivationalPhrase()
        
        // Créer le contenu de la notification
        let content = UNMutableNotificationContent()
        content.title = "☀️ Bonne journée !".localized
        content.body = motivationalPhrase
        content.sound = .default
        content.badge = 1
        
        // Programmer la notification pour demain matin
        let calendar = Calendar.current
        var dateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: wakeTime)
        dateComponents.day = (dateComponents.day ?? 1) + 1 // Demain
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
        let request = UNNotificationRequest(identifier: "morning_motivation_\(UUID().uuidString)", content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("✅ Notification programmée pour demain à \(wakeTime)")
        } catch {
            print("❌ Erreur programmation notification: \(error)")
        }
    }
    
    /// Programme une notification quotidienne récurrente
    func scheduleDailyNotifications() async {
        guard isEnabled, isAuthorized else {
            cancelAllNotifications()
            return
        }
        
        guard let wakeTime = notificationTime else { return }
        
        // Annuler les notifications existantes
        cancelAllNotifications()
        
        // Générer une phrase motivationnelle avec l'IA
        let motivationalPhrase = await generateMotivationalPhrase()
        
        // Créer le contenu de la notification
        let content = UNMutableNotificationContent()
        content.title = "☀️ Bonne journée !".localized
        content.body = motivationalPhrase
        content.sound = .default
        content.badge = 1
        
        // Programmer la notification quotidienne
        let calendar = Calendar.current
        let dateComponents = calendar.dateComponents([.hour, .minute], from: wakeTime)
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_morning_motivation", content: content, trigger: trigger)
        
        do {
            try await notificationCenter.add(request)
            print("✅ Notifications quotidiennes programmées pour \(wakeTime)")
        } catch {
            print("❌ Erreur programmation notifications quotidiennes: \(error)")
        }
    }
    
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
    }
    
    // MARK: - Génération de phrase motivationnelle
    
    private func generateMotivationalPhrase() async -> String {
        // Phrases motivationnelles variées
        let phrases = [
            "Commencez votre journée avec style ! Ouvrez Shoply pour découvrir votre outfit parfait aujourd'hui. 💫".localized,
            "Une nouvelle journée commence ! Choisissez un outfit qui reflète votre personnalité et boostez votre confiance. ✨".localized,
            "Le style, c'est l'expression de soi. Trouvez l'outfit idéal pour briller aujourd'hui ! 🌟".localized,
            "Chaque matin est une nouvelle opportunité de vous exprimer. Découvrez votre style avec Shoply ! 💎".localized,
            "S'habiller avec soin, c'est se respecter. Trouvez l'outfit parfait pour cette belle journée ! 👔".localized,
            "Votre style est votre signature. Créez l'outfit qui vous ressemble aujourd'hui ! 🎨".localized,
            "Commencez la journée du bon pied avec un outfit qui vous met en valeur ! 🌈".localized,
            "L'élégance commence par le choix de vos vêtements. Découvrez votre outfit parfait ! 👗".localized,
        ]
        
        // Pour l'instant, utiliser une phrase aléatoire
        // Plus tard, on pourra intégrer l'IA pour générer des phrases personnalisées
        return phrases.randomElement() ?? phrases[0]
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension MotivationNotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Afficher la notification même si l'app est au premier plan
        completionHandler([.banner, .sound, .badge])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        // L'utilisateur a tapé sur la notification
        // On pourrait ouvrir l'app directement sur la sélection d'outfit
        completionHandler()
    }
}

