//
//  TutorialScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

/// Écran de tutoriel étape par étape
struct TutorialScreen: View {
    @Binding var isPresented: Bool
    @StateObject private var settingsManager = AppSettingsManager.shared
    @State private var currentStep = 0
    @State private var showSkipButton = true
    
    var steps: [TutorialStep] {
        [
            TutorialStep(
                icon: "sparkles",
                title: "Bienvenue dans Shoply !".localized,
                description: "Votre assistant personnel intelligent pour créer des outfits parfaits. Découvrez toutes les fonctionnalités qui vous aideront à organiser votre style.".localized,
                imageColor: AppColors.buttonPrimary
            ),
            TutorialStep(
                icon: "tshirt.fill",
                title: "Gestion de garde-robe".localized,
                description: "Ajoutez vos vêtements avec photos, organisez-les en collections thématiques et créez votre garde-robe digitale complète. Plus vous ajoutez de vêtements, plus les suggestions seront précises.".localized,
                imageColor: AppColors.buttonPrimary
            ),
            TutorialStep(
                icon: "brain.head.profile",
                title: "Shoply AI - Sélection intelligente".localized,
                description: "Générez des outfits personnalisés avec Shoply AI, votre assistant IA créé par William RAUWENS OLIVER. L'IA analyse votre style, la météo et vos préférences pour créer des tenues parfaites.".localized,
                imageColor: AppColors.buttonPrimary
            ),
            TutorialStep(
                icon: "message.fill",
                title: "Chat avec Shoply AI".localized,
                description: "Discutez avec Shoply AI pour obtenir des conseils personnalisés sur la mode, le style et vos tenues. L'IA comprend votre contexte et vous guide dans vos choix.".localized,
                imageColor: AppColors.buttonPrimary
            ),
            TutorialStep(
                icon: "airplane",
                title: "Mode Voyage".localized,
                description: "Planifiez vos voyages avec des checklists intelligentes générées par Shoply AI. L'IA analyse votre destination, la météo et crée une liste personnalisée pour ne rien oublier.".localized,
                imageColor: AppColors.buttonPrimary
            ),
            TutorialStep(
                icon: "calendar",
                title: "Calendrier et historique".localized,
                description: "Planifiez vos outfits à l'avance, consultez votre historique et marquez vos favoris. L'application s'intègre avec votre calendrier iOS pour des suggestions d'événements.".localized,
                imageColor: AppColors.buttonPrimary
            ),
            TutorialStep(
                icon: "heart.fill",
                title: "Wishlist et shopping".localized,
                description: "Créez une wishlist de vêtements désirés, scannez des codes-barres pour comparer les prix et trouvez les meilleures offres. Organisez vos envies par priorité.".localized,
                imageColor: AppColors.buttonPrimary
            ),
            TutorialStep(
                icon: "star.fill",
                title: "Gamification".localized,
                description: "Débloquez des badges, progressez en niveaux et suivez vos achievements. Rendez l'organisation de votre style ludique et motivante avec le système de gamification.".localized,
                imageColor: AppColors.buttonPrimary
            ),
            TutorialStep(
                icon: "briefcase.fill",
                title: "Modes spécialisés".localized,
                description: "Utilisez le Mode Professionnel pour les occasions importantes, le Mode Romantique pour les rendez-vous, et créez des lookbooks PDF de vos meilleurs outfits.".localized,
                imageColor: AppColors.buttonPrimary
            )
        ]
    }
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // En-tête avec bouton passer
                if showSkipButton {
                    HStack {
                        Spacer()
                        Button(action: {
                            completeTutorial()
                        }) {
                            Text("Passer".localized)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.secondaryText)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 20)
                }
                
                // Contenu du tutoriel
                TabView(selection: $currentStep) {
                    ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                        TutorialStepView(step: step, stepIndex: index, currentStep: currentStep)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.5, dampingFraction: 0.8), value: currentStep)
                .padding(.top, 20)
                
                // Indicateur de progression
                HStack(spacing: 8) {
                    ForEach(0..<steps.count, id: \.self) { index in
                        Capsule()
                            .fill(index == currentStep ? AppColors.buttonPrimary : AppColors.buttonSecondary)
                            .frame(width: index == currentStep ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentStep)
                    }
                }
                .padding(.top, 30)
                .padding(.bottom, 40)
                
                // Boutons de navigation
                HStack(spacing: 16) {
                    if currentStep > 0 {
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            HStack {
                                Image(systemName: "chevron.left")
                                Text("Précédent".localized)
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.primaryText)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppColors.buttonSecondary)
                            .cornerRadius(12)
                        }
                    }
                    
                    Button(action: {
                        if currentStep < steps.count - 1 {
                            withAnimation {
                                currentStep += 1
                            }
                        } else {
                            completeTutorial()
                        }
                    }) {
                        HStack {
                            Text(currentStep < steps.count - 1 ? "Suivant".localized : "Commencer".localized)
                            if currentStep < steps.count - 1 {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.buttonPrimaryText)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(AppColors.buttonPrimary)
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
        .onChange(of: currentStep) { newValue in
            // Cacher le bouton "Passer" sur la dernière étape
            showSkipButton = newValue < steps.count - 1
        }
    }
    
    private func completeTutorial() {
        // Marquer le tutoriel comme complété
        UserDefaults.standard.set(true, forKey: "tutorial_completed")
        isPresented = false
    }
}

