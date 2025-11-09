//
//  DesignHelpers.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import UIKit

// Palette de couleurs noir et blanc épurée et moderne
// Supporte le mode sombre avec ColorScheme
struct AppColors {
    // Fond - Noir et blanc pur
    static let background = Color(light: .white, dark: .black)
    
    // Textes - Noir et blanc pur
    static let primaryText = Color(light: .black, dark: .white)
    static let secondaryText = Color(light: Color(white: 0.3), dark: Color(white: 0.7))
    static let tertiaryText = Color(light: Color(white: 0.5), dark: Color(white: 0.5))
    
    // Cartes - Minimalistes
    static let cardBackground = Color(light: .white, dark: Color(white: 0.05))
    static let cardBorder = Color(light: Color(white: 0.2), dark: Color(white: 0.2))
    static let separator = Color(light: Color(white: 0.1), dark: Color(white: 0.1))
    
    // Boutons - Noir et blanc pur
    static let buttonPrimary = Color(light: .black, dark: .white)
    static let buttonPrimaryText = Color(light: .white, dark: .black)
    static let buttonSecondary = Color(light: Color(white: 0.05), dark: Color(white: 0.1))
    static let buttonSecondaryText = Color(light: .black, dark: .white)
    
    // Accents - Gris uniquement
    static let accent = Color(light: Color(white: 0.2), dark: Color(white: 0.8))
    static let shadow = Color(light: Color.black.opacity(0.1), dark: Color.black.opacity(0.3))
    static let hoverShadow = Color(light: Color.black.opacity(0.15), dark: Color.black.opacity(0.4))
}

// Extension pour créer des couleurs adaptatives
extension Color {
    static func dynamicColor(light: UIColor, dark: UIColor) -> Color {
        return Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark:
                return dark
            default:
                return light
            }
        })
    }
    
    init(light: Color, dark: Color) {
        let lightUIColor = UIColor(light)
        let darkUIColor = UIColor(dark)
        self = Color.dynamicColor(light: lightUIColor, dark: darkUIColor)
    }
}

// Modificateur de carte épurée minimaliste
struct CleanCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    )
                    .shadow(color: AppColors.shadow, radius: 4, x: 0, y: 2)
            }
    }
}

// Modificateur avec animation de glissement
struct SlideInModifier: ViewModifier {
    @State private var isVisible = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .offset(y: isVisible ? 0 : 20)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    isVisible = true
                }
            }
    }
}

// Modificateur de pulsation pour les éléments interactifs
struct PulseModifier: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

// View extension pour faciliter l'utilisation
extension View {
    @ViewBuilder
    func cleanCard(cornerRadius: CGFloat = 16) -> some View {
        self.modifier(CleanCardModifier(cornerRadius: cornerRadius))
    }
    
    @ViewBuilder
    func slideIn() -> some View {
        self.modifier(SlideInModifier())
    }
    
    @ViewBuilder
    func pulse() -> some View {
        self.modifier(PulseModifier())
    }
    
    // Extension pour coins arrondis
    @ViewBuilder
    func roundedCorner(_ radius: CGFloat = 16) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

// Fond blanc épuré
@ViewBuilder
func cleanBackground() -> some View {
    AppColors.background
}

// Extension Font pour les polices PlayfairDisplay
extension Font {
    static func playfairDisplayBold(size: CGFloat) -> Font {
        return .custom("Playfair Display Bold", size: size)
    }
    
    static func playfairDisplayRegular(size: CGFloat) -> Font {
        return .custom("Playfair Display Regular", size: size)
    }
}
