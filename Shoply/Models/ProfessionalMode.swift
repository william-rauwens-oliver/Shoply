//
//  ProfessionalMode.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation

/// Mode professionnel avec suggestions pour entretiens et présentations
struct ProfessionalOutfit: Codable, Identifiable {
    let id: UUID
    var occasion: ProfessionalOccasion
    var items: [UUID] // IDs des vêtements
    var confidence: Double // 0.0 - 1.0
    var tips: [String]
    var createdAt: Date
    
    enum ProfessionalOccasion: String, Codable, CaseIterable {
        case jobInterview = "Entretien d'embauche"
        case presentation = "Présentation"
        case meeting = "Réunion importante"
        case networking = "Networking"
        case conference = "Conférence"
        case clientMeeting = "Rendez-vous client"
        
        var requiredFormality: FormalityLevel {
            switch self {
            case .jobInterview, .presentation, .clientMeeting:
                return .high
            case .meeting, .networking:
                return .medium
            case .conference:
                return .medium
            }
        }
        
        var colorRecommendations: [String] {
            switch self {
            case .jobInterview:
                return ["noir", "bleu marine", "gris", "beige"]
            case .presentation:
                return ["noir", "bleu", "gris", "blanc"]
            case .meeting:
                return ["bleu", "gris", "noir", "blanc"]
            case .networking:
                return ["bleu", "gris", "noir"]
            case .conference:
                return ["bleu", "gris", "noir", "blanc"]
            case .clientMeeting:
                return ["noir", "bleu marine", "gris"]
            }
        }
    }
    
    enum FormalityLevel: Int, Codable {
        case low = 1
        case medium = 2
        case high = 3
    }
    
    init(id: UUID = UUID(), occasion: ProfessionalOccasion, items: [UUID] = [], confidence: Double = 0.0, tips: [String] = [], createdAt: Date = Date()) {
        self.id = id
        self.occasion = occasion
        self.items = items
        self.confidence = confidence
        self.tips = tips
        self.createdAt = createdAt
    }
}

struct ProfessionalTip: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let category: TipCategory
    let priority: Int // 1-5
    
    enum TipCategory: String, Codable {
        case color = "Couleurs"
        case fit = "Taille"
        case accessories = "Accessoires"
        case grooming = "Soin"
        case etiquette = "Étiquette"
    }
    
    init(id: UUID = UUID(), title: String, description: String, category: TipCategory, priority: Int = 3) {
        self.id = id
        self.title = title
        self.description = description
        self.category = category
        self.priority = priority
    }
}

