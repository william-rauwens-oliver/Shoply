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
    private let encoder = JSONEncoder()
    
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
            // 4 badges faciles seulement
            Badge(name: "Premier Pas", description: "Ajoutez votre premier vêtement à votre garde-robe", icon: "star.fill", category: .consistency, target: 1),
            Badge(name: "Collectionneur", description: "Construisez une garde-robe de 5 vêtements", icon: "tshirt.fill", category: .variety, target: 5),
            Badge(name: "Régulier", description: "Utilisez l'app 3 jours consécutifs", icon: "calendar", category: .consistency, target: 3),
            Badge(name: "Créatif", description: "Créez 3 outfits différents", icon: "paintbrush.fill", category: .creativity, target: 3)
        ]
    }
    
    /// Met à jour les badges selon l'activité
    func updateBadges() {
        let items = wardrobeService.items
        let outfits = outfitService.getAllOutfits()
        let historyStore = OutfitHistoryStore()
        
        // Badges de collection
        updateBadge(named: "Premier Pas", current: items.count)
        updateBadge(named: "Collectionneur", current: items.count)
        updateBadge(named: "Styliste", current: items.count)
        updateBadge(named: "Maître Garde-Robe", current: items.count)
        
        // Badges de régularité
        streak.update()
        updateBadge(named: "Régulier", current: streak.currentStreak)
        updateBadge(named: "Dévoué", current: streak.currentStreak)
        updateBadge(named: "Passionné", current: streak.currentStreak)
        
        // Badges de durabilité
        let totalWearCount = items.reduce(0) { $0 + $1.wearCount }
        updateBadge(named: "Éco-Conscient", current: totalWearCount)
        updateBadge(named: "Durable", current: totalWearCount)
        updateBadge(named: "Zéro Déchet", current: totalWearCount)
        
        // Badges de créativité
        updateBadge(named: "Créatif", current: outfits.count)
        updateBadge(named: "Artiste", current: outfits.count)
        updateBadge(named: "Expert Style", current: outfits.count)
        updateBadge(named: "Maître Mode", current: outfits.count)
        
        // Badges de style et historique
        let historyCount = historyStore.outfits.count
        updateBadge(named: "Historique", current: historyCount)
        updateBadge(named: "Vétéran", current: historyCount)
        
        // Badges de partage (simulation - à implémenter avec le service de partage)
        // Pour l'instant, on utilise le nombre d'outfits comme proxy
        updateBadge(named: "Partageur", current: outfits.count / 2)
        updateBadge(named: "Influenceur", current: outfits.count / 2)
        updateBadge(named: "Ambassadeur", current: outfits.count / 2)
        
        // Calculer le niveau basé sur l'XP
        calculateLevel()
        
        saveGamificationData()
    }
    
    // Permettre de “réclamer” manuellement un badge lorsque la progression est atteinte
    func claimBadge(_ badge: Badge) {
        guard let index = badges.firstIndex(where: { $0.id == badge.id }) else { return }
        let current = badges[index].current
        guard current >= badges[index].target else { return }
        // Marquer comme débloqué si pas déjà
        if badges[index].unlockedAt == nil {
            badges[index] = Badge(
                id: badges[index].id,
                name: badges[index].name,
                description: badges[index].description,
                icon: badges[index].icon,
                category: badges[index].category,
                target: badges[index].target,
                current: badges[index].current,
                unlockedAt: Date()
            )
            // Récompenser un peu d'XP
            addXP(10)
            saveGamificationData()
        }
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

