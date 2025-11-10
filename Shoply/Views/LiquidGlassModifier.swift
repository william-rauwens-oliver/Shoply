//
//  LiquidGlassModifier.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

/// Modifier pour appliquer l'effet Liquid Glass iOS 26
struct LiquidGlassModifier: ViewModifier {
    @Environment(\.colorScheme) var colorScheme
    let cornerRadius: CGFloat
    
    init(cornerRadius: CGFloat = 20) {
        self.cornerRadius = cornerRadius
    }
    
    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

extension View {
    func liquidGlass(cornerRadius: CGFloat = 20) -> some View {
        modifier(LiquidGlassModifier(cornerRadius: cornerRadius))
    }
}

/// Carte avec effet Liquid Glass iOS 26
struct LiquidGlassCard<Content: View>: View {
    @Environment(\.colorScheme) var colorScheme
    let cornerRadius: CGFloat
    let content: Content
    
    init(cornerRadius: CGFloat = 20, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content()
    }
    
    var body: some View {
        content
            .padding()
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

