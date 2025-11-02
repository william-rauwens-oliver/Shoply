//
//  HomeView.swift
//  ShoplyCore - Android Compatible
//
//  Écran d'accueil SwiftUI pour Android (identique iOS)

import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

/// Vue d'accueil principale (identique iOS HomeScreen)
public struct HomeView: View {
    @StateObject private var wardrobeService = WardrobeService.shared
    @StateObject private var dataManager = DataManager.shared
    @State private var currentTime = Date()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                // Fond adaptatif
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // En-tête personnalisé
                        HeaderSectionView(currentTime: currentTime)
                            .padding(.top, 20)
                            .padding(.bottom, 32)
                        
                        // Grille de cartes
                        VStack(spacing: 16) {
                            // Carte principale - Sélection intelligente
                            NavigationLink(destination: SmartSelectionView()) {
                                SmartSelectionCardView()
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Deux colonnes
                            HStack(spacing: 16) {
                                // Garde-robe
                                NavigationLink(destination: WardrobeView()) {
                                    WardrobeCardView()
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Historique
                                NavigationLink(destination: HistoryView()) {
                                    HistoryCardView()
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // Calendrier
                            NavigationLink(destination: CalendarView()) {
                                CalendarCardView()
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120)
                    }
                }
                
                // Bulle de chat flottante
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingChatButtonView()
                            .padding(.trailing, 20)
                            .padding(.bottom, 100)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Shoply")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink(destination: FavoritesView()) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(AppColors.primaryText)
                        }
                        
                        NavigationLink(destination: ProfileView()) {
                            Image(systemName: "person.fill")
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

// MARK: - Sous-vues (identiques iOS)

struct HeaderSectionView: View {
    let currentTime: Date
    @StateObject private var dataManager = DataManager.shared
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<12: return "Bonjour"
        case 12..<17: return "Bon après-midi"
        case 17..<22: return "Bonsoir"
        default: return "Bonne nuit"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: currentTime).capitalized
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    if let profile = dataManager.loadUserProfile(), !profile.firstName.isEmpty {
                        Text("\(greeting) \(profile.firstName)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                    } else {
                        Text(greeting)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                    }
                    
                    Text(formattedDate)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
    }
}

struct SmartSelectionCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sélection Intelligente")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Météo automatique + IA")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .light))
                    .foregroundColor(AppColors.primaryText.opacity(0.6))
            }
            
            HStack(spacing: 12) {
                Image(systemName: "location.fill")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.buttonPrimaryText)
                
                Text("Détection automatique")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColors.buttonPrimaryText)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(AppColors.buttonPrimary)
            .roundedCorner(16)
        }
        .padding(28)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 20)
                .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 0.5)
        }
        .roundedCorner(20)
        .shadow(color: AppColors.shadow.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

struct WardrobeCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Garde-robe")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Ajoutez vos vêtements")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(AppColors.primaryText.opacity(0.7))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .background(AppColors.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 0.5)
        }
        .roundedCorner(18)
        .shadow(color: AppColors.shadow.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct HistoryCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Historique")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Outfits déjà portés")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "clock.fill")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(AppColors.primaryText.opacity(0.7))
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 120)
        .background(AppColors.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 0.5)
        }
        .roundedCorner(18)
        .shadow(color: AppColors.shadow.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct CalendarCardView: View {
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Calendrier")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.primaryText)
                
                Text("Planifiez vos outfits à l'avance")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "calendar")
                .font(.system(size: 28, weight: .light))
                .foregroundColor(AppColors.primaryText.opacity(0.7))
                .frame(width: 56, height: 56)
                .background(AppColors.buttonSecondary)
                .clipShape(Circle())
        }
        .padding(24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 0.5)
        }
        .roundedCorner(18)
        .shadow(color: AppColors.shadow.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct FloatingChatButtonView: View {
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
                Label("Historique des conversations", systemImage: "message.fill")
            }
        } label: {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.buttonPrimary.opacity(0.95),
                                AppColors.buttonPrimary.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppColors.buttonPrimaryText.opacity(0.4),
                                        AppColors.buttonPrimaryText.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .frame(width: 56, height: 56)
                    .shadow(color: AppColors.buttonPrimary.opacity(0.4), radius: 10, x: 0, y: 5)
                    .shadow(color: AppColors.buttonPrimary.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppColors.buttonPrimaryText)
            }
        }
        .sheet(isPresented: $showingChat) {
            ChatAIView()
        }
        .sheet(isPresented: $showingConversations) {
            ChatConversationsView()
        }
    }
}

struct ChatConversationsView: View {
    var body: some View {
        Text("Conversations")
            .navigationTitle("Conversations")
    }
}

// MARK: - Vues de navigation (stubs - à compléter)

public struct SmartSelectionView: View {
    public init() {}
    public var body: some View {
        Text("Sélection Intelligente")
            .navigationTitle("Sélection intelligente")
    }
}

public struct WardrobeView: View {
    public init() {}
    public var body: some View {
        Text("Garde-robe")
            .navigationTitle("Ma Garde-robe")
    }
}

public struct HistoryView: View {
    public init() {}
    public var body: some View {
        Text("Historique")
            .navigationTitle("Historique")
    }
}

public struct CalendarView: View {
    public init() {}
    public var body: some View {
        Text("Calendrier")
            .navigationTitle("Calendrier")
    }
}

public struct FavoritesView: View {
    public init() {}
    public var body: some View {
        Text("Favoris")
            .navigationTitle("Favoris")
    }
}

public struct ProfileView: View {
    public init() {}
    public var body: some View {
        Text("Profil")
            .navigationTitle("Profil")
    }
}

public struct ChatAIView: View {
    public init() {}
    public var body: some View {
        Text("Chat IA")
            .navigationTitle("Conseils de Style")
    }
}

