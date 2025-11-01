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
    
    let dataManager = DataManager.shared
    
    var body: some View {
        ZStack {
            adaptiveGradient()
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
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(12)
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
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [Color.pink, Color.purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .disabled(currentStep == 0 && firstName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }
    
    private func completeOnboarding() {
        let profile = UserProfile(
            firstName: firstName,
            age: age,
            gender: selectedGender,
            createdAt: Date()
        )
        dataManager.saveUserProfile(profile)
        // Ne pas utiliser navigateToApp, laissez ShoplyApp gérer la navigation
        // navigateToApp = true
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
                    .fill(step <= currentStep ? Color.pink : Color.gray.opacity(0.3))
                    .frame(height: 4)
            }
        }
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
                .foregroundColor(.pink)
                .padding(.top, 80)
            
            Text("Quel est votre prénom ?")
                .font(.playfairDisplayBold(size: 32))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            TextField("Votre prénom", text: $firstName)
                .font(.system(size: 20))
                .textInputAutocapitalization(.words)
                .autocorrectionDisabled(false)
                .focused($isTextFieldFocused)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isTextFieldFocused ? Color.pink : Color.clear, lineWidth: 2)
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
                .foregroundColor(.purple)
                .padding(.top, 80)
            
            Text("Quel est votre âge ?")
                .font(.playfairDisplayBold(size: 32))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Picker("Âge", selection: $age) {
                ForEach(10..<100) { age in
                    Text("\(age) ans").tag(age)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 200)
            .padding(.horizontal, 40)
            
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
                .foregroundColor(.blue)
                .padding(.top, 80)
            
            Text("Quel est votre genre ?")
                .font(.playfairDisplayBold(size: 32))
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
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            if selectedGender == gender {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.pink)
                                    .font(.title2)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(selectedGender == gender ? Color.pink.opacity(0.1) : Color.gray.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedGender == gender ? Color.pink : Color.clear, lineWidth: 2)
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

