//
//  EmailValidation.swift
//  Shoply - Outfit Selector
//
//  Created by William on 02/11/2025.
//

import Foundation

/// Utilitaires de validation d'email avec vérification des domaines valides
struct EmailValidation {
    /// Liste complète des extensions de domaine valides (TLD - Top Level Domains)
    private static let validTLDs: Set<String> = [
        // Domaines génériques principaux
        "com", "org", "net", "edu", "gov", "mil", "int",
        // Domaines génériques modernes
        "info", "biz", "name", "pro", "coop", "aero", "museum", "jobs", "mobi", "tel", "travel",
        // Domaines géographiques - Europe
        "fr", "uk", "de", "es", "it", "nl", "be", "ch", "at", "se", "no", "dk", "fi", "pl", "cz", "ie", "pt", "gr", "hu", "ro", "sk", "bg", "hr", "si", "lt", "lv", "ee", "lu", "mt", "cy",
        // Domaines géographiques - Amériques
        "us", "ca", "mx", "br", "ar", "cl", "co", "pe", "ve", "ec", "uy", "py", "bo", "cr", "pa", "gt", "hn", "ni", "sv", "do", "cu", "jm", "tt", "bb", "gd", "lc", "vc", "ag", "bs", "bz", "sr", "gy", "fk",
        // Domaines géographiques - Asie
        "cn", "jp", "in", "kr", "id", "ph", "vn", "th", "my", "sg", "hk", "tw", "mo", "bd", "pk", "lk", "np", "mm", "kh", "la", "bn", "tl", "mn", "kz", "uz", "kg", "tj", "tm", "af", "ir", "iq", "sa", "ae", "om", "ye", "jo", "lb", "sy", "il", "ps", "kw", "qa", "bh",
        // Domaines géographiques - Océanie
        "au", "nz", "fj", "pg", "sb", "vu", "nc", "pf", "ws", "to", "ki", "tv", "nr", "pw", "fm", "mh",
        // Domaines géographiques - Afrique
        "za", "eg", "ng", "ke", "gh", "tz", "et", "ug", "zm", "mw", "mg", "ma", "dz", "tn", "ly", "sd", "so", "dj", "er", "rw", "bi", "td", "cm", "cf", "cg", "cd", "ga", "gq", "st", "ao", "mz", "zw", "bw", "na", "sz", "ls", "mu", "sc", "km", "yt", "re", "sh", "io", "ac",
        // Domaines modernes
        "xyz", "online", "site", "website", "tech", "app", "dev", "cloud", "digital", "ai", "io", "ly", "me", "tv", "co", "cc", "ws",
        // Domaines spécialisés
        "email", "news", "blog", "shop", "store", "sale", "pics", "photos", "gallery", "photo", "video", "media", "film", "games", "game", "music", "art", "design", "studio", "agency", "group", "team", "club", "support", "help", "center", "guide", "tips", "news", "world", "global", "international", "international"
    ]
    
    /// Valide qu'un email a un format correct ET se termine par un domaine valide
    /// - Parameter email: L'adresse email à valider
    /// - Returns: true si l'email est valide, false sinon
    static func isValidEmail(_ email: String) -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        
        // Vérifier que l'email n'est pas vide
        guard !trimmedEmail.isEmpty else {
            return false
        }
        
        // Vérifier le format de base avec regex
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        guard emailPredicate.evaluate(with: trimmedEmail) else {
            return false
        }
        
        // Extraire le domaine (partie après @)
        guard let atIndex = trimmedEmail.lastIndex(of: "@") else {
            return false
        }
        
        let domain = String(trimmedEmail[trimmedEmail.index(after: atIndex)...])
        
        // Séparer le domaine et l'extension
        let domainParts = domain.lowercased().split(separator: ".")
        
        // Vérifier qu'il y a au moins 2 parties (domaine.extension)
        guard domainParts.count >= 2 else {
            return false
        }
        
        // Récupérer l'extension (dernière partie)
        let tld = String(domainParts.last!)
        
        // Vérifier que l'extension est dans la liste des TLD valides
        guard validTLDs.contains(tld) else {
            return false
        }
        
        // Vérifier que le domaine (avant l'extension) n'est pas vide
        guard !domainParts[domainParts.count - 2].isEmpty else {
            return false
        }
        
        return true
    }
    
    /// Message d'erreur personnalisé pour l'email invalide
    static func getErrorMessage() -> String {
        // Utiliser la localisation si disponible, sinon message par défaut
        return LocalizedString.localized("L'email doit contenir une adresse valide avec un domaine reconnu (ex: .com, .fr, .org)", default: "L'email doit contenir une adresse valide avec un domaine reconnu (ex: .com, .fr, .org)")
    }
}

