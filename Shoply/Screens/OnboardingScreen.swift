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
    @State private var email = ""
    @State private var age = 18 // Âge par défaut >= 15 ans
    @State private var selectedGender: Gender = .notSpecified
    @State private var showingTutorial = false
    @State private var showingAgeError = false
    @State private var showingEmailError = false
    @EnvironmentObject var dataManager: DataManager
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Indicateur de progression (masqué sur la page de bienvenue)
                if currentStep > 0 {
                    ProgressIndicator(currentStep: currentStep - 1, totalSteps: 4)
                        .padding(.top, 50)
                        .padding(.horizontal)
                } else {
                    // Espace vide pour maintenir la structure
                    Spacer()
                        .frame(height: 50)
                }
                
                // Contenu des étapes - Utiliser une vue conditionnelle au lieu de TabView pour éviter les problèmes de swipe
                Group {
                    switch currentStep {
                    case 0:
                        OnboardingStep0_Welcome()
                    case 1:
                        OnboardingStep1(firstName: $firstName)
                    case 2:
                        OnboardingStep2_Email(email: $email, showingError: $showingEmailError)
                    case 3:
                        OnboardingStep3_Age(age: $age, showingError: $showingAgeError)
                    case 4:
                        OnboardingStep4_Gender(selectedGender: $selectedGender)
                    default:
                        OnboardingStep0_Welcome()
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
                .animation(.spring(response: 0.3, dampingFraction: 0.8), value: currentStep)
                
                // Boutons de navigation
                if currentStep > 0 {
                    HStack(spacing: 20) {
                        if currentStep > 1 {
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
                                    .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 4)
                            }
                        } else {
                            Spacer()
                                .frame(maxWidth: .infinity)
                        }
                        
                        Button(action: {
                            if currentStep < 4 {
                                // Valider avant de passer à l'étape suivante
                                if currentStep == 1 {
                                    // Validation prénom - doit être rempli
                                    if !firstName.trimmingCharacters(in: .whitespaces).isEmpty {
                                        withAnimation {
                                            currentStep += 1
                                        }
                                    }
                                } else if currentStep == 2 {
                                    // Validation email - doit être rempli et valide
                                    let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
                                    if !trimmedEmail.isEmpty && isValidEmail(trimmedEmail) {
                                        showingEmailError = false
                                        withAnimation {
                                            currentStep += 1
                                        }
                                    } else {
                                        showingEmailError = true
                                    }
                                } else if currentStep == 3 {
                                    // Validation âge - doit être au minimum 15 ans
                                    if age >= 15 {
                                        showingAgeError = false
                                        withAnimation {
                                            currentStep += 1
                                        }
                                    } else {
                                        showingAgeError = true
                                    }
                                } else {
                                    // Étape 0 (bienvenue) ou autre - passer à l'étape suivante
                                    withAnimation {
                                        currentStep += 1
                                    }
                                }
                            } else {
                                completeOnboarding()
                            }
                        }) {
                            Text(currentStep < 4 ? "Suivant" : "Terminer")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.buttonPrimaryText)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.buttonPrimary)
                                .roundedCorner(20)
                                .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 4)
                        }
                        .disabled(
                            (currentStep == 1 && firstName.trimmingCharacters(in: .whitespaces).isEmpty) ||
                            (currentStep == 2 && (email.trimmingCharacters(in: .whitespaces).isEmpty || !isValidEmail(email.trimmingCharacters(in: .whitespaces)))) ||
                            (currentStep == 3 && age < 15)
                        )
                        .opacity(
                            (currentStep == 1 && firstName.trimmingCharacters(in: .whitespaces).isEmpty) ||
                            (currentStep == 2 && (email.trimmingCharacters(in: .whitespaces).isEmpty || !isValidEmail(email.trimmingCharacters(in: .whitespaces)))) ||
                            (currentStep == 3 && age < 15) ? 0.5 : 1.0
                        )
                    }
                    .padding(.horizontal, 30)
                    .padding(.bottom, 50)
                } else {
                    // Page de bienvenue - bouton centré
                    Button(action: {
                        withAnimation {
                            currentStep += 1
                        }
                    }) {
                        Text("Pour commencer".localized)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.buttonPrimaryText)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.buttonPrimary)
                            .roundedCorner(20)
                            .shadow(color: AppColors.shadow, radius: 12, x: 0, y: 6)
                    }
                    .padding(.horizontal, 40)
                    .padding(.bottom, 50)
                }
            }
            .sheet(isPresented: $showingTutorial) {
                TutorialScreen(isPresented: $showingTutorial)
            }
        }
    }
    
    // Fonction pour valider l'email avec vérification du domaine
    private func isValidEmail(_ email: String) -> Bool {
        return EmailValidation.isValidEmail(email)
    }
    
    private func completeOnboarding() {
        // Vérifier que tous les champs obligatoires sont remplis
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        
        guard !trimmedFirstName.isEmpty,
              !trimmedEmail.isEmpty,
              isValidEmail(trimmedEmail),
              age >= 15 else {
            // Si l'âge est invalide, afficher l'erreur
            if age < 15 {
                showingAgeError = true
            }
            return
        }
        
        // Le genre peut être notSpecified (optionnel)
        
        // Créer un nouveau profil avec toutes les informations
        let profile = UserProfile(
            firstName: trimmedFirstName,
            age: age,
            gender: selectedGender, // Peut être notSpecified
            email: trimmedEmail, // Email saisi par l'utilisateur
            createdAt: Date()
        )
        
        // Sauvegarder le profil en local (UserDefaults via DataManager)
        dataManager.saveUserProfile(profile)
        
        // La synchronisation iCloud se fait automatiquement depuis ShoplyApp.checkAndSyncWithiCloud()
        // et peut aussi être déclenchée manuellement depuis SettingsScreen
        
        // Si c'est la première fois qu'un genre est défini et que le tutoriel n'a pas été complété, l'afficher
        if selectedGender != .notSpecified && !UserDefaults.hasCompletedTutorial() {
            // Attendre un court instant avant d'afficher le tutoriel
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                showingTutorial = true
            }
        }
        
        // Le changement sera détecté automatiquement par ShoplyApp grâce à @StateObject
    }
}

