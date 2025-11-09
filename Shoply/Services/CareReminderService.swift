//
//  CareReminderService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import Combine
import UserNotifications

/// Service de gestion des rappels d'entretien
class CareReminderService: ObservableObject {
    static let shared = CareReminderService()
    
    @Published var reminders: [CareReminder] = []
    
    private init() {
        requestNotificationPermission()
        loadReminders()
        scheduleReminders()
    }
    
    // MARK: - Gestion des Rappels
    
    func addReminder(_ reminder: CareReminder) {
        reminders.append(reminder)
        saveReminders()
        scheduleReminder(reminder)
    }
    
    func updateReminder(_ reminder: CareReminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index] = reminder
            saveReminders()
            scheduleReminder(reminder)
        }
    }
    
    func deleteReminder(_ reminder: CareReminder) {
        reminders.removeAll { $0.id == reminder.id }
        saveReminders()
        cancelReminder(reminder)
    }
    
    func markAsCompleted(_ reminder: CareReminder) {
        if let index = reminders.firstIndex(where: { $0.id == reminder.id }) {
            reminders[index].isCompleted = true
            saveReminders()
            cancelReminder(reminder)
        }
    }
    
    func getRemindersForItem(_ itemId: UUID) -> [CareReminder] {
        return reminders.filter { $0.itemId == itemId && !$0.isCompleted }
    }
    
    func getUpcomingReminders(days: Int = 7) -> [CareReminder] {
        let futureDate = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        return reminders.filter { reminder in
            !reminder.isCompleted &&
            reminder.dueDate <= futureDate &&
            reminder.dueDate >= Date()
        }.sorted { $0.dueDate < $1.dueDate }
    }
    
    // MARK: - Génération Automatique
    
    func generateRemindersForItem(_ item: WardrobeItem) {
        // Générer un rappel de lavage si l'item a été porté plusieurs fois
        if item.wearCount >= 3 {
            let washDate = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
            let washReminder = CareReminder(
                itemId: item.id,
                type: .wash,
                dueDate: washDate,
                notes: "L'item '\(item.name)' a été porté \(item.wearCount) fois"
            )
            addReminder(washReminder)
        }
        
        // Générer un rappel de changement de saison
        let currentSeason = getCurrentSeason()
        if !item.season.contains(currentSeason) && !item.season.contains(.allSeason) {
            let seasonalDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            let seasonalReminder = CareReminder(
                itemId: item.id,
                type: .seasonal,
                dueDate: seasonalDate,
                notes: "L'item '\(item.name)' n'est pas adapté à la saison actuelle"
            )
            addReminder(seasonalReminder)
        }
    }
    
    private func getCurrentSeason() -> Season {
        let month = Calendar.current.component(.month, from: Date())
        switch month {
        case 12, 1, 2: return .winter
        case 3, 4, 5: return .spring
        case 6, 7, 8: return .summer
        case 9, 10, 11: return .autumn
        default: return .allSeason
        }
    }
    
    // MARK: - Notifications
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("⚠️ Erreur permission notifications: \(error)")
            }
        }
    }
    
    private func scheduleReminders() {
        for reminder in reminders where !reminder.isCompleted {
            scheduleReminder(reminder)
        }
    }
    
    private func scheduleReminder(_ reminder: CareReminder) {
        let content = UNMutableNotificationContent()
        content.title = getReminderTitle(for: reminder.type)
        content.body = getReminderBody(for: reminder)
        content.sound = .default
        
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.dueDate),
            repeats: false
        )
        
        let request = UNNotificationRequest(
            identifier: reminder.id.uuidString,
            content: content,
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Erreur planification rappel: \(error)")
            }
        }
    }
    
    private func cancelReminder(_ reminder: CareReminder) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [reminder.id.uuidString])
    }
    
    private func getReminderTitle(for type: ReminderType) -> String {
        switch type {
        case .wash: return "Lavage nécessaire"
        case .dryClean: return "Nettoyage à sec"
        case .repair: return "Réparation nécessaire"
        case .iron: return "Repassage"
        case .store: return "Rangement"
        case .seasonal: return "Changement de saison"
        }
    }
    
    private func getReminderBody(for reminder: CareReminder) -> String {
        let baseMessage = getReminderTitle(for: reminder.type)
        if let notes = reminder.notes {
            return "\(baseMessage): \(notes)"
        }
        return baseMessage
    }
    
    // MARK: - Persistance
    
    private func saveReminders() {
        if let encoded = try? JSONEncoder().encode(reminders) {
            UserDefaults.standard.set(encoded, forKey: "care_reminders")
        }
    }
    
    private func loadReminders() {
        if let data = UserDefaults.standard.data(forKey: "care_reminders"),
           let decoded = try? JSONDecoder().decode([CareReminder].self, from: data) {
            reminders = decoded
        }
    }
}

