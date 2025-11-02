//
//  DesignHelpers.swift
//  ShoplyCore - Android Compatible
//
//  Helpers de design identiques iOS

import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

// Palette de couleurs (identique iOS)
public struct AppColors {
    public static let background = Color(light: .white, dark: .black)
    public static let primaryText = Color(light: .black, dark: .white)
    public static let secondaryText = Color(light: Color.gray.opacity(0.7), dark: Color.gray.opacity(0.6))
    public static let cardBackground = Color(light: .white, dark: Color(white: 0.1))
    public static let cardBorder = Color(light: Color.gray.opacity(0.25), dark: Color.gray.opacity(0.3))
    public static let buttonPrimary = Color(light: .black, dark: .white)
    public static let buttonPrimaryText = Color(light: .white, dark: .black)
    public static let buttonSecondary = Color(light: Color.gray.opacity(0.08), dark: Color(white: 0.15))
    public static let shadow = Color(light: Color.black.opacity(0.15), dark: Color.black.opacity(0.5))
}

// Extension Color pour compatibilité Android
extension Color {
    init(light: Color, dark: Color) {
        #if canImport(UIKit)
        let lightUIColor = UIColor(light)
        let darkUIColor = UIColor(dark)
        self = Color(UIColor { traitCollection in
            switch traitCollection.userInterfaceStyle {
            case .dark: return darkUIColor
            default: return lightUIColor
            }
        })
        #else
        // Pour Android, utiliser la couleur claire par défaut
        self = light
        #endif
    }
}

// Modificateur Liquid Glass
struct LiquidGlassCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(AppColors.cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 0.5)
                    )
                    .shadow(color: AppColors.shadow.opacity(0.08), radius: 12, x: 0, y: 4)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func cleanCard(cornerRadius: CGFloat = 24) -> some View {
        self.modifier(LiquidGlassCardModifier(cornerRadius: cornerRadius))
    }
    
    func roundedCorner(_ radius: CGFloat = 24) -> some View {
        self.clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

