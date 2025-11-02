//
//  HomeScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import Combine
import CoreLocation

struct HomeScreen: View {
    @StateObject private var wardrobeService = WardrobeService()
    @StateObject private var settingsManager = AppSettingsManager.shared
    @State private var currentTime = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond ultra-simple et épuré avec opacité maximale
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // En-tête minimaliste
                        SimpleHeader(currentTime: currentTime)
                            .padding(.top, 28)
                            .padding(.bottom, 36)
                        
                        // Grille de cartes ultra-épurée
                        VStack(spacing: 18) {
                            // Carte principale - Sélection intelligente
                            NavigationLink(destination: SmartOutfitSelectionScreen()) {
                                SimpleSelectionCard()
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Deux colonnes pour les cartes secondaires
                            HStack(spacing: 16) {
                                // Garde-robe
                                NavigationLink(destination: WardrobeManagementScreen()) {
                                    SimpleWardrobeCard()
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Historique
                                NavigationLink(destination: OutfitHistoryScreen()) {
                                    SimpleHistoryCard()
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // Calendrier
                            NavigationLink(destination: OutfitCalendarScreen()) {
                                SimpleCalendarCard()
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 140)
                    }
                }
                
                // Bouton chat simple et direct
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        SimpleChatButton()
                            .padding(.trailing, 20)
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Shoply")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink(destination: FavoritesScreen()) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(AppColors.primaryText)
                        }
                        
                        NavigationLink(destination: ProfileScreen()) {
                            Image(systemName: "person.fill")
                                .font(.system(size: 17, weight: .medium))
                                .foregroundColor(AppColors.primaryText)
                        }
                    }
                }
            }
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            currentTime = Date()
        }
    }
}

// En-tête minimaliste
struct SimpleHeader: View {
    let currentTime: Date
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var weatherService = WeatherService.shared
    @State private var greetingText = "Bonjour"
    
    var body: some View {
                VStack(alignment: .leading, spacing: 8) {
                    if let profile = dataManager.loadUserProfile(), !profile.firstName.isEmpty {
                Text("\(greetingText), \(profile.firstName)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                    } else {
                Text(greetingText)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                    }
                    
                    Text(formattedDate)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
        }
        .padding(.horizontal, 20)
        .onAppear {
            updateGreeting()
        }
    }
    
    private func updateGreeting() {
        if let location = weatherService.location {
            let isDay = SunsetService.shared.isDaytime(
                latitude: location.coordinate.latitude,
                longitude: location.coordinate.longitude,
                currentTime: currentTime
            )
            greetingText = isDay ? "Bonjour" : "Bonsoir"
        } else {
        let hour = Calendar.current.component(.hour, from: currentTime)
            greetingText = (hour >= 5 && hour < 18) ? "Bonjour" : "Bonsoir"
            }
        }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: currentTime).capitalized
    }
}

// Carte sélection intelligente - Design ultra-simple
struct SimpleSelectionCard: View {
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Sélection IA")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(AppColors.primaryText)
                
                Text("Créez vos tenues avec l'intelligence artificielle")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Image(systemName: "sparkles")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(AppColors.buttonPrimary)
                .frame(width: 60, height: 60)
                .background(AppColors.buttonPrimary.opacity(0.1))
                .clipShape(Circle())
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppColors.cardBorder.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: AppColors.shadow.opacity(0.3), radius: 12, x: 0, y: 4)
    }
}

// Carte garde-robe - Design simple
struct SimpleWardrobeCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppColors.buttonPrimary)
                
                Text("Garde-robe")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
            }
            
            Text("Vos vêtements")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .frame(height: 110)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppColors.cardBorder.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: AppColors.shadow.opacity(0.3), radius: 10, x: 0, y: 3)
    }
}

// Carte historique - Design simple
struct SimpleHistoryCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppColors.buttonPrimary)
                
                Text("Historique")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
            }
            
            Text("Tenues portées")
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .frame(height: 110)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .stroke(AppColors.cardBorder.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: AppColors.shadow.opacity(0.3), radius: 10, x: 0, y: 3)
    }
}

// Carte calendrier - Design simple
struct SimpleCalendarCard: View {
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Calendrier")
                    .font(.system(size: 22, weight: .bold))
                        .foregroundColor(AppColors.primaryText)

                Text("Planifiez vos tenues")
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
                }

                Spacer()

            Image(systemName: "calendar")
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(AppColors.buttonPrimary)
                .frame(width: 56, height: 56)
                .background(AppColors.buttonPrimary.opacity(0.1))
                .clipShape(Circle())
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Material.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppColors.cardBorder.opacity(0.5), lineWidth: 1)
                )
        )
        .shadow(color: AppColors.shadow.opacity(0.3), radius: 12, x: 0, y: 4)
            }
}

// Bouton chat avec menu et historique
struct SimpleChatButton: View {
    @State private var showingChat = false
    @State private var showingConversations = false
    
    var body: some View {
        Menu {
            Button {
                showingChat = true
            } label: {
                Label("Nouvelle conversation", systemImage: "square.and.pencil")
            }
            
            Button {
                showingConversations = true
            } label: {
                Label("Historique", systemImage: "message.fill")
            }
        } label: {
                Image(systemName: "sparkles")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(AppColors.buttonPrimaryText)
                .frame(width: 56, height: 56)
                .background(AppColors.buttonPrimary)
                .clipShape(Circle())
                .shadow(color: AppColors.shadow.opacity(0.4), radius: 12, x: 0, y: 6)
        }
        .sheet(isPresented: $showingChat) {
            NavigationStack {
                ChatAIScreen()
            }
        }
        .sheet(isPresented: $showingConversations) {
            NavigationStack {
                ChatConversationsScreen()
            }
        }
    }
}

#Preview {
    NavigationStack {
        HomeScreen()
            .environmentObject(DataManager.shared)
    }
}
