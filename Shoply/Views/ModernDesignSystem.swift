//
//  ModernDesignSystem.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

/// Système de design moderne avec support dark/light mode complet
struct ModernDesignSystem {
    
    // MARK: - Couleurs de Base
    
    struct Colors {
        // Backgrounds
        static var background: Color {
            Color(light: .white, dark: Color(red: 0.05, green: 0.05, blue: 0.05))
        }
        
        static var secondaryBackground: Color {
            Color(light: Color(white: 0.98), dark: Color(red: 0.1, green: 0.1, blue: 0.1))
        }
        
        // Cards
        static var cardBackground: Color {
            Color(light: .white, dark: Color(red: 0.12, green: 0.12, blue: 0.12))
        }
        
        static var cardBorder: Color {
            Color(light: Color.gray.opacity(0.15), dark: Color.gray.opacity(0.3))
        }
        
        // Text
        static var primaryText: Color {
            Color(light: .black, dark: .white)
        }
        
        static var secondaryText: Color {
            Color(light: Color.gray.opacity(0.7), dark: Color.gray.opacity(0.6))
        }
        
        static var tertiaryText: Color {
            Color(light: Color.gray.opacity(0.5), dark: Color.gray.opacity(0.4))
        }
        
        // Accents
        static var accent: Color {
            Color(light: Color(red: 0.2, green: 0.4, blue: 0.9), dark: Color(red: 0.4, green: 0.6, blue: 1.0))
        }
        
        static var accentSecondary: Color {
            Color(light: Color(red: 0.9, green: 0.3, blue: 0.5), dark: Color(red: 1.0, green: 0.4, blue: 0.6))
        }
        
        // Buttons
        static var buttonPrimary: Color {
            Color(light: .black, dark: .white)
        }
        
        static var buttonPrimaryText: Color {
            Color(light: .white, dark: .black)
        }
        
        static var buttonSecondary: Color {
            Color(light: Color.gray.opacity(0.1), dark: Color(white: 0.2))
        }
        
        // Shadows
        static var shadow: Color {
            Color(light: Color.black.opacity(0.1), dark: Color.black.opacity(0.5))
        }
        
        // Success/Error/Warning
        static var success: Color {
            Color(light: Color(red: 0.2, green: 0.7, blue: 0.3), dark: Color(red: 0.3, green: 0.8, blue: 0.4))
        }
        
        static var error: Color {
            Color(light: Color(red: 0.9, green: 0.2, blue: 0.2), dark: Color(red: 1.0, green: 0.3, blue: 0.3))
        }
        
        static var warning: Color {
            Color(light: Color(red: 1.0, green: 0.6, blue: 0.0), dark: Color(red: 1.0, green: 0.7, blue: 0.2))
        }
    }
    
    // MARK: - Typography
    
    struct Typography {
        static func largeTitle(_ colorScheme: ColorScheme) -> Font {
            .system(size: 34, weight: .bold, design: .rounded)
        }
        
        static func title(_ colorScheme: ColorScheme) -> Font {
            .system(size: 28, weight: .bold, design: .rounded)
        }
        
        static func title2(_ colorScheme: ColorScheme) -> Font {
            .system(size: 22, weight: .semibold, design: .rounded)
        }
        
        static func headline(_ colorScheme: ColorScheme) -> Font {
            .system(size: 17, weight: .semibold, design: .default)
        }
        
        static func body(_ colorScheme: ColorScheme) -> Font {
            .system(size: 17, weight: .regular, design: .default)
        }
        
        static func callout(_ colorScheme: ColorScheme) -> Font {
            .system(size: 16, weight: .regular, design: .default)
        }
        
        static func subheadline(_ colorScheme: ColorScheme) -> Font {
            .system(size: 15, weight: .regular, design: .default)
        }
        
        static func footnote(_ colorScheme: ColorScheme) -> Font {
            .system(size: 13, weight: .regular, design: .default)
        }
        
        static func caption(_ colorScheme: ColorScheme) -> Font {
            .system(size: 12, weight: .regular, design: .default)
        }
    }
    
    // MARK: - Spacing
    
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 48
    }
    
    // MARK: - Corner Radius
    
    struct CornerRadius {
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let xlarge: CGFloat = 24
    }
    
    // MARK: - Shadows
    
    struct Shadows {
        static func small(_ colorScheme: ColorScheme) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color: Colors.shadow, radius: 4, x: 0, y: 2)
        }
        
        static func medium(_ colorScheme: ColorScheme) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color: Colors.shadow, radius: 8, x: 0, y: 4)
        }
        
        static func large(_ colorScheme: ColorScheme) -> (color: Color, radius: CGFloat, x: CGFloat, y: CGFloat) {
            (color: Colors.shadow, radius: 16, x: 0, y: 8)
        }
    }
}

// MARK: - View Modifiers

struct ModernCardModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let cornerRadius: CGFloat
    let padding: CGFloat
    
    init(cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.large, padding: CGFloat = ModernDesignSystem.Spacing.md) {
        self.cornerRadius = cornerRadius
        self.padding = padding
    }
    
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(ModernDesignSystem.Colors.cardBackground)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(ModernDesignSystem.Colors.cardBorder, lineWidth: 1)
            )
            .shadow(
                color: ModernDesignSystem.Shadows.medium(colorScheme).color,
                radius: ModernDesignSystem.Shadows.medium(colorScheme).radius,
                x: ModernDesignSystem.Shadows.medium(colorScheme).x,
                y: ModernDesignSystem.Shadows.medium(colorScheme).y
            )
    }
}

struct ModernButtonModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let style: ButtonStyle
    
    enum ButtonStyle {
        case primary
        case secondary
        case accent
    }
    
    func body(content: Content) -> some View {
        content
            .font(ModernDesignSystem.Typography.headline(colorScheme))
            .foregroundColor(buttonTextColor)
            .padding(.horizontal, ModernDesignSystem.Spacing.lg)
            .padding(.vertical, ModernDesignSystem.Spacing.md)
            .background(buttonBackground)
            .cornerRadius(ModernDesignSystem.CornerRadius.medium)
            .shadow(
                color: ModernDesignSystem.Shadows.small(colorScheme).color,
                radius: ModernDesignSystem.Shadows.small(colorScheme).radius,
                x: ModernDesignSystem.Shadows.small(colorScheme).x,
                y: ModernDesignSystem.Shadows.small(colorScheme).y
            )
    }
    
    private var buttonBackground: Color {
        switch style {
        case .primary:
            return ModernDesignSystem.Colors.buttonPrimary
        case .secondary:
            return ModernDesignSystem.Colors.buttonSecondary
        case .accent:
            return ModernDesignSystem.Colors.accent
        }
    }
    
    private var buttonTextColor: Color {
        switch style {
        case .primary:
            return ModernDesignSystem.Colors.buttonPrimaryText
        case .secondary, .accent:
            return ModernDesignSystem.Colors.primaryText
        }
    }
}

extension View {
    func modernCard(cornerRadius: CGFloat = ModernDesignSystem.CornerRadius.large, padding: CGFloat = ModernDesignSystem.Spacing.md) -> some View {
        self.modifier(ModernCardModifier(cornerRadius: cornerRadius, padding: padding))
    }
    
    func modernButton(style: ModernButtonModifier.ButtonStyle = .primary) -> some View {
        self.modifier(ModernButtonModifier(style: style))
    }
}

