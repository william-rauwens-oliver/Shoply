//
//  RomanticMode.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation

/// Mode romantique/social avec suggestions pour dates et occasions spéciales
struct RomanticOutfit: Codable, Identifiable {
    let id: UUID
    var occasion: RomanticOccasion
    var items: [UUID] // IDs des vêtements
    var confidence: Double // 0.0 - 1.0
    var tips: [String]
    var createdAt: Date
    
    enum RomanticOccasion: String, Codable, CaseIterable {
        case firstDate = "Premier rendez-vous"
        case romanticDinner = "Dîner romantique"
        case anniversary = "Anniversaire"
        case wedding = "Mariage"
        case party = "Soirée / Fête"
        case dateNight = "Soirée en amoureux"
        case brunch = "Brunch"
        case cinema = "Cinéma"
        case concert = "Concert"
        case beach = "Plage / Pique-nique"
        case casualDate = "Rendez-vous décontracté"
        
        var requiredFormality: FormalityLevel {
            switch self {
            case .wedding, .anniversary, .romanticDinner:
                return .high
            case .firstDate, .dateNight, .party:
                return .medium
            case .brunch, .cinema, .concert, .beach, .casualDate:
                return .low
            }
        }
        
        var colorRecommendations: [String] {
            switch self {
            case .firstDate:
                return ["noir", "blanc", "rouge", "rose", "bleu"]
            case .romanticDinner:
                return ["noir", "rouge", "bleu marine", "blanc"]
            case .anniversary:
                return ["rouge", "noir", "blanc", "doré"]
            case .wedding:
                return ["blanc", "beige", "pastel", "bleu clair"]
            case .party:
                return ["noir", "rouge", "doré", "argenté"]
            case .dateNight:
                return ["noir", "rouge", "bleu", "blanc"]
            case .brunch:
                return ["pastel", "blanc", "beige", "bleu clair"]
            case .cinema:
                return ["noir", "gris", "bleu", "blanc"]
            case .concert:
                return ["noir", "gris", "rouge", "bleu"]
            case .beach:
                return ["blanc", "bleu", "pastel", "beige"]
            case .casualDate:
                return ["jean", "blanc", "gris", "pastel"]
            }
        }
    }
    
    enum FormalityLevel: Int, Codable {
        case low = 1
        case medium = 2
        case high = 3
    }
    
    init(id: UUID = UUID(), occasion: RomanticOccasion, items: [UUID] = [], confidence: Double = 0.0, tips: [String] = [], createdAt: Date = Date()) {
        self.id = id
        self.occasion = occasion
        self.items = items
        self.confidence = confidence
        self.tips = tips
        self.createdAt = createdAt
    }
}

