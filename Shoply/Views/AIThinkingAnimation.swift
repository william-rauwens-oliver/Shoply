//
//  AIThinkingAnimation.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

/// Animation moderne et stylée pour indiquer que l'IA réfléchit
struct AIThinkingAnimation: View {
    let message: String?
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 1.0
    @State private var opacity: Double = 0.6
    @State private var dotAnimations: [Bool] = [false, false, false]
    
    init(message: String? = nil) {
        self.message = message
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Animation principale
            ZStack {
                // Cercle extérieur animé
                Circle()
                    .stroke(
                        LinearGradient(
                            colors: [
                                AppColors.buttonPrimary.opacity(0.3),
                                AppColors.buttonPrimary.opacity(0.1),
                                AppColors.buttonPrimary.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 3
                    )
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(rotationAngle))
                
                // Cercle intérieur pulsant
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.buttonPrimary.opacity(0.4),
                                AppColors.buttonPrimary.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)
                    .scaleEffect(scale)
                    .opacity(opacity)
                
                // Icône étoiles au centre
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .medium))
                    .foregroundColor(AppColors.buttonPrimary)
                    .scaleEffect(scale * 0.9)
                    .opacity(opacity)
            }
            
            // Message avec points animés
            if let message = message {
                HStack(spacing: 4) {
                    Text(message)
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(AppColors.primaryText)
                    
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(AppColors.buttonPrimary)
                                .frame(width: 6, height: 6)
                                .offset(y: dotAnimations[index] ? -8 : 0)
                                .opacity(dotAnimations[index] ? 1.0 : 0.5)
                        }
                    }
                }
            } else {
                HStack(spacing: 4) {
                    Text("Réflexion en cours".localized)
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(AppColors.primaryText)
                    
                    HStack(spacing: 4) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(AppColors.buttonPrimary)
                                .frame(width: 6, height: 6)
                                .offset(y: dotAnimations[index] ? -8 : 0)
                                .opacity(dotAnimations[index] ? 1.0 : 0.5)
                        }
                    }
                }
            }
        }
        .onAppear {
            // Animation de rotation continue
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            
            // Animation de pulsation
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                scale = 1.2
                opacity = 0.8
            }
            
            // Animation séquentielle des points
            for index in 0..<3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.2) {
                    withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
                        dotAnimations[index] = true
                    }
                }
            }
        }
    }
}

/// Variante compacte pour les petits espaces
struct AIThinkingAnimationCompact: View {
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(AppColors.buttonPrimary.opacity(0.3), lineWidth: 2)
                .frame(width: 24, height: 24)
                .rotationEffect(.degrees(rotationAngle))
            
            Circle()
                .fill(AppColors.buttonPrimary.opacity(0.5))
                .frame(width: 16, height: 16)
                .scaleEffect(scale)
            
            Image(systemName: "sparkles")
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(AppColors.buttonPrimary)
        }
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotationAngle = 360
            }
            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                scale = 1.3
            }
        }
    }
}

