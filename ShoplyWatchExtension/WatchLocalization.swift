//
//  WatchLocalization.swift
//  ShoplyWatchExtension
//
//  Created by William on 01/11/2025.
//
//  Système de localisation pour Apple Watch

import Foundation

enum WatchAppLanguage: String {
    case french = "fr"
    case english = "en"
    case spanish = "es"
    case german = "de"
    case italian = "it"
    case portuguese = "pt"
    case russian = "ru"
    case chineseSimplified = "zh-Hans"
    case japanese = "ja"
    case korean = "ko"
    
    static func from(rawValue: String) -> WatchAppLanguage {
        return WatchAppLanguage(rawValue: rawValue) ?? .french
    }
}

struct WatchLocalizedStrings {
    static let translations: [String: [WatchAppLanguage: String]] = [
        "Historique": [
            .french: "Historique",
            .english: "History",
            .spanish: "Historial",
            .german: "Verlauf",
            .italian: "Cronologia",
            .portuguese: "Histórico",
            .russian: "История",
            .chineseSimplified: "历史",
            .japanese: "履歴",
            .korean: "기록"
        ],
        "Aucun historique": [
            .french: "Aucun historique",
            .english: "No history",
            .spanish: "Sin historial",
            .german: "Kein Verlauf",
            .italian: "Nessuna cronologia",
            .portuguese: "Sem histórico",
            .russian: "Нет истории",
            .chineseSimplified: "无历史记录",
            .japanese: "履歴がありません",
            .korean: "기록 없음"
        ],
        "Favoris": [
            .french: "Favoris",
            .english: "Favorites",
            .spanish: "Favoritos",
            .german: "Favoriten",
            .italian: "Preferiti",
            .portuguese: "Favoritos",
            .russian: "Избранное",
            .chineseSimplified: "收藏",
            .japanese: "お気に入り",
            .korean: "즐겨찾기"
        ],
        "Aucun favori": [
            .french: "Aucun favori",
            .english: "No favorites",
            .spanish: "Sin favoritos",
            .german: "Keine Favoriten",
            .italian: "Nessun preferito",
            .portuguese: "Sem favoritos",
            .russian: "Нет избранного",
            .chineseSimplified: "无收藏",
            .japanese: "お気に入りがありません",
            .korean: "즐겨찾기 없음"
        ],
        "Ajouté le": [
            .french: "Ajouté le",
            .english: "Added on",
            .spanish: "Añadido el",
            .german: "Hinzugefügt am",
            .italian: "Aggiunto il",
            .portuguese: "Adicionado em",
            .russian: "Добавлено",
            .chineseSimplified: "添加于",
            .japanese: "追加日",
            .korean: "추가된 날짜"
        ]
    ]
    
    static func localized(_ key: String, for language: WatchAppLanguage) -> String {
        guard let translationsForKey = translations[key] else {
            return translations[key]?[.english] ?? translations[key]?[.french] ?? key
        }
        
        if let translation = translationsForKey[language] {
            return translation
        }
        
        // Fallback: essayer les langues de base
        let fallbackLanguages: [WatchAppLanguage] = [.english, .french, .spanish, .german, .italian]
        for fallbackLang in fallbackLanguages {
            if let translation = translationsForKey[fallbackLang] {
                return translation
            }
        }
        
        return key
    }
}

struct WatchLocalization {
    static var selectedLanguage: WatchAppLanguage {
        guard let sharedDefaults = UserDefaults(suiteName: "group.William.Shoply"),
              let languageString = sharedDefaults.string(forKey: "app_language") else {
            return .french // Défaut
        }
        return WatchAppLanguage.from(rawValue: languageString)
    }
    
    static func localized(_ key: String) -> String {
        let language = selectedLanguage
        return WatchLocalizedStrings.localized(key, for: language)
    }
}

extension String {
    var localized: String {
        return WatchLocalization.localized(self)
    }
}

