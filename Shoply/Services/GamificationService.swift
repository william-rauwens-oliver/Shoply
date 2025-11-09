//
//  GamificationService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation

/// Service de gamification (badges, achievements, niveaux, streaks)
class GamificationService {
    static let shared = GamificationService()
    
    private let wardrobeService = WardrobeService()
    private let outfitService = OutfitService()
    
    @Published var badges: [Badge] = []
    @Published var achievements: [Achievement] = []
    @Published var styleLevel = StyleLevel()
    @Published var streak = Streak()
    
    private init() {
        loadGamificationData()
        initializeBadges()
        initializeAchievements()
    }
    
    // MARK: - Badges
    
    private func initializeBadges() {
        badges = [
            Badge(name: "Premier Pas", description: "Ajoutez votre premier vêtement", icon: "star.fill", category: .consistency, target: 1),
            Badge(name: "Collectionneur", description: "Ajoutez 10 vêtements", icon: "tshirt.fill", category: .variety, target: 10),
            Badge(name: "Styliste", description: "Ajoutez 50 vêtements", icon: "sparkles", category: .variety, target: 50),
            Badge(name: "7 Jours", description: "Utilisez l'app 7 jours consécutifs", icon: "calendar", category: .consistency, target: 7),
            Badge(name: "30 Jours", description: "Utilisez l'app 30 jours consécutifs", icon: "calendar.badge.clock", category: .consistency, target: 30),
            Badge(name: "Éco-Conscient", description: "Portez 100 fois vos vêtements", icon: "leaf.fill", category: .sustainability, target: 100),
            Badge(name: "Créatif", description: "Créez 20 outfits différents", icon: "paintbrush.fill", category: .creativity, target: 20),
            Badge(name: "Expert", description: "Créez 100 outfits différents", icon: "crown.fill", category: .creativity, target: 100),
            Badge(name: "Partageur", description: "Partagez 10 outfits", icon: "square.and.arrow.up.fill", category: .social, target: 10),
            Badge(name: "Perfectionniste", description: "Notez 50 outfits", icon: "star.circle.fill", category: .style, target: 50),
            Badge(name: "Historique", description: "Portez 20 outfits différents", icon: "clock.fill", category: .consistency, target: 20)
        ]
    }
    
    /// Met à jour les badges selon l'activité
    func updateBadges() {
        let items = wardrobeService.items
        let outfits = outfitService.getAllOutfits()
        let historyStore = OutfitHistoryStore()
        
        // Badge "Premier Pas"
        updateBadge(named: "Premier Pas", current: items.count)
        
        // Badge "Collectionneur"
        updateBadge(named: "Collectionneur", current: items.count)
        
        // Badge "Styliste"
        updateBadge(named: "Styliste", current: items.count)
        
        // Badge "7 Jours" et "30 Jours"
        streak.update()
        updateBadge(named: "7 Jours", current: streak.currentStreak)
        updateBadge(named: "30 Jours", current: streak.currentStreak)
        
        // Badge "Éco-Conscient"
        let totalWearCount = items.reduce(0) { $0 + $1.wearCount }
        updateBadge(named: "Éco-Conscient", current: totalWearCount)
        
        // Badge "Créatif" et "Expert"
        updateBadge(named: "Créatif", current: outfits.count)
        updateBadge(named: "Expert", current: outfits.count)
        
        // Badge basé sur l'historique
        let historyCount = historyStore.outfits.count
        updateBadge(named: "Historique", current: historyCount)
        
        // Calculer le niveau basé sur l'XP
        calculateLevel()
        
        saveGamificationData()
    }
    
    /// Calcule et met à jour le niveau (utilise la logique de StyleLevel)
    private func calculateLevel() {
        // Le calcul est déjà fait dans StyleLevel.addXP
        // On met juste à jour le titre si nécessaire
    }
    
    private func updateBadge(named name: String, current: Int) {
        if let index = badges.firstIndex(where: { $0.name == name }) {
            var badge = badges[index]
            if badge.current < badge.target {
                badge = Badge(
                    id: badge.id,
                    name: badge.name,
                    description: badge.description,
                    icon: badge.icon,
                    category: badge.category,
                    target: badge.target,
                    current: min(current, badge.target),
                    unlockedAt: current >= badge.target ? (badge.unlockedAt ?? Date()) : nil
                )
                badges[index] = badge
                
                // Ajouter XP si débloqué
                if badge.isUnlocked && badge.unlockedAt == Date() {
                    addXP(10)
                }
            }
        }
    }
    
    // MARK: - Achievements
    
    private func initializeAchievements() {
        achievements = [
            Achievement(id: UUID(), title: "Débutant", description: "Créez votre premier outfit", icon: "star.fill", points: 10, unlockedAt: nil),
            Achievement(id: UUID(), title: "Variété", description: "Portez 10 couleurs différentes", icon: "paintpalette.fill", points: 20, unlockedAt: nil),
            Achievement(id: UUID(), title: "Durabilité", description: "Portez un vêtement 20 fois", icon: "leaf.fill", points: 30, unlockedAt: nil),
            Achievement(id: UUID(), title: "Maître Style", description: "Créez 50 outfits avec une note moyenne de 4+", icon: "crown.fill", points: 50, unlockedAt: nil)
        ]
    }
    
    // MARK: - Niveaux et XP
    
    func addXP(_ amount: Int) {
        styleLevel.addXP(amount)
        saveGamificationData()
    }
    
    // MARK: - Streaks
    
    func updateStreak() {
        streak.update()
        saveGamificationData()
    }
    
    // MARK: - Persistance
    
    private func saveGamificationData() {
        let encoder = JSONEncoder()
        
        if let badgesData = try? encoder.encode(badges),
           let achievementsData = try? encoder.encode(achievements),
           let levelData = try? encoder.encode(styleLevel),
           let streakData = try? encoder.encode(streak) {
            UserDefaults.standard.set(badgesData, forKey: "gamification_badges")
            UserDefaults.standard.set(achievementsData, forKey: "gamification_achievements")
            UserDefaults.standard.set(levelData, forKey: "gamification_level")
            UserDefaults.standard.set(streakData, forKey: "gamification_streak")
        }
    }
    
    private func loadGamificationData() {
        let decoder = JSONDecoder()
        
        if let badgesData = UserDefaults.standard.data(forKey: "gamification_badges"),
           let loadedBadges = try? decoder.decode([Badge].self, from: badgesData) {
            badges = loadedBadges
        }
        
        if let achievementsData = UserDefaults.standard.data(forKey: "gamification_achievements"),
           let loadedAchievements = try? decoder.decode([Achievement].self, from: achievementsData) {
            achievements = loadedAchievements
        }
        
        if let levelData = UserDefaults.standard.data(forKey: "gamification_level"),
           let loadedLevel = try? decoder.decode(StyleLevel.self, from: levelData) {
            styleLevel = loadedLevel
        }
        
        if let streakData = UserDefaults.standard.data(forKey: "gamification_streak"),
           let loadedStreak = try? decoder.decode(Streak.self, from: streakData) {
            streak = loadedStreak
        }
    }
}

import Combine

extension GamificationService: ObservableObject {}

