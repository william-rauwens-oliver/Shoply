//
//  OnboardingScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

/// Écran d'onboarding - Première utilisation
struct OnboardingScreen: View {
    @State private var currentStep = 0
    @State private var firstName = ""
    @State private var age = 18
    @State private var selectedGender: Gender = .notSpecified
    @State private var showingTutorial = false
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Indicateur de progression
                ProgressIndicator(currentStep: currentStep, totalSteps: 3)
                    .padding(.top, 50)
                    .padding(.horizontal)
                
                // Contenu des étapes
                TabView(selection: $currentStep) {
                    // Étape 1: Prénom
                    OnboardingStep1(firstName: $firstName)
                        .tag(0)
                    
                    // Étape 2: Âge
                    OnboardingStep2(age: $age)
                        .tag(1)
                    
                    // Étape 3: Sexe
                    OnboardingStep3(selectedGender: $selectedGender)
                        .tag(2)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .disabled(false)
                
                // Boutons de navigation
                HStack(spacing: 20) {
                    if currentStep > 0 {
                        Button(action: {
                            withAnimation {
                                currentStep -= 1
                            }
                        }) {
                            Text("Précédent")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.primaryText)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.buttonSecondary)
                                .roundedCorner(20)
                        }
                    }
                    
                    Button(action: {
                        if currentStep < 2 {
                            withAnimation {
                                currentStep += 1
                            }
                        } else {
                            completeOnboarding()
                        }
                    }) {
                        Text(currentStep < 2 ? "Suivant" : "Terminer")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.buttonPrimaryText)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.buttonPrimary)
                            .roundedCorner(20)
                    }
                    .disabled(
                        (currentStep == 0 && firstName.trimmingCharacters(in: .whitespaces).isEmpty) ||
                        (currentStep == 2 && selectedGender == .notSpecified)
                    )
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
            .sheet(isPresented: $showingTutorial) {
                TutorialScreen(isPresented: $showingTutorial)
            }
        }
    }
    
    private func completeOnboarding() {
        // Vérifier que le genre est sélectionné
        guard selectedGender != .notSpecified else {
            // Si pas de genre sélectionné, on peut quand même sauvegarder avec notSpecified
            // ou afficher un message d'erreur
            return
        }
        
        let profile = UserProfile(
            firstName: firstName,
            age: age,
            gender: selectedGender,
            createdAt: Date()
        )
        
        // Sauvegarder le profil (cela déclenchera automatiquement le rafraîchissement dans ShoplyApp)
        dataManager.saveUserProfile(profile)
        
        // La synchronisation iCloud se fait automatiquement depuis ShoplyApp.checkAndSyncWithiCloud()
        // et peut aussi être déclenchée manuellement depuis SettingsScreen
        
        // Si c'est la première fois qu'un genre est défini et que le tutoriel n'a pas été complété, l'afficher
        if !UserDefaults.hasCompletedTutorial() {
            // Attendre un court instant avant d'afficher le tutoriel
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingTutorial = true
            }
        }
        
        // Le changement sera détecté automatiquement par ShoplyApp grâce à @StateObject
    }
}

// MARK: - Indicateur de progression
struct ProgressIndicator: View {
    let currentStep: Int
    let totalSteps: Int
    
    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalSteps, id: \.self) { step in
                Capsule()
                    .fill(step <= currentStep ? AppColors.buttonPrimary : AppColors.buttonSecondary)
                    .frame(height: 4)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentStep)
            }
        }
        .padding(.horizontal, 30)
    }
}

// MARK: - Étape 1: Prénom
struct OnboardingStep1: View {
    @Binding var firstName: String
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.fill")
                .font(.system(size: 80))
                .foregroundColor(AppColors.primaryText)
                .padding(.top, 80)
            
            Text("Quel est votre prénom ?")
                .font(.playfairDisplayBold(size: 32))
                .foregroundColor(AppColors.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ZStack(alignment: .leading) {
                // Placeholder visible
                if firstName.isEmpty {
                    Text("Votre prénom")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.secondaryText)
                        .padding(.horizontal, 16)
                }
                
                TextField("", text: $firstName)
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.primaryText)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
                    .focused($isTextFieldFocused)
                    .padding()
                    .tint(AppColors.buttonPrimary)
                    .accentColor(AppColors.buttonPrimary)
                    .submitLabel(.next)
            }
            .background(AppColors.buttonSecondary)
            .roundedCorner(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(isTextFieldFocused ? AppColors.buttonPrimary : Color.clear, lineWidth: 2)
            )
            .padding(.horizontal, 40)
                .onAppear {
                    // Focus automatique après un court délai pour permettre l'animation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isTextFieldFocused = true
                    }
                }
            
            Spacer()
        }
    }
}

// MARK: - Étape 2: Âge
struct OnboardingStep2: View {
    @Binding var age: Int
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "calendar")
                .font(.system(size: 80))
                .foregroundColor(AppColors.primaryText)
                .padding(.top, 80)
            
            Text("Quel est votre âge ?")
                .font(.playfairDisplayBold(size: 32))
                .foregroundColor(AppColors.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Picker("Âge", selection: $age) {
                ForEach(10..<100) { age in
                    Text("\(age) ans")
                        .foregroundColor(AppColors.primaryText)
                        .tag(age)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 200)
            .padding(.horizontal, 40)
            .tint(AppColors.buttonPrimary)
            
            Spacer()
        }
    }
}

// MARK: - Étape 3: Sexe
struct OnboardingStep3: View {
    @Binding var selectedGender: Gender
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 80))
                .foregroundColor(AppColors.primaryText)
                .padding(.top, 80)
            
            Text("Quel est votre genre ?")
                .font(.playfairDisplayBold(size: 32))
                .foregroundColor(AppColors.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 20) {
                ForEach(Gender.allCases, id: \.rawValue) { gender in
                    Button(action: {
                        selectedGender = gender
                    }) {
                        HStack {
                            Text(gender.rawValue)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppColors.primaryText)
                            
                            Spacer()
                            
                            if selectedGender == gender {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.buttonPrimary)
                                    .font(.title2)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedGender == gender ? AppColors.buttonSecondary : AppColors.buttonSecondary.opacity(0.5))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(selectedGender == gender ? AppColors.buttonPrimary : Color.clear, lineWidth: 2)
                                )
                        )
                    }
                }
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

#Preview {
    OnboardingScreen()
}

