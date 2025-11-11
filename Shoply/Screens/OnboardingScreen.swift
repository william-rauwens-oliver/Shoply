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
    @State private var profileBackgroundImage: UIImage? = nil
    @State private var dateOfBirth: Date = {
        // Date par défaut : il y a 18 ans (donc 18 ans actuellement)
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        var components = DateComponents()
        components.year = currentYear - 18
        components.month = 1
        components.day = 1
        return calendar.date(from: components) ?? Date()
    }()
    @State private var selectedGender: Gender = .notSpecified
    @State private var showingTutorial = false
    @State private var showingAgeError = false
    @State private var showingEmailError = false
    @EnvironmentObject var dataManager: DataManager
    
    // Propriété calculée pour l'âge minimum (15 ans)
    private var minimumDate: Date {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        var components = DateComponents()
        components.year = currentYear - 15 // Maximum 15 ans
        components.month = 12
        components.day = 31
        return calendar.date(from: components) ?? Date()
    }
    
    private var maximumDate: Date {
        let calendar = Calendar.current
        var components = DateComponents()
        components.year = 1920 // Minimum 1920
        components.month = 1
        components.day = 1
        return calendar.date(from: components) ?? Date()
    }
    
    // Calculer l'âge à partir de la date de naissance
    private var calculatedAge: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year ?? 0
    }
    
    var body: some View {
        ZStack {
            // Fond avec dégradé subtil
            LinearGradient(
                colors: [
                    AppColors.background,
                    AppColors.background.opacity(0.96)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
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
                    OnboardingStep1(firstName: $firstName, backgroundImage: $profileBackgroundImage)
                    case 2:
                        OnboardingStep2_Email(email: $email, showingError: $showingEmailError)
                    case 3:
                        OnboardingStep3_DateOfBirth(dateOfBirth: $dateOfBirth, showingError: $showingAgeError, calculatedAge: calculatedAge, minimumDate: minimumDate, maximumDate: maximumDate)
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
                                    if calculatedAge >= 15 {
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
                            (currentStep == 3 && calculatedAge < 15)
                        )
                        .opacity(
                            (currentStep == 1 && firstName.trimmingCharacters(in: .whitespaces).isEmpty) ||
                            (currentStep == 2 && (email.trimmingCharacters(in: .whitespaces).isEmpty || !isValidEmail(email.trimmingCharacters(in: .whitespaces)))) ||
                            (currentStep == 3 && calculatedAge < 15) ? 0.5 : 1.0
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
              calculatedAge >= 15 else {
            // Si l'âge est invalide, afficher l'erreur
            if calculatedAge < 15 {
                showingAgeError = true
            }
            return
        }
        
        // Le genre peut être notSpecified (optionnel)
        
        // Créer un nouveau profil avec toutes les informations
        var profile = UserProfile(
            firstName: trimmedFirstName,
            dateOfBirth: dateOfBirth,
            gender: selectedGender, // Peut être notSpecified
            email: trimmedEmail, // Email saisi par l'utilisateur
                createdAt: Date()
            )
        // Ajouter l'image de fond si fournie
        if let bg = profileBackgroundImage {
            profile.backgroundPhoto = bg
        }
        
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
    @State private var logoScale: CGFloat = 0.8
    @State private var logoRotation: Double = 0
    @State private var featuresOpacity: Double = 0
    @State private var featuresOffset: CGFloat = 30
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo animé avec effet moderne
            VStack(spacing: 32) {
                ZStack {
                    // Cercles animés en arrière-plan
                    ForEach(0..<3, id: \.self) { index in
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppColors.buttonPrimary.opacity(0.3 - Double(index) * 0.1),
                                        AppColors.buttonPrimary.opacity(0.1 - Double(index) * 0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2
                            )
                            .frame(width: 160 + CGFloat(index * 20), height: 160 + CGFloat(index * 20))
                            .opacity(0.6)
                            .blur(radius: CGFloat(index) * 2)
                    }
                    
                    // Logo principal avec effet glassmorphism
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.buttonPrimary.opacity(0.25),
                                        AppColors.buttonPrimary.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 160, height: 160)
                            .overlay {
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: [
                                                AppColors.buttonPrimary.opacity(0.5),
                                                AppColors.buttonPrimary.opacity(0.2)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 3
                                    )
                            }
                            .shadow(color: AppColors.buttonPrimary.opacity(0.4), radius: 20, x: 0, y: 10)
                        
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 70, weight: .bold))
                            .foregroundColor(AppColors.buttonPrimary)
                            .rotationEffect(.degrees(logoRotation))
                    }
                    .scaleEffect(logoScale)
                }
                .padding(.top, 40)
                
                // Titre avec animation
                VStack(spacing: 20) {
                    Text("Bienvenue sur".localized)
                        .font(.system(size: 24, weight: .light))
                        .foregroundColor(AppColors.secondaryText)
                        .opacity(featuresOpacity)
                    
                    Text("Shoply".localized)
                        .font(.playfairDisplayBold(size: 48))
                        .foregroundColor(AppColors.primaryText)
                        .opacity(featuresOpacity)
                    
                    Text("Votre assistant style intelligent".localized)
                        .font(.system(size: 18, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 50)
                        .lineSpacing(6)
                        .opacity(featuresOpacity)
                }
            }
            
            Spacer()
            
            // Points forts avec animation en cascade
            VStack(spacing: 24) {
                ModernFeatureCard(
                    icon: "sparkles",
                    title: "Shoply AI".localized,
                    description: "Intelligence artificielle avancée pour des suggestions personnalisées".localized,
                    delay: 0.1
                )
                .opacity(featuresOpacity)
                .offset(y: featuresOffset)
                
                ModernFeatureCard(
                    icon: "tshirt.fill",
                    title: "Garde-robe complète".localized,
                    description: "Organisez vos vêtements en collections et suivez votre style".localized,
                    delay: 0.2
                )
                .opacity(featuresOpacity)
                .offset(y: featuresOffset)
                
                ModernFeatureCard(
                    icon: "airplane",
                    title: "Mode Voyage".localized,
                    description: "Planifiez vos outfits de voyage avec checklist intelligente".localized,
                    delay: 0.3
                )
                .opacity(featuresOpacity)
                .offset(y: featuresOffset)
            }
            .padding(.horizontal, 30)
            .padding(.bottom, 40)
        }
        .onAppear {
            // Animation du logo
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                logoScale = 1.0
            }
            
            withAnimation(.linear(duration: 20).repeatForever(autoreverses: false)) {
                logoRotation = 360
            }
            
            // Animation des features
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    featuresOpacity = 1.0
                    featuresOffset = 0
                }
            }
        }
    }
}