// MARK: - Étape 0: Page de bienvenue
struct OnboardingStep0_Welcome: View {
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // Logo et illustration
            VStack(spacing: 30) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppColors.buttonPrimary.opacity(0.2),
                                    AppColors.buttonPrimary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 140, height: 140)
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [
                                            AppColors.buttonPrimary.opacity(0.4),
                                            AppColors.buttonPrimary.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                    
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 60, weight: .semibold))
                        .foregroundColor(AppColors.buttonPrimary)
                }
                .shadow(color: AppColors.buttonPrimary.opacity(0.3), radius: 16, x: 0, y: 8)
                
                VStack(spacing: 16) {
                    Text("Bienvenue sur Shoply".localized)
                        .font(.playfairDisplayBold(size: 36))
                        .foregroundColor(AppColors.primaryText)
                        .multilineTextAlignment(.center)
                    
                    Text("Votre assistant style intelligent pour créer des tenues parfaites".localized)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                        .lineSpacing(4)
                }
            }
            
            // Points forts
            VStack(spacing: 20) {
                FeatureItem(icon: "sparkles", title: "Suggestions intelligentes".localized, description: "Basées sur votre style et la météo".localized)
                FeatureItem(icon: "photo.fill", title: "Gestion de votre garde-robe".localized, description: "Organisez tous vos vêtements".localized)
                FeatureItem(icon: "brain.head.profile", title: "Assistant IA".localized, description: "Des conseils personnalisés 24/7".localized)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
}

struct FeatureItem: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(AppColors.buttonSecondary)
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(AppColors.buttonPrimary)
            }
            .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 3)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
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
                .shadow(color: AppColors.shadow.opacity(0.3), radius: 8, x: 0, y: 4)
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
                    .stroke(isTextFieldFocused ? AppColors.buttonPrimary : AppColors.cardBorder.opacity(0.3), lineWidth: isTextFieldFocused ? 2 : 1)
            )
            .shadow(color: AppColors.shadow, radius: 12, x: 0, y: 6)
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

