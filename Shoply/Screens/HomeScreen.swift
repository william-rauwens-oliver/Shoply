//
//  HomeScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import Combine
#if !WIDGET_EXTENSION
import UserNotifications
import UIKit
#endif

struct HomeScreen: View {
    @StateObject private var wardrobeService = WardrobeService()
    @StateObject private var settingsManager = AppSettingsManager.shared
    @StateObject private var historyStore = OutfitHistoryStore()
    @State private var currentTime = Date()
    @State private var showingChat = false
    @State private var showingConversations = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Header avec photo de profil
                        HeaderView(currentTime: currentTime)
                            .padding(.top, DesignSystem.Spacing.lg)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        // Carte principale - Sélection intelligente
                        NavigationLink(destination: SmartOutfitSelectionScreen()) {
                            MainActionCard()
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        // Deux cartes côte à côte
                        HStack(spacing: DesignSystem.Spacing.md) {
                            NavigationLink(destination: WardrobeManagementScreen()) {
                                QuickActionCard(
                                    icon: "tshirt.fill",
                                    title: "Garde-robe",
                                    value: "\(wardrobeService.items.count)",
                                    color: AppColors.buttonPrimary
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            NavigationLink(destination: OutfitHistoryScreen()) {
                                QuickActionCard(
                                    icon: "clock.fill",
                                    title: "Historique",
                                    value: "\(historyStore.outfits.count)",
                                    color: AppColors.buttonPrimary
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        // Section fonctionnalités
                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                            HStack {
                                Text("Fonctionnalités".localized)
                                    .font(DesignSystem.Typography.title2())
                                    .foregroundColor(AppColors.primaryText)
                                Spacer()
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            // Grille de fonctionnalités
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                                GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
                            ], spacing: DesignSystem.Spacing.md) {
                                FeatureGridItem(icon: "chart.bar.fill", title: "Statistiques", destination: StatisticsScreen(), color: AppColors.buttonPrimary)
                                FeatureGridItem(icon: "folder.fill", title: "Collections", destination: CollectionsScreen(), color: AppColors.buttonPrimary)
                                FeatureGridItem(icon: "heart.fill", title: "Wishlist", destination: WishlistScreen(), color: AppColors.buttonPrimary)
                                FeatureGridItem(icon: "airplane", title: "Voyage", destination: TravelModeScreen(), color: AppColors.buttonPrimary)
                                FeatureGridItem(icon: "star.fill", title: "Badges", destination: GamificationScreen(), color: AppColors.buttonPrimary)
                                FeatureGridItem(icon: "barcode.viewfinder", title: "Scanner", destination: BarcodeScannerScreen(), color: AppColors.buttonPrimary)
                                FeatureGridItem(icon: "dollarsign.circle.fill", title: "Prix", destination: PriceComparisonScreen(), color: AppColors.buttonPrimary)
                                FeatureGridItem(icon: "briefcase.fill", title: "Pro", destination: ProfessionalModeScreen(), color: AppColors.buttonPrimary)
                                FeatureGridItem(icon: "book.fill", title: "Lookbooks", destination: LookbooksScreen(), color: AppColors.buttonPrimary)
                                FeatureGridItem(icon: "chart.line.uptrend.xyaxis", title: "Tendances", destination: TrendAnalysisScreen(), color: AppColors.buttonPrimary)
                                FeatureGridItem(icon: "calendar", title: "Événements", destination: CalendarEventsScreen(), color: AppColors.buttonPrimary)
                                FeatureGridItem(icon: "square.and.arrow.up", title: "Partage", destination: SocialShareScreen(), color: AppColors.buttonPrimary)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                        
                        // Espace pour le bouton flottant
                        Spacer()
                            .frame(height: 80)
                    }
                }
                
                // Bouton chat flottant
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Menu {
                            Button(action: {
                                showingChat = true
                            }) {
                                Label("Nouvelle conversation".localized, systemImage: "square.and.pencil")
                            }
                            
                            Button(action: {
                                showingConversations = true
                            }) {
                                Label("Historique".localized, systemImage: "clock.arrow.circlepath")
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(AppColors.buttonPrimary)
                                    .frame(width: 60, height: 60)
                                    .shadow(color: AppColors.shadow.opacity(0.3), radius: 12, x: 0, y: 6)
                                
                                Image(systemName: "message.fill")
                                    .font(.system(size: 22, weight: .medium))
                                    .foregroundColor(AppColors.buttonPrimaryText)
                            }
                        }
                        .padding(.trailing, DesignSystem.Spacing.lg)
                        .padding(.bottom, DesignSystem.Spacing.lg)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Shoply")
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        NavigationLink(destination: FavoritesScreen()) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.primaryText)
                        }
                        
                        NavigationLink(destination: ProfileScreen()) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.primaryText)
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showingChat) {
            ChatAIScreen()
        }
        .sheet(isPresented: $showingConversations) {
            NavigationStack {
                ChatConversationsScreen()
            }
        }
        .onAppear {
            clearApplicationBadge()
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            currentTime = Date()
        }
    }
    
    #if !WIDGET_EXTENSION
    private func clearApplicationBadge() {
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print("⚠️ Erreur badge: \(error.localizedDescription)")
                }
            }
        } else {
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
    #endif
}

