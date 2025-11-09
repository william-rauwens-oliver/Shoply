//
//  GamificationScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct GamificationScreen: View {
    @StateObject private var gamificationService = GamificationService.shared
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // En-tête avec niveau
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            // Niveau actuel
                            Card(cornerRadius: DesignSystem.Radius.lg) {
                                VStack(spacing: DesignSystem.Spacing.md) {
                                    Text("Niveau \(gamificationService.styleLevel.currentLevel)")
                                        .font(DesignSystem.Typography.title())
                                        .foregroundColor(AppColors.primaryText)
                                    
                                    Text(gamificationService.styleLevel.title)
                                        .font(DesignSystem.Typography.headline())
                                        .foregroundColor(AppColors.secondaryText)
                                    
                                    // Barre de progression XP
                                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                                        ProgressView(
                                            value: Double(gamificationService.styleLevel.currentXP),
                                            total: Double(gamificationService.styleLevel.xpToNextLevel)
                                        )
                                        .tint(AppColors.buttonPrimary)
                                        
                                        HStack {
                                            Text("\(gamificationService.styleLevel.currentXP) XP")
                                                .font(DesignSystem.Typography.caption())
                                                .foregroundColor(AppColors.secondaryText)
                                            
                                            Spacer()
                                            
                                            Text("\(gamificationService.styleLevel.xpToNextLevel) XP")
                                                .font(DesignSystem.Typography.caption())
                                                .foregroundColor(AppColors.secondaryText)
                                        }
                                    }
                                }
                                .padding(DesignSystem.Spacing.md)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.top, DesignSystem.Spacing.md)
                            
                            // Streak
                            Card(cornerRadius: DesignSystem.Radius.lg) {
                                HStack(spacing: DesignSystem.Spacing.xl) {
                                    VStack(spacing: DesignSystem.Spacing.xs) {
                                        Text("\(gamificationService.streak.currentStreak)")
                                            .font(DesignSystem.Typography.title2())
                                            .foregroundColor(AppColors.primaryText)
                                        Text("Jours consécutifs".localized)
                                            .font(DesignSystem.Typography.caption())
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                    
                                    VStack(spacing: DesignSystem.Spacing.xs) {
                                        Text("\(gamificationService.streak.longestStreak)")
                                            .font(DesignSystem.Typography.title2())
                                            .foregroundColor(AppColors.primaryText)
                                        Text("Record".localized)
                                            .font(DesignSystem.Typography.caption())
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(DesignSystem.Spacing.md)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            // Tabs
                            Picker("", selection: $selectedTab) {
                                Text("Badges".localized).tag(0)
                                Text("Achievements".localized).tag(1)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            // Contenu
                            if selectedTab == 0 {
                                badgesView
                            } else {
                                achievementsView
                            }
                        }
                        .padding(.bottom, DesignSystem.Spacing.xl)
                    }
                }
            }
            .navigationTitle("Gamification".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Gamification".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
            }
            .onAppear {
                gamificationService.updateBadges()
                gamificationService.updateStreak()
            }
        }
    }
    
    private var badgesView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
            GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
        ], spacing: DesignSystem.Spacing.md) {
            ForEach(gamificationService.badges) { badge in
                BadgeCard(badge: badge)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
    
    private var achievementsView: some View {
        LazyVStack(spacing: DesignSystem.Spacing.md) {
            ForEach(gamificationService.achievements) { achievement in
                AchievementCard(achievement: achievement)
            }
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
    }
}

struct BadgeCard: View {
    let badge: Badge
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(badge.isUnlocked ? badge.category.color.opacity(0.15) : AppColors.cardBackground)
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: badge.icon)
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(badge.isUnlocked ? badge.category.color : AppColors.secondaryText)
                }
                
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text(badge.name)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.primaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    Text(badge.description)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                    
                    // Progression
                    if !badge.isUnlocked {
                        ProgressView(value: badge.progress)
                            .tint(AppColors.buttonPrimary)
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                    } else {
                        Text("✓ Débloqué".localized)
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(.green)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
        }
        .opacity(badge.isUnlocked ? 1.0 : 0.6)
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            HStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(achievement.isUnlocked ? Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.15) : AppColors.cardBackground)
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(achievement.isUnlocked ? Color(red: 1.0, green: 0.84, blue: 0.0) : AppColors.secondaryText)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(achievement.title)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(achievement.description)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.secondaryText)
                    
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.yellow)
                        Text("\(achievement.points) points".localized)
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                
                Spacer()
                
                if achievement.isUnlocked {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
        .opacity(achievement.isUnlocked ? 1.0 : 0.6)
    }
}