// MARK: - Étape 2: Email
struct OnboardingStep2_Email: View {
    @Binding var email: String
    @Binding var showingError: Bool
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "envelope.fill")
                .font(.system(size: 80))
                .foregroundColor(AppColors.primaryText)
                .shadow(color: AppColors.shadow.opacity(0.3), radius: 8, x: 0, y: 4)
                .padding(.top, 80)
            
            Text("Quel est votre email ?")
                .font(.playfairDisplayBold(size: 32))
                .foregroundColor(AppColors.primaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ZStack(alignment: .leading) {
                // Placeholder visible
                if email.isEmpty {
                    Text("votre.email@exemple.com")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.secondaryText)
                        .padding(.horizontal, 16)
                }
                
                TextField("", text: $email)
                    .font(.system(size: 20))
                    .foregroundColor(AppColors.primaryText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .keyboardType(.emailAddress)
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
                    .stroke(isTextFieldFocused ? AppColors.buttonPrimary : AppColors.cardBorder.opacity(0.3), lineWidth: isTextFieldFocused ? 2 : 1)
            )
            .shadow(color: AppColors.shadow, radius: 12, x: 0, y: 6)
            .padding(.horizontal, 40)
                .onAppear {
                    // Focus automatique après un court délai
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        isTextFieldFocused = true
                    }
                }
                .onChange(of: email) { oldValue, newValue in
                    // Cacher l'erreur si l'email devient valide
                    if EmailValidation.isValidEmail(newValue) {
                        showingError = false
                    }
                }
            
            if showingError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                    Text(EmailValidation.getErrorMessage())
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.1))
                .roundedCorner(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.red.opacity(0.2), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 40)
                .padding(.top, 12)
            }
            
            Spacer()
        }
    }
}

// MARK: - Étape 3: Âge
struct OnboardingStep3_Age: View {
    @Binding var age: Int
    @Binding var showingError: Bool
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "calendar")
                .font(.system(size: 80))
                .foregroundColor(AppColors.primaryText)
                .shadow(color: AppColors.shadow.opacity(0.3), radius: 8, x: 0, y: 4)
                .padding(.top, 80)
            
            VStack(spacing: 12) {
                Text("Quel est votre âge ?")
                    .font(.playfairDisplayBold(size: 32))
                    .foregroundColor(AppColors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text("Vous devez avoir au minimum 15 ans")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppColors.secondaryText)
            }
            .padding(.horizontal)
            
            Picker("Âge", selection: $age) {
                ForEach(15..<100) { age in
                    Text("\(age) ans")
                        .foregroundColor(AppColors.primaryText)
                        .tag(age)
                }
            }
            .pickerStyle(.wheel)
            .frame(height: 200)
            .padding(.vertical, 16)
            .padding(.horizontal, 40)
            .background(AppColors.buttonSecondary)
            .roundedCorner(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: AppColors.shadow, radius: 12, x: 0, y: 6)
            .tint(AppColors.buttonPrimary)
            .onChange(of: age) { oldValue, newValue in
                // Cacher l'erreur si l'âge devient valide
                if newValue >= 15 {
                    showingError = false
                }
            }
            
            if showingError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                    Text("Vous devez avoir au minimum 15 ans pour utiliser l'application")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.red)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color.red.opacity(0.1))
                .roundedCorner(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: Color.red.opacity(0.2), radius: 8, x: 0, y: 4)
                .padding(.horizontal, 40)
                .padding(.top, 8)
            }
            
            Spacer()
        }
    }
}

// MARK: - Étape 4: Genre
struct OnboardingStep4_Gender: View {
    @Binding var selectedGender: Gender
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 80))
                .foregroundColor(AppColors.primaryText)
                .shadow(color: AppColors.shadow.opacity(0.3), radius: 8, x: 0, y: 4)
                .padding(.top, 80)
            
            VStack(spacing: 8) {
                Text("Quel est votre genre ?")
                    .font(.playfairDisplayBold(size: 32))
                    .foregroundColor(AppColors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text("(Optionnel)")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(AppColors.secondaryText)
            }
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
                                .fill(selectedGender == gender ? AppColors.buttonSecondary : AppColors.buttonSecondary.opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(
                                            selectedGender == gender ? AppColors.buttonPrimary : AppColors.cardBorder.opacity(0.4),
                                            lineWidth: selectedGender == gender ? 2 : 1
                                        )
                                )
                        )
                        .shadow(
                            color: AppColors.shadow,
                            radius: selectedGender == gender ? 12 : 8,
                            x: 0,
                            y: selectedGender == gender ? 6 : 4
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