// MARK: - Composants HomeScreen

struct HeaderView: View {
    let currentTime: Date
    @StateObject private var dataManager = DataManager.shared
    @State private var greetingKey = "Bonjour"
    
    private var greetingText: String {
        greetingKey.localized
    }
    
    private var profile: UserProfile? {
        dataManager.loadUserProfile()
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.lg) {
            // Photo de profil
            if let profile = profile, let photo = profile.profilePhoto {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(AppColors.cardBorder, lineWidth: 2)
                    }
            } else {
                Circle()
                    .fill(AppColors.buttonSecondary)
                    .frame(width: 56, height: 56)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 24, weight: .light))
                            .foregroundColor(AppColors.primaryText)
                    }
                    .overlay {
                        Circle()
                            .stroke(AppColors.cardBorder, lineWidth: 2)
                    }
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                if let profile = profile, !profile.firstName.isEmpty {
                    Text("\(greetingText), \(profile.firstName)")
                        .font(DesignSystem.Typography.largeTitle())
                        .foregroundColor(AppColors.primaryText)
                        .lineLimit(1)
                } else {
                    Text(greetingText)
                        .font(DesignSystem.Typography.largeTitle())
                        .foregroundColor(AppColors.primaryText)
                }
                
                Text(formattedDate)
                    .font(DesignSystem.Typography.subheadline())
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
        }
        .onAppear {
            updateGreeting()
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: AppSettingsManager.shared.selectedLanguage.rawValue)
        formatter.dateStyle = .full
        return formatter.string(from: currentTime)
    }
    
    private func updateGreeting() {
        let hour = Calendar.current.component(.hour, from: currentTime)
        if hour < 12 {
            greetingKey = "Bonjour"
        } else if hour < 18 {
            greetingKey = "Bon après-midi"
        } else {
            greetingKey = "Bonsoir"
        }
    }
}

struct MainActionCard: View {
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            HStack(spacing: DesignSystem.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(AppColors.buttonSecondary)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(AppColors.primaryText)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text("Sélection Intelligente".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Générez des outfits adaptés".localized)
                        .font(DesignSystem.Typography.subheadline())
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.secondaryText)
            }
            .padding(DesignSystem.Spacing.lg)
        }
    }
}

struct QuickActionCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(spacing: DesignSystem.Spacing.lg) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(color)
                }
                
                VStack(spacing: DesignSystem.Spacing.xs) {
                    Text(title.localized)
                        .font(DesignSystem.Typography.footnote())
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text(value)
                        .font(DesignSystem.Typography.title())
                        .foregroundColor(AppColors.primaryText)
                        .fontWeight(.bold)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.lg)
        }
    }
}

struct FeatureGridItem<Destination: View>: View {
    let icon: String
    let title: String
    let destination: Destination
    let color: Color
    
    var body: some View {
        NavigationLink(destination: destination) {
            Card(cornerRadius: DesignSystem.Radius.lg) {
                VStack(spacing: DesignSystem.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(color)
                    }
                    
                    Text(title.localized)
                        .font(DesignSystem.Typography.footnote())
                        .foregroundColor(AppColors.primaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 110)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}
