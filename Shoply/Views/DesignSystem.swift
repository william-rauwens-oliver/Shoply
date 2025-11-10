//
//  DesignSystem.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

// MARK: - Système de Design Épuré Noir & Blanc

struct DesignSystem {
    
    // MARK: - Espacements
    struct Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 16
        static let lg: CGFloat = 24
        static let xl: CGFloat = 32
        static let xxl: CGFloat = 40
    }
    
    // MARK: - Rayons de coins
    struct Radius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
    }
    
    // MARK: - Typographie
    struct Typography {
        static func largeTitle() -> Font {
            .system(size: 34, weight: .bold, design: .default)
        }
        
        static func title() -> Font {
            .system(size: 28, weight: .bold, design: .default)
        }
        
        static func title2() -> Font {
            .system(size: 22, weight: .semibold, design: .default)
        }
        
        static func headline() -> Font {
            .system(size: 17, weight: .semibold, design: .default)
        }
        
        static func body() -> Font {
            .system(size: 17, weight: .regular, design: .default)
        }
        
        static func callout() -> Font {
            .system(size: 16, weight: .regular, design: .default)
        }
        
        static func subheadline() -> Font {
            .system(size: 15, weight: .regular, design: .default)
        }
        
        static func footnote() -> Font {
            .system(size: 13, weight: .regular, design: .default)
        }
        
        static func caption() -> Font {
            .system(size: 12, weight: .regular, design: .default)
        }
    }
}

// MARK: - Composants Réutilisables

struct Card<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let content: Content
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = DesignSystem.Radius.md, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(DesignSystem.Spacing.md)
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.headline())
                .foregroundColor(AppColors.buttonPrimaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(AppColors.buttonPrimary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
        }
    }
}

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(DesignSystem.Typography.headline())
                .foregroundColor(AppColors.buttonSecondaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, DesignSystem.Spacing.md)
                .background(AppColors.buttonSecondary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
        }
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(DesignSystem.Typography.title2())
                .foregroundColor(AppColors.primaryText)
            Spacer()
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.sm)
    }
}

struct ListRow<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            content
        }
        .padding(.horizontal, DesignSystem.Spacing.md)
        .padding(.vertical, DesignSystem.Spacing.md)
        .background(AppColors.cardBackground)
    }
}

struct EmptyState: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(AppColors.secondaryText)
            
            Text(title)
                .font(DesignSystem.Typography.title2())
                .foregroundColor(AppColors.primaryText)
            
            Text(message)
                .font(DesignSystem.Typography.body())
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DesignSystem.Spacing.xl)
        }
        .padding(.vertical, DesignSystem.Spacing.xxl)
    }
}

