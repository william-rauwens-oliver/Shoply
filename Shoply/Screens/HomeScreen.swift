//
//  HomeScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import Combine
import CoreLocation
#if !WIDGET_EXTENSION
import UserNotifications
import UIKit
#endif

struct HomeScreen: View {
    @StateObject private var wardrobeService = WardrobeService()
    @StateObject private var historyStore = OutfitHistoryStore()
    @StateObject private var collectionService = WardrobeCollectionService.shared
    @State private var currentTime = Date()
    @State private var showingChat = false
    @State private var showingConversations = false
    
    private var userProfile: UserProfile {
        DataManager.shared.loadUserProfile() ?? UserProfile()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // En-tête avec photo de profil
                        SimpleHeaderView(
                            userProfile: userProfile,
                            currentTime: currentTime
                        )
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                        
                        // Action principale
                        NavigationLink(destination: SmartOutfitSelectionScreen()) {
                            SimpleMainActionCard()
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 20)
                            
                        // Accès rapide
                        SimpleQuickAccessView()
                            .padding(.horizontal, 20)
                        
                        // Espace pour le bouton chat
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
                                    .frame(width: 56, height: 56)
                                    .shadow(color: AppColors.shadow.opacity(0.3), radius: 12, x: 0, y: 6)
                                
                                Image(systemName: "message.fill")
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(AppColors.buttonPrimaryText)
                            }
                        }
                        .padding(.trailing, 20)
                        .padding(.bottom, 20)
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
                    HStack(spacing: 16) {
                        NavigationLink(destination: FavoritesScreen()) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.primaryText)
                        }
                        
                        NavigationLink(destination: ProfileScreen()) {
                            if let photo = userProfile.profilePhoto {
                                Image(uiImage: photo)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 32, height: 32)
                                    .clipShape(Circle())
                            } else {
                            Image(systemName: "person.fill")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.primaryText)
                            }
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

// MARK: - Composants Simples

struct SimpleHeaderView: View {
    let userProfile: UserProfile
    let currentTime: Date
    @StateObject private var weatherService = WeatherService.shared
    @State private var greetingKey = "Bonjour"
    
    var body: some View {
        HStack(spacing: 16) {
            // Photo de profil
            if let photo = userProfile.profilePhoto {
                Image(uiImage: photo)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 64, height: 64)
                    .clipShape(Circle())
                    .overlay {
                        Circle()
                            .stroke(AppColors.buttonPrimary.opacity(0.3), lineWidth: 2)
                    }
                    .shadow(color: AppColors.shadow.opacity(0.2), radius: 8, x: 0, y: 4)
            } else {
                ZStack {
                Circle()
                        .fill(AppColors.buttonPrimary.opacity(0.15))
                        .frame(width: 64, height: 64)
                    
                        Image(systemName: "person.fill")
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(AppColors.buttonPrimary)
                    }
                    .overlay {
                        Circle()
                        .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 2)
                    }
            }
            
            // Texte de salutation
            VStack(alignment: .leading, spacing: 6) {
                if !userProfile.firstName.isEmpty {
                    Text("\(greetingKey.localized), \(userProfile.firstName)")
                        .font(DesignSystem.Typography.largeTitle())
                        .foregroundColor(AppColors.primaryText)
                } else {
                    Text(greetingKey.localized)
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
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        return formatter.string(from: currentTime)
    }
    
    private func updateGreeting() {
        if let location = weatherService.location {
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            guard !lat.isNaN && !lon.isNaN && !lat.isInfinite && !lon.isInfinite else {
        let hour = Calendar.current.component(.hour, from: currentTime)
                greetingKey = (hour >= 5 && hour < 18) ? "Bonjour" : "Bonsoir"
                return
            }
            greetingKey = SunsetService.shared.getGreeting(
                latitude: lat,
                longitude: lon,
                currentTime: currentTime
            )
        } else {
            let hour = Calendar.current.component(.hour, from: currentTime)
            greetingKey = (hour >= 5 && hour < 18) ? "Bonjour" : "Bonsoir"
        }
    }
}

struct SimpleMainActionCard: View {
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(AppColors.buttonPrimary.opacity(0.15))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(AppColors.buttonPrimary)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Sélection Intelligente".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Générez des outfits adaptés".localized)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.secondaryText)
            }
            .padding(24)
        }
    }
}

struct SimpleQuickAccessView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Accès rapide".localized)
                .font(DesignSystem.Typography.headline())
                .foregroundColor(AppColors.primaryText)
                .padding(.horizontal, 4)
            
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                SimpleQuickAccessButton(
                    icon: "tshirt.fill",
                    title: "Garde-robe",
                    destination: WardrobeManagementScreen()
                )
                
                SimpleQuickAccessButton(
                    icon: "clock.fill",
                    title: "Historique",
                    destination: OutfitHistoryScreen()
                )
                
                SimpleQuickAccessButton(
                    icon: "folder.fill",
                    title: "Collections",
                    destination: CollectionsScreen()
                )
                
                SimpleQuickAccessButton(
                    icon: "heart.fill",
                    title: "Wishlist",
                    destination: WishlistScreen()
                )
                
                SimpleQuickAccessButton(
                    icon: "airplane",
                    title: "Voyage",
                    destination: TravelModeScreen()
                )
                
                SimpleQuickAccessButton(
                    icon: "briefcase.fill",
                    title: "Occasions",
                    destination: OccasionsScreen()
                )
                
                SimpleQuickAccessButton(
                    icon: "calendar",
                    title: "Calendrier",
                    destination: OutfitCalendarScreen()
                )
                
                SimpleQuickAccessButton(
                    icon: "star.fill",
                    title: "Badges",
                    destination: GamificationScreen()
                )
            }
        }
    }
}

struct SimpleQuickAccessButton<Destination: View>: View {
    let icon: String
    let title: String
    let destination: Destination
    @State private var isPressed = false
    
    var body: some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 10) {
                        Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AppColors.buttonPrimary)
                    .frame(width: 50, height: 50)
                    .background(AppColors.buttonSecondary)
                    .clipShape(Circle())
                    
                    Text(title.localized)
                    .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.primaryText)
                    .lineLimit(1)
                }
                .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}
