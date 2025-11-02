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
                description: "Votre assistant personnel pour créer des outfits parfaits adaptés à la météo et à votre style.".localized,
                imageColor: .blue
            ),
            TutorialStep(
                icon: "tshirt.fill",
                title: "Ajoutez vos vêtements".localized,
                description: "Commencez par ajouter au moins 5 vêtements dans votre garde-robe avec leurs photos pour que l'IA puisse vous proposer les meilleurs outfits.".localized,
                imageColor: .purple
            ),
            TutorialStep(
                icon: "brain.head.profile",
                title: "Sélection Intelligente".localized,
                description: "Générez des outfits personnalisés en utilisant ChatGPT pour une analyse avancée de vos vêtements, ou utilisez l'algorithme local pour préserver votre confidentialité.".localized,
                imageColor: .orange
            ),
            TutorialStep(
                icon: "calendar",
                title: "Planifiez vos outfits".localized,
                description: "Consultez le calendrier pour planifier vos tenues à l'avance selon la météo prévue. L'IA s'adapte automatiquement aux conditions.".localized,
                imageColor: .green
            ),
            TutorialStep(
                icon: "clock.fill",
                title: "Suivez votre historique".localized,
                description: "Gardez une trace de vos outfits portés et marquez vos favoris pour retrouver facilement vos combinaisons préférées.".localized,
                imageColor: .pink
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
                        TutorialStepView(step: step)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
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
        .onChange(of: currentStep) { oldValue, newValue in
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
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Icône grande
            ZStack {
                Circle()
                    .fill(step.imageColor.opacity(0.2))
                    .frame(width: 180, height: 180)
                
                Image(systemName: step.icon)
                    .font(.system(size: 80))
                    .foregroundColor(step.imageColor)
            }
            
            // Titre et description
            VStack(spacing: 16) {
                Text(step.title)
                    .font(.playfairDisplayBold(size: 32))
                    .foregroundColor(AppColors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text(step.description)
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineSpacing(6)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
        }
        .padding()
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