struct TutorialStep {
    let icon: String
    let title: String
    let description: String
    let imageColor: Color
}

struct TutorialStepView: View {
    let step: TutorialStep
    let stepIndex: Int
    let currentStep: Int
    @Environment(\.colorScheme) private var colorScheme
    @State private var iconScale: CGFloat = 0.5
    @State private var iconRotation: Double = -180
    @State private var contentOpacity: Double = 0
    @State private var contentOffset: CGFloat = 50
    @State private var circlesOpacity: Double = 0
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)
            
            // Panneau pour améliorer la lisibilité
            VStack(spacing: 24) {
                // Icône grande avec animation améliorée
            ZStack {
                // Cercles concentriques animés avec effet de pulsation
                ForEach(0..<2, id: \.self) { index in
                Circle()
                        .stroke(
                            step.imageColor.opacity(0.2 - Double(index) * 0.1),
                            lineWidth: 2
                        )
                        .frame(width: 200 + CGFloat(index * 30), height: 200 + CGFloat(index * 30))
                        .opacity(circlesOpacity)
                        .scaleEffect(iconScale)
                }
                
                // Cercle principal avec animation de rotation
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    step.imageColor.opacity(0.25),
                                    step.imageColor.opacity(0.15)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    .frame(width: 180, height: 180)
                        .overlay {
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            step.imageColor.opacity(0.4),
                                            step.imageColor.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 3
                                )
                        }
                        .shadow(color: step.imageColor.opacity(0.3), radius: 20, x: 0, y: 10)
                
                Image(systemName: step.icon)
                        .font(.system(size: 80, weight: .semibold))
                    .foregroundColor(step.imageColor)
                        .rotationEffect(.degrees(iconRotation))
                }
                .scaleEffect(iconScale)
            }
            
                // Titre et description avec animation améliorée
                VStack(spacing: 14) {
                Text(step.title)
                        .font(.playfairDisplayBold(size: 28))
                    .foregroundColor(AppColors.primaryText)
                    .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                
                Text(step.description)
                        .font(.system(size: 16, weight: .regular))
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                        .padding(.horizontal, 24)
                }
                .opacity(contentOpacity)
                .offset(y: contentOffset)
            }
            .padding(.vertical, 24)
            .padding(.horizontal, 20)
            
            Spacer(minLength: 0)
        }
        .padding()
        .onAppear {
            // Réinitialiser les animations à chaque apparition
            iconScale = 0.5
            iconRotation = -180
            contentOpacity = 0
            contentOffset = 50
            circlesOpacity = 0
            
            // Animation séquentielle améliorée
            // 1. Cercles concentriques
            withAnimation(.easeOut(duration: 0.4)) {
                circlesOpacity = 0.5
            }
            
            // 2. Icône principale avec rotation et scale
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                iconScale = 1.0
                iconRotation = 0
            }
            
            // 3. Contenu avec fade in et slide up
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                    contentOpacity = 1.0
                    contentOffset = 0
                }
            }
        }
        .onChange(of: currentStep) { _, newValue in
            // Rejouer l'animation à CHAQUE fois qu'on arrive sur cette étape
            guard newValue == stepIndex else { return }
            iconScale = 0.5
            iconRotation = -180
            contentOpacity = 0
            contentOffset = 50
            circlesOpacity = 0
            
            withAnimation(.easeOut(duration: 0.4)) {
                circlesOpacity = 0.5
            }
            withAnimation(.spring(response: 0.7, dampingFraction: 0.6)) {
                iconScale = 1.0
                iconRotation = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.75)) {
                    contentOpacity = 1.0
                    contentOffset = 0
                }
            }
        }
    }
}

/// Helper pour vérifier si le tutoriel doit être affiché
extension UserDefaults {
    static func hasCompletedTutorial() -> Bool {
        return standard.bool(forKey: "tutorial_completed")
    }
    
    static func markTutorialAsCompleted() {
        standard.set(true, forKey: "tutorial_completed")
    }
}

#Preview {
    TutorialScreen(isPresented: .constant(true))
}

