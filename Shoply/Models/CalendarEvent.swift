//
//  CalendarEvent.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import EventKit

/// Événement du calendrier pour suggestions d'outfits
struct CalendarEvent: Codable, Identifiable {
    let id: String
    let title: String
    let startDate: Date
    let endDate: Date
    let location: String?
    let notes: String?
    var suggestedOutfit: SuggestedOutfit?
    var eventType: EventType
    
    enum EventType: String, Codable {
        case meeting = "Réunion"
        case interview = "Entretien"
        case party = "Fête"
        case date = "Rendez-vous"
        case casual = "Casual"
        case formal = "Formel"
        case sport = "Sport"
        case other = "Autre"
    }
    
    init(id: String, title: String, startDate: Date, endDate: Date, location: String? = nil, notes: String? = nil, eventType: EventType = .other, suggestedOutfit: SuggestedOutfit? = nil) {
        self.id = id
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.location = location
        self.notes = notes
        self.eventType = eventType
        self.suggestedOutfit = suggestedOutfit
    }
}

struct SuggestedOutfit: Codable {
    let itemIds: [UUID]
    let style: String
    let notes: String?
    let confidence: Double // 0.0 - 1.0
}

