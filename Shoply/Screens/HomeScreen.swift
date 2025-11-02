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
                    VStack(spacing: 24) {
                        // En-tête personnalisé avec accès au profil
                        HeaderSection(currentTime: currentTime)
                            .padding(.top, 10)
                        
                        // Carte principale - Sélection intelligente
                        NavigationLink(destination: SmartOutfitSelectionScreen()) {
                            SmartSelectionCard()
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Gestion de la garde-robe
                        NavigationLink(destination: WardrobeManagementScreen()) {
                            WardrobeManagementCard()
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Historique des outfits portés
                        NavigationLink(destination: OutfitHistoryScreen()) {
                            HistoryCard()
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        // Calendrier des outfits
                        NavigationLink(destination: OutfitCalendarScreen()) {
                            CalendarCard()
                        }
                        .buttonStyle(PlainButtonStyle())
                                }
                    .padding(.horizontal)
                    .padding(.bottom, 100) // Plus d'espace pour la bulle de chat
                            }
                
                // Bulle de chat flottante
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        FloatingChatButton()
                            .padding(.trailing, 20)
                            .padding(.bottom, 20)
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
        VStack(alignment: .leading, spacing: 8) {
        HStack {
                VStack(alignment: .leading, spacing: 6) {
                    if let profile = dataManager.loadUserProfile(), !profile.firstName.isEmpty {
                        Text("\(LocalizedString.localized("Bonjour", for: settingsManager.selectedLanguage)) \(profile.firstName)")
                            .font(.playfairDisplayBold(size: 32))
                            .foregroundColor(AppColors.primaryText)
                    } else {
                    Text(greeting.localized)
                        .font(.playfairDisplayBold(size: 32))
                        .foregroundColor(AppColors.primaryText)
                    }
                    
                    Text(formattedDate)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
            }
        }
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
        // Européennes
        case .french: return "fr_FR"
        case .english: return "en_US"
        case .spanish: return "es_ES"
        case .spanishLatinAmerica: return "es_MX"
        case .german: return "de_DE"
        case .italian: return "it_IT"
        case .portuguese: return "pt_PT"
        case .portugueseBrazil: return "pt_BR"
        case .russian: return "ru_RU"
        case .dutch: return "nl_NL"
        case .polish: return "pl_PL"
        case .greek: return "el_GR"
        case .turkish: return "tr_TR"
        case .swedish: return "sv_SE"
        case .norwegian, .norwegianBokmal: return "no_NO"
        case .danish: return "da_DK"
        case .finnish: return "fi_FI"
        case .czech: return "cs_CZ"
        case .hungarian: return "hu_HU"
        case .romanian: return "ro_RO"
        case .croatian: return "hr_HR"
        case .bulgarian: return "bg_BG"
        case .serbian: return "sr_RS"
        case .slovak: return "sk_SK"
        case .slovenian: return "sl_SI"
        case .ukrainian: return "uk_UA"
        case .irish: return "ga_IE"
        case .catalan: return "ca_ES"
        case .basque: return "eu_ES"
        
        // Asiatiques
        case .chineseSimplified: return "zh_Hans_CN"
        case .chineseTraditional: return "zh_Hant_TW"
        case .japanese: return "ja_JP"
        case .korean: return "ko_KR"
        case .hindi: return "hi_IN"
        case .arabic: return "ar_SA"
        case .thai: return "th_TH"
        case .vietnamese: return "vi_VN"
        case .indonesian: return "id_ID"
        case .malay: return "ms_MY"
        case .bengali: return "bn_BD"
        case .tagalog: return "tl_PH"
        case .urdu: return "ur_PK"
        case .persian: return "fa_IR"
        case .hebrew: return "he_IL"
        case .tamil: return "ta_IN"
        case .telugu: return "te_IN"
        case .marathi: return "mr_IN"
        case .gujarati: return "gu_IN"
        case .kannada: return "kn_IN"
        case .malayalam: return "ml_IN"
        case .punjabi: return "pa_IN"
        case .nepali: return "ne_NP"
        case .sinhala: return "si_LK"
        case .khmer: return "km_KH"
        case .lao: return "lo_LA"
        case .burmese: return "my_MM"
        
        // Africaines et autres
        case .swahili: return "sw_KE"
        case .afrikaans: return "af_ZA"
        case .zulu: return "zu_ZA"
        case .xhosa: return "xh_ZA"
        case .amharic: return "am_ET"
        case .hausa: return "ha_NG"
        case .yoruba: return "yo_NG"
        case .igbo: return "ig_NG"
        }
    }
}

