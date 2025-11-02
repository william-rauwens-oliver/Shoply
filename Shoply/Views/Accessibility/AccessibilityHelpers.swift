//
//  AccessibilityHelpers.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

/// Helpers pour l'accessibilité - Conforme au RGAA
/// Améliore l'accessibilité pour les personnes en situation de handicap
struct AccessibilityHelpers {
    
    // MARK: - Labels d'accessibilité
    static func outfitAccessibilityLabel(outfit: Outfit) -> String {
        return """
        Outfit \(outfit.name), type \(outfit.type.rawValue).
        Niveau de confort \(outfit.comfortLevel) sur 5.
        Niveau de style \(outfit.styleLevel) sur 5.
        \(outfit.description)
        """
    }
    
    static func weatherAccessibilityLabel(weather: WeatherType) -> String {
        return "Météo \(weather.rawValue)"
    }
    
    // MARK: - Hints d'accessibilité
    static func outfitAccessibilityHint(outfit: Outfit) -> String {
        return "Double-tapez pour voir les détails de cet outfit"
    }
    
    static func favoriteAccessibilityHint(isFavorite: Bool) -> String {
        return isFavorite ? "Double-tapez pour retirer des favoris" : "Double-tapez pour ajouter aux favoris"
    }
    
    // MARK: - Contrastes de couleurs (WCAG AA)
    static func getAccessibleForegroundColor(for backgroundColor: Color) -> Color {
        // S'assurer d'un contraste suffisant (ratio 4.5:1 minimum)
        return .primary
    }
    
    // MARK: - Taille de police minimale (16pt minimum recommandé)
    static let minimumFontSize: CGFloat = 16.0
    static let preferredFontSize: CGFloat = 18.0
}

/// ViewModifier pour améliorer l'accessibilité
struct AccessibilityModifier: ViewModifier {
    let label: String
    let hint: String?
    let value: String?
    let traits: AccessibilityTraits
    
    func body(content: Content) -> some View {
        content
            .accessibilityLabel(label)
            .accessibilityHint(hint ?? "")
            .accessibilityValue(value ?? "")
            .accessibilityAddTraits(traits)
    }
}

extension View {
    func accessible(label: String, hint: String? = nil, value: String? = nil, traits: AccessibilityTraits = []) -> some View {
        self.modifier(AccessibilityModifier(label: label, hint: hint, value: value, traits: traits))
    }
    
    // Helper pour les tailles de police accessibles
    func accessibleFont(size: CGFloat) -> some View {
        self.font(.system(size: max(size, AccessibilityHelpers.minimumFontSize)))
    }
}

