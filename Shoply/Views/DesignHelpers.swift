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
    // Utilise Color.primary et Color.secondary qui s'adaptent automatiquement au mode sombre
    // Pour une compatibilité maximale, on utilise les couleurs adaptatives du système
    
    // Fond - Utilise les couleurs adaptatives
    static let background = Color(light: .white, dark: .black)
    
    // Textes - Utilise les couleurs adaptatives
    static let primaryText = Color(light: .black, dark: .white)
    static let secondaryText = Color(light: Color.gray.opacity(0.7), dark: Color.gray.opacity(0.6))
    static let tertiaryText = Color(light: Color.gray.opacity(0.5), dark: Color.gray.opacity(0.4))
    
    // Cartes
    static let cardBackground = Color(light: .white, dark: Color(white: 0.1))
    static let cardBorder = Color(light: Color.gray.opacity(0.15), dark: Color.gray.opacity(0.3))
    static let separator = Color(light: Color.gray.opacity(0.12), dark: Color.gray.opacity(0.2))
    
    // Boutons
    static let buttonPrimary = Color(light: .black, dark: .white)
    static let buttonPrimaryText = Color(light: .white, dark: .black)
    static let buttonSecondary = Color(light: Color.gray.opacity(0.08), dark: Color(white: 0.15))
    static let buttonSecondaryText = Color(light: .black, dark: .white)
    
    // Accents et ombres - Ultra-opaques pour meilleure visibilité
    static let accent = Color(light: Color.gray.opacity(0.25), dark: Color.gray.opacity(0.4))
    static let shadow = Color(light: Color.black.opacity(0.5), dark: Color.black.opacity(0.6))
    static let hoverShadow = Color(light: Color.black.opacity(0.6), dark: Color.black.opacity(0.8))
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

// Modificateur Liquid Glass avec coins arrondis iOS
struct LiquidGlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    @State private var isHovered = false
    @Environment(\.colorScheme) var colorScheme
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        // Effet liquid glass avec blur
                        Material.regularMaterial
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppColors.cardBorder.opacity(0.3),
                                        AppColors.cardBorder.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(
                        color: isHovered ? AppColors.hoverShadow.opacity(0.3) : AppColors.shadow.opacity(0.2),
                        radius: isHovered ? 16 : 12,
                        x: 0,
                        y: isHovered ? 6 : 4
                    )
            }
            .animation(.easeInOut(duration: 0.3), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// Modificateur de carte épurée avec animations modernes (pour compatibilité)
struct CleanCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    @State private var isHovered = false
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(
                        Material.regularMaterial
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppColors.cardBorder.opacity(0.3),
                                        AppColors.cardBorder.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(
                        color: isHovered ? AppColors.hoverShadow.opacity(0.3) : AppColors.shadow.opacity(0.2),
                        radius: isHovered ? 16 : 12,
                        x: 0,
                        y: isHovered ? 6 : 4
                    )
            }
            .animation(.easeInOut(duration: 0.3), value: isHovered)
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
    func cleanCard(cornerRadius: CGFloat = 24) -> some View {
        self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius))
    }
    
    @ViewBuilder
    func liquidGlass(cornerRadius: CGFloat = 24) -> some View {
        self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius))
    }
    
    @ViewBuilder
    func slideIn() -> some View {
        self.modifier(SlideInModifier())
    }
    
    @ViewBuilder
    func pulse() -> some View {
        self.modifier(PulseModifier())
    }
    
    // Extension pour coins arrondis iOS par défaut
    @ViewBuilder
    func roundedCorner(_ radius: CGFloat = 24) -> some View {
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