// Carte de sélection intelligente (nouvelle)
struct SmartSelectionCard: View {
    @StateObject private var settingsManager = AppSettingsManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Sélection Intelligente".localized)
                        .font(.playfairDisplayBold(size: 22))
                        .foregroundColor(AppColors.primaryText)

                    Text("Météo automatique + IA".localized)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
                }

                Spacer()

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 28))
                    .foregroundColor(AppColors.primaryText)
            }

            HStack {
                Image(systemName: "location.fill")
                    .foregroundColor(AppColors.primaryText)
                    .font(.system(size: 14))
                Text("Détection automatique".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.buttonPrimaryText)
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundColor(AppColors.buttonPrimaryText)
                    .font(.system(size: 14, weight: .semibold))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(AppColors.buttonPrimary)
            .roundedCorner(20)
        }
        .padding(24)
        .cleanCard(cornerRadius: 24)
        .id(settingsManager.selectedLanguage)
    }
}

// Carte de gestion de garde-robe
struct CalendarCard: View {
    @StateObject private var settingsManager = AppSettingsManager.shared
    
    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(AppColors.buttonSecondary)
                    .frame(width: 60, height: 60)
                
                Image(systemName: "calendar")
                    .font(.system(size: 28))
                    .foregroundColor(AppColors.primaryText)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Calendrier".localized)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                
                Text("Planifiez vos outfits à l'avance".localized)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.secondaryText)
        }
        .padding()
        .cleanCard(cornerRadius: 24)
        .slideIn()
        .id("calendar-\(settingsManager.selectedLanguage)")
    }
}

struct WardrobeManagementCard: View {
    @StateObject private var settingsManager = AppSettingsManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Ma Garde-robe".localized)
                        .font(.playfairDisplayBold(size: 22))
                        .foregroundColor(AppColors.primaryText)

                    Text("Ajoutez vos vêtements".localized)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
            }

                Spacer()

                Image(systemName: "tshirt.fill")
                    .font(.system(size: 28))
                    .foregroundColor(AppColors.primaryText)
            }

            HStack {
                Image(systemName: "camera.fill")
                    .foregroundColor(AppColors.secondaryText)
                    .font(.system(size: 14))
                Text("Prenez vos vêtements en photo".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.secondaryText)
                Spacer()
                Image(systemName: "arrow.right")
                    .foregroundColor(AppColors.secondaryText)
                    .font(.system(size: 14))
            }
        }
        .padding(24)
        .cleanCard(cornerRadius: 24)
        .id("wardrobe-\(settingsManager.selectedLanguage)")
    }
}

// Carte historique
struct HistoryCard: View {
    @StateObject private var settingsManager = AppSettingsManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Historique".localized)
                        .font(.playfairDisplayBold(size: 22))
                        .foregroundColor(AppColors.primaryText)

                    Text("Outfits déjà portés".localized)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
                }

                Spacer()

                Image(systemName: "clock.fill")
                    .font(.system(size: 28))
                    .foregroundColor(AppColors.primaryText)
            }

                HStack {
                Image(systemName: "arrow.right")
                    .foregroundColor(AppColors.secondaryText)
                    .font(.system(size: 14))
                Text("Voir l'historique complet".localized)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.secondaryText)
                    Spacer()
                    Image(systemName: "arrow.right")
                    .foregroundColor(AppColors.secondaryText)
                    .font(.system(size: 14))
            }
        }
        .padding(24)
        .cleanCard(cornerRadius: 24)
        .id("history-\(settingsManager.selectedLanguage)")
    }
}


#Preview {
    NavigationStack {
        HomeScreen()
            .environmentObject(DataManager.shared)
    }
}
