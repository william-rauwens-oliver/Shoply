//
//  Gamification.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import SwiftUI

/// Badge obtenu par l'utilisateur
struct Badge: Codable, Identifiable {
    let id: UUID
    let name: String
    let description: String
    let icon: String
    let category: BadgeCategory
    let unlockedAt: Date?
    let progress: Double // 0.0 - 1.0
    let target: Int
    let current: Int
    
    var isUnlocked: Bool {
        return unlockedAt != nil
    }
    
    init(id: UUID = UUID(), name: String, description: String, icon: String, category: BadgeCategory, target: Int, current: Int = 0, unlockedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.description = description
        self.icon = icon
        self.category = category
        self.target = target
        self.current = current
        self.unlockedAt = unlockedAt
        self.progress = min(Double(current) / Double(target), 1.0)
    }
}

enum BadgeCategory: String, Codable, CaseIterable {
    case consistency = "Cohérence"
    case variety = "Variété"
    case sustainability = "Durabilité"
    case creativity = "Créativité"
    case style = "Style"
    case social = "Social"
    
    var color: Color {
        switch self {
        case .consistency: return .blue
        case .variety: return .purple
        case .sustainability: return .green
        case .creativity: return .orange
        case .style: return .pink
        case .social: return .yellow
        }
    }
}

/// Achievement (accomplissement)
struct Achievement: Codable, Identifiable {
    let id: UUID
    let title: String
    let description: String
    let icon: String
    let points: Int
    let unlockedAt: Date?
    
    var isUnlocked: Bool {
        return unlockedAt != nil
    }
}

/// Niveau de style de l'utilisateur
struct StyleLevel: Codable {
    var currentLevel: Int
    var currentXP: Int
    var xpToNextLevel: Int
    var totalXP: Int
    var title: String
    
    init() {
        self.currentLevel = 1
        self.currentXP = 0
        self.xpToNextLevel = 100
        self.totalXP = 0
        self.title = "Débutant"
    }
    
    mutating func addXP(_ amount: Int) {
        currentXP += amount
        totalXP += amount
        
        while currentXP >= xpToNextLevel {
            currentXP -= xpToNextLevel
            currentLevel += 1
            xpToNextLevel = Int(Double(xpToNextLevel) * 1.5) // Augmentation progressive
            updateTitle()
        }
    }
    
    private mutating func updateTitle() {
        switch currentLevel {
        case 1...5: title = "Débutant"
        case 6...10: title = "Styliste"
        case 11...20: title = "Expert"
        case 21...30: title = "Maître"
        case 31...50: title = "Légende"
        default: title = "Icône"
        }
    }
}

/// Streak (série)
struct Streak: Codable {
    var currentStreak: Int // Jours consécutifs
    var longestStreak: Int
    var lastActivityDate: Date?
    
    init(currentStreak: Int = 0, longestStreak: Int = 0, lastActivityDate: Date? = nil) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.lastActivityDate = lastActivityDate
    }
    
    mutating func update() {
        let today = Calendar.current.startOfDay(for: Date())
        let lastDate = lastActivityDate.map { Calendar.current.startOfDay(for: $0) }
        
        if let lastDate = lastDate {
            let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: today).day ?? 0
            
            if daysSince == 1 {
                // Continuer le streak
                currentStreak += 1
            } else if daysSince > 1 {
                // Streak rompu
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                }
                currentStreak = 1
            }
        } else {
            // Premier jour
            currentStreak = 1
        }
        
        lastActivityDate = Date()
    }
}

