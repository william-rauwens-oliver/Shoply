//
//  AppSettingsManager.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import SwiftUI
import Combine

/// Gestionnaire des paramètres de l'application
class AppSettingsManager: ObservableObject {
    static let shared = AppSettingsManager()
    
    // MARK: - Propriétés publiées
    @Published var colorScheme: ColorScheme? = nil {
        didSet {
            saveColorScheme()
        }
    }
    
    @Published var selectedLanguage: AppLanguage = .french {
        didSet {
            saveLanguage()
        }
    }
    
    // Plus de sélection de provider - uniquement Gemini
    
    // MARK: - Clés UserDefaults
    private let colorSchemeKey = "app_color_scheme" // "light", "dark", "system"
    private let languageKey = "app_language"
    
    private init() {
        loadSettings()
    }
    
    // MARK: - Chargement des paramètres
    private func loadSettings() {
        // Charger le mode sombre
        if let schemeString = UserDefaults.standard.string(forKey: colorSchemeKey) {
            switch schemeString {
            case "light":
                colorScheme = .light
            case "dark":
                colorScheme = .dark
            case "system":
                colorScheme = nil
            default:
                colorScheme = nil
            }
        } else {
            colorScheme = nil // Par défaut, suivre le système
        }
        
        // Charger la langue
        if let languageString = UserDefaults.standard.string(forKey: languageKey),
           let language = AppLanguage(rawValue: languageString) {
            selectedLanguage = language
        } else {
            selectedLanguage = .french // Langue par défaut
        }
        
        // Plus de chargement de provider - uniquement Gemini
    }
    
    // MARK: - Sauvegarde des paramètres
    private func saveColorScheme() {
        let schemeString: String
        switch colorScheme {
        case .light:
            schemeString = "light"
        case .dark:
            schemeString = "dark"
        case .none:
            schemeString = "system"
        @unknown default:
            schemeString = "system"
        }
        UserDefaults.standard.set(schemeString, forKey: colorSchemeKey)
    }
    
    private func saveLanguage() {
        UserDefaults.standard.set(selectedLanguage.rawValue, forKey: languageKey)
    }
    
    
    // MARK: - Méthodes publiques
    func setColorScheme(_ scheme: ColorScheme?) {
        self.colorScheme = scheme
    }
    
    func setLanguage(_ language: AppLanguage) {
        self.selectedLanguage = language
    }
    
}

/// Langues supportées par l'application
enum AppLanguage: String, CaseIterable, Identifiable {
    // Langues européennes
    case french = "fr"
    case english = "en"
    case spanish = "es"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case russian = "ru"
    case dutch = "nl"
    case polish = "pl"
    case greek = "el"
    case turkish = "tr"
    case swedish = "sv"
    case norwegian = "no"
    case danish = "da"
    case finnish = "fi"
    case czech = "cs"
    case hungarian = "hu"
    case romanian = "ro"
    case croatian = "hr"
    case bulgarian = "bg"
    case serbian = "sr"
    case slovak = "sk"
    case slovenian = "sl"
    case ukrainian = "uk"
    case norwegianBokmal = "nb"
    case irish = "ga"
    case catalan = "ca"
    case basque = "eu"
    
    // Langues asiatiques
    case chineseSimplified = "zh-Hans"
    case chineseTraditional = "zh-Hant"
    case japanese = "ja"
    case korean = "ko"
    case hindi = "hi"
    case arabic = "ar"
    case thai = "th"
    case vietnamese = "vi"
    case indonesian = "id"
    case malay = "ms"
    case bengali = "bn"
    case tagalog = "tl"
    case urdu = "ur"
    case persian = "fa"
    case hebrew = "he"
    case tamil = "ta"
    case telugu = "te"
    case marathi = "mr"
    case gujarati = "gu"
    case kannada = "kn"
    case malayalam = "ml"
    case punjabi = "pa"
    case nepali = "ne"
    case sinhala = "si"
    case khmer = "km"
    case lao = "lo"
    case burmese = "my"
    
    // Langues africaines et autres
    case swahili = "sw"
    case afrikaans = "af"
    case zulu = "zu"
    case xhosa = "xh"
    case amharic = "am"
    case hausa = "ha"
    case yoruba = "yo"
    case igbo = "ig"
    
    // Langues d'autres régions
    case portugueseBrazil = "pt-BR"
    case spanishLatinAmerica = "es-419"
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        // Européennes
        case .french: return "Français"
        case .english: return "English"
        case .spanish: return "Español"
        case .german: return "Deutsch"
        case .italian: return "Italiano"
        case .portuguese: return "Português"
        case .russian: return "Русский"
        case .dutch: return "Nederlands"
        case .polish: return "Polski"
        case .greek: return "Ελληνικά"
        case .turkish: return "Türkçe"
        case .swedish: return "Svenska"
        case .norwegian: return "Norsk"
        case .danish: return "Dansk"
        case .finnish: return "Suomi"
        case .czech: return "Čeština"
        case .hungarian: return "Magyar"
        case .romanian: return "Română"
        case .croatian: return "Hrvatski"
        case .bulgarian: return "Български"
        case .serbian: return "Српски"
        case .slovak: return "Slovenčina"
        case .slovenian: return "Slovenščina"
        case .ukrainian: return "Українська"
        case .norwegianBokmal: return "Norsk Bokmål"
        case .irish: return "Gaeilge"
        case .catalan: return "Català"
        case .basque: return "Euskera"
        