struct ModernFeatureCard: View {
    let icon: String
    let title: String
    let description: String
    let delay: Double
    @State private var isVisible = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
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
                    .frame(width: 56, height: 56)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(AppColors.buttonPrimary.opacity(0.3), lineWidth: 1.5)
                    }
                
                Image(systemName: icon)
                    .font(.system(size: 26, weight: .semibold))
                    .foregroundColor(AppColors.buttonPrimary)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(AppColors.primaryText)
                
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(2)
            }
            
            Spacer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(AppColors.buttonSecondary)
                .overlay {
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppColors.cardBorder.opacity(0.2), lineWidth: 1)
                }
        )
        .shadow(color: AppColors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
        .scaleEffect(isVisible ? 1.0 : 0.95)
        .opacity(isVisible ? 1.0 : 0)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    isVisible = true
                }
            }
        }
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
    @Binding var backgroundImage: UIImage?
    @FocusState private var isTextFieldFocused: Bool
    @State private var selectedBackgroundItem: PhotosPickerItem?
    
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
            
            // Image de fond (optionnel)
            VStack(alignment: .leading, spacing: 12) {
                Text("Image de fond (optionnel)".localized)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.primaryText)
                    .padding(.horizontal, 40)
                
                HStack(spacing: 12) {
                    if let bg = backgroundImage {
                        Image(uiImage: bg)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 140)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .overlay {
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 1)
                            }
                            .padding(.leading, 40)
                        
                        Button {
                            backgroundImage = nil
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Supprimer".localized)
                            }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                            .background(AppColors.buttonSecondary)
                            .roundedCorner(12)
                        }
                        .padding(.trailing, 40)
                    } else {
                        PhotosPicker(selection: $selectedBackgroundItem, matching: .images) {
                            HStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 22, weight: .medium))
                                Text("Choisir une image de fond".localized)
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(AppColors.primaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColors.buttonSecondary)
                            .roundedCorner(16)
                            .padding(.horizontal, 40)
                        }
                        .onChange(of: selectedBackgroundItem) { oldValue, newValue in
                            Task {
                                if let newValue = newValue,
                                   let data = try? await newValue.loadTransferable(type: Data.self),
                                   let image = UIImage(data: data) {
                                    await MainActor.run {
                                        backgroundImage = image
                                    }
                                }
                            }
                        }
                    }
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

// MARK: - Étape 3: Date de naissance
struct OnboardingStep3_DateOfBirth: View {
    @Binding var dateOfBirth: Date
    @Binding var showingError: Bool
    let calculatedAge: Int
    let minimumDate: Date
    let maximumDate: Date
    
    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "calendar")
                .font(.system(size: 80))
                .foregroundColor(AppColors.primaryText)
                .shadow(color: AppColors.shadow.opacity(0.3), radius: 8, x: 0, y: 4)
                .padding(.top, 80)
            
            VStack(spacing: 12) {
                Text("Quelle est votre date de naissance ?")
                    .font(.playfairDisplayBold(size: 32))
                        .foregroundColor(AppColors.primaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                
                Text("Vous devez avoir au minimum 15 ans")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppColors.secondaryText)
                
                if calculatedAge > 0 {
                    Text("Vous avez \(calculatedAge) ans")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(calculatedAge >= 15 ? .green : .red)
                        .padding(.top, 4)
                }
            }
            .padding(.horizontal)
            
            // DatePicker avec design moderne
            VStack(spacing: 20) {
                DatePicker(
                    "",
                    selection: $dateOfBirth,
                    in: maximumDate...minimumDate,
                    displayedComponents: .date
                )
                .datePickerStyle(.wheel)
                .labelsHidden()
            .frame(height: 200)
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(AppColors.buttonSecondary)
                .roundedCorner(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 1)
                )
                .shadow(color: AppColors.shadow, radius: 12, x: 0, y: 6)
                .tint(AppColors.buttonPrimary)
                .onChange(of: dateOfBirth) { oldValue, newValue in
                    // Cacher l'erreur si l'âge devient valide
                    let calendar = Calendar.current
                    let ageComponents = calendar.dateComponents([.year], from: newValue, to: Date())
                    if let age = ageComponents.year, age >= 15 {
                        showingError = false
                    }
                }
            }
            .padding(.horizontal, 40)
            
            if showingError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 16))
                    Text("Vous devez avoir au minimum 15 ans pour utiliser l'application")
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

