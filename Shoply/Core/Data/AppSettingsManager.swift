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

/// Langues supportées par l'application - Les 10 langues les plus parlées au monde
enum AppLanguage: String, CaseIterable, Identifiable {
    // Les 10 langues les plus parlées au monde (par nombre total de locuteurs)
    case english = "en"           // 1. Anglais - ~1,5 milliards
    case chineseSimplified = "zh-Hans"  // 2. Chinois mandarin - ~1,1 milliards
    case hindi = "hi"             // 3. Hindi - ~600 millions
    case spanish = "es"           // 4. Espagnol - ~548 millions
    case french = "fr"            // 5. Français - ~274 millions
    case italian = "it"           // Italien
    case german = "de"            // Allemand
    case arabic = "ar"            // 6. Arabe - ~274 millions
    case bengali = "bn"           // 7. Bengali - ~272 millions
    case russian = "ru"           // 8. Russe - ~258 millions
    case portuguese = "pt"        // 9. Portugais - ~234 millions
    case indonesian = "id"        // 10. Indonésien - ~199 millions
    
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .english: return "English"
        case .chineseSimplified: return "简体中文"
        case .hindi: return "हिन्दी"
        case .spanish: return "Español"
        case .french: return "Français"
        case .italian: return "Italiano"
        case .german: return "Deutsch"
        case .arabic: return "العربية"
        case .bengali: return "বাংলা"
        case .russian: return "Русский"
        case .portuguese: return "Português"
        case .indonesian: return "Bahasa Indonesia"
        }
    }
    
    var flag: String {
        switch self {
        case .english: return "🇬🇧"
        case .chineseSimplified: return "🇨🇳"
        case .hindi: return "🇮🇳"
        case .spanish: return "🇪🇸"
        case .french: return "🇫🇷"
        case .italian: return "🇮🇹"
        case .german: return "🇩🇪"
        case .arabic: return "🇸🇦"
        case .bengali: return "🇧🇩"
        case .russian: return "🇷🇺"
        case .portuguese: return "🇵🇹"
        case .indonesian: return "🇮🇩"
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

