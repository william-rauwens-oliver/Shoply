//
//  CareReminder.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation

/// Rappel d'entretien pour un vêtement
struct CareReminder: Codable, Identifiable {
    let id: UUID
    let itemId: UUID
    var type: ReminderType
    var dueDate: Date
    var isCompleted: Bool
    var notes: String?
    var createdAt: Date
    
    init(id: UUID = UUID(), itemId: UUID, type: ReminderType, dueDate: Date, isCompleted: Bool = false, notes: String? = nil, createdAt: Date = Date()) {
        self.id = id
        self.itemId = itemId
        self.type = type
        self.dueDate = dueDate
        self.isCompleted = isCompleted
        self.notes = notes
        self.createdAt = createdAt
    }
}

enum ReminderType: String, Codable, CaseIterable {
    case wash = "Lavage"
    case dryClean = "Nettoyage à sec"
    case repair = "Réparation"
    case iron = "Repassage"
    case store = "Rangement"
    case seasonal = "Changement de saison"
    
    var icon: String {
        switch self {
        case .wash: return "drop.fill"
        case .dryClean: return "sparkles"
        case .repair: return "wrench.fill"
        case .iron: return "flame.fill"
        case .store: return "archivebox.fill"
        case .seasonal: return "calendar"
        }
    }
}

/// Instructions de soin pour un vêtement
struct CareInstructions: Codable {
    var washingTemperature: String?
    var washingMethod: String?
    var dryingMethod: String?
    var ironingTemperature: String?
    var dryCleanOnly: Bool
    var bleachAllowed: Bool
    var notes: String?
}

