//
//  DesignHelpers.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

// Helper pour le design liquid glass (iOS 26)
@available(iOS 26.0, *)
struct LiquidGlassModifier: ViewModifier {
    let cornerRadius: CGFloat
    let intensity: Double
    
    func body(content: Content) -> some View {
        content
            .background(
                .ultraThinMaterial,
                in: RoundedRectangle(cornerRadius: cornerRadius)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(
                        LinearGradient(
                            colors: [
                                .white.opacity(0.6),
                                .white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
    }
}

// Helper pour le design iOS 18
struct ClassicCardModifier: ViewModifier {
    let cornerRadius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 5)
            )
    }
}

// View extension pour faciliter l'utilisation
extension View {
    @ViewBuilder
    func adaptiveCard(cornerRadius: CGFloat = 20) -> some View {
        if #available(iOS 26.0, *) {
            self.modifier(LiquidGlassModifier(cornerRadius: cornerRadius, intensity: 0.8))
        } else {
            self.modifier(ClassicCardModifier(cornerRadius: cornerRadius))
        }
    }
}

// Gradient moderne selon la version iOS
@ViewBuilder
func adaptiveGradient() -> some View {
    if #available(iOS 26.0, *) {
        // Design liquid glass avec gradients plus subtils
        LinearGradient(
            colors: [
                Color(red: 0.99, green: 0.98, blue: 1.0).opacity(0.95),
                Color(red: 0.97, green: 0.98, blue: 1.0).opacity(0.9)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    } else {
        // Design classique iOS 18
        LinearGradient(
            colors: [
                Color(red: 0.98, green: 0.97, blue: 0.99),
                Color(red: 0.95, green: 0.97, blue: 1.0)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