        // Asiatiques
        case .chineseSimplified: return "简体中文"
        case .chineseTraditional: return "繁體中文"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .hindi: return "हिन्दी"
        case .arabic: return "العربية"
        case .thai: return "ไทย"
        case .vietnamese: return "Tiếng Việt"
        case .indonesian: return "Bahasa Indonesia"
        case .malay: return "Bahasa Melayu"
        case .bengali: return "বাংলা"
        case .tagalog: return "Tagalog"
        case .urdu: return "اردو"
        case .persian: return "فارسی"
        case .hebrew: return "עברית"
        case .tamil: return "தமிழ்"
        case .telugu: return "తెలుగు"
        case .marathi: return "मराठी"
        case .gujarati: return "ગુજરાતી"
        case .kannada: return "ಕನ್ನಡ"
        case .malayalam: return "മലയാളം"
        case .punjabi: return "ਪੰਜਾਬੀ"
        case .nepali: return "नेपाली"
        case .sinhala: return "සිංහල"
        case .khmer: return "ខ្មែរ"
        case .lao: return "ລາວ"
        case .burmese: return "မြန်မာ"
        
        // Africaines et autres
        case .swahili: return "Kiswahili"
        case .afrikaans: return "Afrikaans"
        case .zulu: return "isiZulu"
        case .xhosa: return "isiXhosa"
        case .amharic: return "አማርኛ"
        case .hausa: return "Hausa"
        case .yoruba: return "Yorùbá"
        case .igbo: return "Igbo"
        
        // Variantes régionales
        case .portugueseBrazil: return "Português (Brasil)"
        case .spanishLatinAmerica: return "Español (América Latina)"
        }
    }
    
    var flag: String {
        switch self {
        // Européennes
        case .french: return "🇫🇷"
        case .english: return "🇬🇧"
        case .spanish: return "🇪🇸"
        case .german: return "🇩🇪"
        case .italian: return "🇮🇹"
        case .portuguese: return "🇵🇹"
        case .russian: return "🇷🇺"
        case .dutch: return "🇳🇱"
        case .polish: return "🇵🇱"
        case .greek: return "🇬🇷"
        case .turkish: return "🇹🇷"
        case .swedish: return "🇸🇪"
        case .norwegian, .norwegianBokmal: return "🇳🇴"
        case .danish: return "🇩🇰"
        case .finnish: return "🇫🇮"
        case .czech: return "🇨🇿"
        case .hungarian: return "🇭🇺"
        case .romanian: return "🇷🇴"
        case .croatian: return "🇭🇷"
        case .bulgarian: return "🇧🇬"
        case .serbian: return "🇷🇸"
        case .slovak: return "🇸🇰"
        case .slovenian: return "🇸🇮"
        case .ukrainian: return "🇺🇦"
        case .irish: return "🇮🇪"
        case .catalan: return "🇪🇸"
        case .basque: return "🇪🇸"
        
        // Asiatiques
        case .chineseSimplified, .chineseTraditional: return "🇨🇳"
        case .japanese: return "🇯🇵"
        case .korean: return "🇰🇷"
        case .hindi, .tamil, .telugu, .marathi, .gujarati, .kannada, .malayalam, .punjabi, .urdu, .bengali, .nepali: return "🇮🇳"
        case .arabic: return "🇸🇦"
        case .thai: return "🇹🇭"
        case .vietnamese: return "🇻🇳"
        case .indonesian, .malay: return "🇮🇩"
        case .tagalog: return "🇵🇭"
        case .persian: return "🇮🇷"
        case .hebrew: return "🇮🇱"
        case .sinhala: return "🇱🇰"
        case .khmer: return "🇰🇭"
        case .lao: return "🇱🇦"
        case .burmese: return "🇲🇲"
        
        // Africaines et autres
        case .swahili, .zulu, .xhosa, .hausa, .yoruba, .igbo: return "🇰🇪"
        case .afrikaans: return "🇿🇦"
        case .amharic: return "🇪🇹"
        
        // Variantes régionales
        case .portugueseBrazil: return "🇧🇷"
        case .spanishLatinAmerica: return "🇲🇽"
        }
    }
}

/// Extension pour les traductions (localisation simple)
extension AppLanguage {
    func localized(_ key: String) -> String {
        // Pour l'instant, on retourne les clés en français
        // Dans une vraie app, on utiliserait NSLocalizedString avec des fichiers .strings
        return key
    }
}

