//
//  HomeScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import Combine

struct HomeScreen: View {
    @StateObject private var wardrobeService = WardrobeService()
    @StateObject private var settingsManager = AppSettingsManager.shared
    @State private var currentTime = Date()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond blanc épuré
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // En-tête personnalisé avec accès au profil
                        HeaderSection(currentTime: currentTime)
                            .padding(.top, 20)
                            .padding(.bottom, 32)
                        
                        // Grille de cartes épurées
                        VStack(spacing: 16) {
                            // Carte principale - Sélection intelligente (plus grande)
                            NavigationLink(destination: SmartOutfitSelectionScreen()) {
                                SmartSelectionCard()
                            }
                            .buttonStyle(PlainButtonStyle())
                            
                            // Deux colonnes pour les cartes secondaires
                            HStack(spacing: 16) {
                                // Garde-robe
                                NavigationLink(destination: WardrobeManagementScreen()) {
                                    WardrobeManagementCard()
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                // Historique
                                NavigationLink(destination: OutfitHistoryScreen()) {
                                    HistoryCard()
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // Calendrier (pleine largeur)
                            NavigationLink(destination: OutfitCalendarScreen()) {
                                CalendarCard()
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 120) // Plus d'espace pour la bulle de chat
                    }
                }
                
                // Bulle de chat flottante
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingChatButton()
                            .padding(.trailing, 20)
                            .padding(.bottom, 100) // Plus d'espace pour la navbar en bas
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Shoply".localized)
                        .font(.playfairDisplayBold(size: 24))
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        NavigationLink(destination: FavoritesScreen()) {
                            Image(systemName: "heart.fill")
                                .foregroundColor(AppColors.primaryText)
                        }
                        
                        NavigationLink(destination: ProfileScreen()) {
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

// Section d'en-tête
struct HeaderSection: View {
    let currentTime: Date
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var settingsManager = AppSettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    if let profile = dataManager.loadUserProfile(), !profile.firstName.isEmpty {
                        Text("\(LocalizedString.localized("Bonjour", for: settingsManager.selectedLanguage)) \(profile.firstName)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                    } else {
                        Text(greeting.localized)
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
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<12:
            return "Bonjour"
        case 12..<17:
            return "Bon après-midi"
        case 17..<22:
            return "Bonsoir"
        default:
            return "Bonne nuit"
            }
        }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM"
        // Utiliser la locale selon la langue sélectionnée
        let localeId = getLocaleId(for: settingsManager.selectedLanguage)
        formatter.locale = Locale(identifier: localeId)
        return formatter.string(from: currentTime).capitalized
    }
    
    private func getLocaleId(for language: AppLanguage) -> String {
        switch language {
        // Les 10 langues les plus parlées au monde
        case .english: return "en_US"
        case .chineseSimplified: return "zh_Hans_CN"
        case .hindi: return "hi_IN"
        case .spanish: return "es_ES"
        case .french: return "fr_FR"
        case .arabic: return "ar_SA"
        case .bengali: return "bn_BD"
        case .russian: return "ru_RU"
        case .portuguese: return "pt_PT"
        case .indonesian: return "id_ID"
        }
    }
}

// Carte de sélection intelligente (design épuré)
struct SmartSelectionCard: View {
    @StateObject private var settingsManager = AppSettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sélection Intelligente".localized)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.primaryText)

                    Text("Météo automatique + IA".localized)
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
                
                Text("Détection automatique".localized)
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
        .id(settingsManager.selectedLanguage)
    }
}

// Carte calendrier (design épuré)
struct CalendarCard: View {
    @StateObject private var settingsManager = AppSettingsManager.shared
    
    var body: some View {
        HStack(spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Calendrier".localized)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColors.primaryText)
                
                Text("Planifiez vos outfits à l'avance".localized)
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
        .id("calendar-\(settingsManager.selectedLanguage)")
    }
}

struct WardrobeManagementCard: View {
    @StateObject private var settingsManager = AppSettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Garde-robe".localized)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.primaryText)

                    Text("Ajoutez vos vêtements".localized)
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
        .id("wardrobe-\(settingsManager.selectedLanguage)")
    }
}

// Carte historique (design épuré)
struct HistoryCard: View {
    @StateObject private var settingsManager = AppSettingsManager.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Historique".localized)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.primaryText)

                    Text("Outfits déjà portés".localized)
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
        .id("history-\(settingsManager.selectedLanguage)")
    }
}

// Carte génération de recettes
struct RecipeCard: View {
    @StateObject private var settingsManager = AppSettingsManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Recettes".localized)
                        .font(.playfairDisplayBold(size: 22))
                        .foregroundColor(AppColors.primaryText)

                    Text("Photo → Recette".localized)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
                }

                Spacer()

                Image(systemName: "camera.fill")
                    .font(.system(size: 28))
                    .foregroundColor(AppColors.primaryText)
            }

            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.accent)
                
                Text("Photographiez vos ingrédients et obtenez une recette personnalisée".localized)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppColors.secondaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(24)
        .cleanCard(cornerRadius: 24)
        .id("recipe-\(settingsManager.selectedLanguage)")
    }
}

#Preview {
    NavigationStack {
        HomeScreen()
            .environmentObject(DataManager.shared)
    }
}
