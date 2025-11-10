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
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                    // En-tête avec niveau
                        ModernLevelCard(gamificationService: gamificationService)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                            
                            // Streak
                        ModernStreakCard(gamificationService: gamificationService)
                            .padding(.horizontal, 20)
                            
                        // Tabs modernes
                        ModernTabPicker(selectedTab: $selectedTab)
                            .padding(.horizontal, 20)
                            
                            // Contenu
                            if selectedTab == 0 {
                            modernBadgesView
                            } else {
                            modernAchievementsView
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Gamification".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Gamification".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButtonWithLongPress()
                }
            }
            .onAppear {
                gamificationService.updateBadges()
                gamificationService.updateStreak()
            }
        }
    }
    
    private var modernBadgesView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ], spacing: 16) {
            ForEach(gamificationService.badges) { badge in
                ModernBadgeCard(badge: badge)
            }
        }
        .padding(.horizontal, 20)
    }
    
    private var modernAchievementsView: some View {
        LazyVStack(spacing: 16) {
            ForEach(gamificationService.achievements) { achievement in
                ModernAchievementCard(achievement: achievement)
                    .padding(.horizontal, 20)
            }
        }
    }
}

// MARK: - Composants Modernes

struct ModernLevelCard: View {
    @ObservedObject var gamificationService: GamificationService
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(spacing: 20) {
                VStack(spacing: 8) {
                    Text("Niveau \(gamificationService.styleLevel.currentLevel)")
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                        .fontWeight(.bold)
                    
                    Text(gamificationService.styleLevel.title)
                        .font(DesignSystem.Typography.subheadline())
                        .foregroundColor(AppColors.secondaryText)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("\(gamificationService.styleLevel.currentXP) XP")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(AppColors.secondaryText)
                        
                        Spacer()
                        
                        Text("\(gamificationService.styleLevel.xpToNextLevel) XP")
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    ProgressView(
                        value: Double(gamificationService.styleLevel.currentXP),
                        total: Double(gamificationService.styleLevel.xpToNextLevel)
                    )
                    .tint(AppColors.buttonPrimary)
                    .scaleEffect(x: 1, y: 1.5, anchor: .center)
                }
            }
            .padding(20)
        }
    }
}

struct ModernStreakCard: View {
    @ObservedObject var gamificationService: GamificationService
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            HStack(spacing: 32) {
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange.opacity(0.2), .orange.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "flame.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    
                    Text("\(gamificationService.streak.currentStreak)")
                        .font(DesignSystem.Typography.title())
                        .foregroundColor(AppColors.primaryText)
                        .fontWeight(.bold)
                    
                    Text("Jours consécutifs".localized)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Divider()
                    .frame(height: 60)
                
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.yellow.opacity(0.2), .yellow.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "star.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(.yellow)
                    }
                    
                    Text("\(gamificationService.streak.longestStreak)")
                        .font(DesignSystem.Typography.title())
                        .foregroundColor(AppColors.primaryText)
                        .fontWeight(.bold)
                    
                    Text("Record".localized)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
        }
    }
}

struct ModernTabPicker: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<2) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    Text(index == 0 ? "Badges".localized : "Achievements".localized)
                        .font(DesignSystem.Typography.footnote())
                        .fontWeight(.semibold)
                        .foregroundColor(selectedTab == index ? AppColors.buttonPrimaryText : AppColors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == index ? AppColors.buttonPrimary : Color.clear)
                }
            }
        }
        .background(AppColors.buttonSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
    }
}

struct ModernBadgeCard: View {
    let badge: Badge
    @State private var isPressed = false
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: badge.isUnlocked ? [
                                    badge.category.color.opacity(0.2),
                                    badge.category.color.opacity(0.1)
                                ] : [
                                    AppColors.buttonSecondary,
                                    AppColors.buttonSecondary.opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 72, height: 72)
                    
                    Image(systemName: badge.icon)
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(badge.isUnlocked ? badge.category.color : AppColors.secondaryText)
                }
                
                VStack(spacing: 6) {
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
                    
                    if !badge.isUnlocked {
                        ProgressView(value: badge.progress)
                            .tint(badge.category.color)
                            .scaleEffect(x: 1, y: 1.2, anchor: .center)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                            Text("Débloqué".localized)
                            .font(DesignSystem.Typography.caption())
                        }
                            .foregroundColor(.green)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(16)
        }
        .opacity(badge.isUnlocked ? 1.0 : 0.7)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct ModernAchievementCard: View {
    let achievement: Achievement
    @State private var isPressed = false
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: achievement.isUnlocked ? [
                                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.2),
                                    Color(red: 1.0, green: 0.84, blue: 0.0).opacity(0.1)
                                ] : [
                                    AppColors.buttonSecondary,
                                    AppColors.buttonSecondary.opacity(0.5)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: achievement.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(achievement.isUnlocked ? Color(red: 1.0, green: 0.84, blue: 0.0) : AppColors.secondaryText)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(achievement.title)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(achievement.description)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.secondaryText)
                        .lineLimit(2)
                    
                    HStack(spacing: 6) {
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
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.green)
                }
            }
            .padding(20)
        }
        .opacity(achievement.isUnlocked ? 1.0 : 0.7)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
