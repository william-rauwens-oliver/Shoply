//
//  AppleSignInScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 02/11/2025.
//

import SwiftUI
import AuthenticationServices

struct AppleSignInScreen: View {
    @StateObject private var appleSignInService = AppleSignInService.shared
    @StateObject private var dataManager = DataManager.shared
    @State private var isLoading = false
    @State private var showingProfileCreation = false
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Logo et titre
                VStack(spacing: 20) {
                    // Logo Shoply
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
                            .frame(width: 120, height: 120)
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
                            .font(.system(size: 50, weight: .semibold))
                            .foregroundColor(AppColors.buttonPrimary)
                    }
                    .shadow(color: AppColors.buttonPrimary.opacity(0.2), radius: 12, x: 0, y: 4)
                    
                    Text("Bienvenue sur Shoply".localized)
                        .font(.playfairDisplayBold(size: 32))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Votre assistant style intelligent".localized)
                        .font(.system(size: 18))
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                }
                
                Spacer()
                
                // Bouton Apple Sign In
                VStack(spacing: 16) {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(1.2)
                            .padding()
                    } else {
                        Button {
                            // Utiliser le service pour déclencher la connexion
                            // Apple gère automatiquement Touch ID / Face ID ou demande le mot de passe
                            appleSignInService.signInWithApple()
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "applelogo")
                                    .font(.system(size: 18, weight: .semibold))
                                
                                Text("Se connecter avec Apple".localized)
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.black)
                            .cornerRadius(12)
                            .shadow(color: AppColors.shadow, radius: 12, x: 0, y: 6)
                        }
                    }
                    
                    if let errorMessage = appleSignInService.errorMessage {
                        VStack(spacing: 16) {
                            // Message d'erreur plus informatif
                            VStack(spacing: 8) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(AppColors.buttonPrimary.opacity(0.8))
                                
                            Text(errorMessage)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(AppColors.buttonSecondary)
                            .roundedCorner(16)
                            .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 3)
                            
                            // Bouton pour continuer (plus visible que réessayer)
                            Button {
                                // Effacer l'erreur et passer à l'onboarding
                                appleSignInService.errorMessage = nil
                                UserDefaults.standard.set(true, forKey: "hasSeenAppleSignInScreen")
                            } label: {
                                Text("Continuer sans Apple Sign In".localized)
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(AppColors.buttonPrimaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(AppColors.buttonPrimary)
                                    .roundedCorner(12)
                                    .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 4)
                            }
                            
                            // Option pour réessayer (plus petit, optionnel)
                            Button {
                                appleSignInService.errorMessage = nil
                                appleSignInService.signInWithApple()
                            } label: {
                                Text("Réessayer".localized)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppColors.secondaryText)
                                    .padding(.top, 8)
                            }
                        }
                        .padding(.top, 8)
                    }
                    
                    // Bouton pour continuer sans Apple Sign In (seulement si pas d'erreur)
                    if appleSignInService.errorMessage == nil {
                        Button {
                            // Marquer comme vu pour passer à l'onboarding
                            UserDefaults.standard.set(true, forKey: "hasSeenAppleSignInScreen")
                            // Forcer la mise à jour de l'interface pour passer à l'onboarding
                            // En réinitialisant l'état d'authentification si nécessaire
                            DispatchQueue.main.async {
                                // Cela permettra à ShoplyApp de détecter que l'utilisateur a choisi de passer
                                // et d'afficher l'onboarding à la place
                            }
                        } label: {
                            Text("Continuer sans Apple Sign In".localized)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(AppColors.secondaryText)
                                .padding(.top, 12)
                        }
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 60)
            }
        }
        .sheet(isPresented: $showingProfileCreation) {
            ProfileCreationScreen()
        }
        .onAppear {
            // Si déjà authentifié, vérifier si le profil existe
            if appleSignInService.isAuthenticated {
                checkProfileExists()
            }
        }
        .onChange(of: appleSignInService.isAuthenticated) { oldValue, newValue in
            if newValue {
                // Si l'authentification a réussi, synchroniser avec iCloud
                Task {
                    await syncWithiCloud()
                }
            }
        }
    }
    
    
    private func syncWithiCloud() async {
        do {
            // Vérifier si des données existent dans iCloud pour cet email
            let hasData = try await CloudKitService.shared.checkIfDataExists()
            
            if hasData {
                // Récupérer les données depuis iCloud
                await restoreFromiCloud()
                
                // Après restauration, vérifier si le profil est complet
                if let profile = dataManager.loadUserProfile() {
                    // Mettre à jour l'email si nécessaire
                    if let email = appleSignInService.userEmail {
                        var updatedProfile = profile
                        updatedProfile.email = email
                        dataManager.saveUserProfile(updatedProfile)
                    }
                    
                    // Si le profil est complet (prénom rempli), on va directement à l'accueil
                    // Sinon on passe à l'onboarding
                    if !profile.firstName.isEmpty {
                        // Profil complet - aller directement à l'accueil
                        // La logique dans ShoplyApp.swift détectera automatiquement que onboardingCompleted est true
                        await MainActor.run {
                            isLoading = false
                        }
                        return
                    }
                }
            } else {
                // Pas de données dans iCloud, vérifier le profil local
                if let profile = dataManager.loadUserProfile() {
                    // Mettre à jour l'email si nécessaire
                    if let email = appleSignInService.userEmail {
                        var updatedProfile = profile
                        updatedProfile.email = email
                        dataManager.saveUserProfile(updatedProfile)
                    }
                    
                    // Si le profil local est complet, sauvegarder dans iCloud et aller à l'accueil
                    if !profile.firstName.isEmpty {
                        try await CloudKitService.shared.syncAllUserData()
                    await MainActor.run {
                            isLoading = false
                        }
                        return
                    }
                } else {
                    // Pas de profil local, créer un profil minimal avec l'email
                    if let email = appleSignInService.userEmail {
                        let newProfile = UserProfile(email: email)
                        dataManager.saveUserProfile(newProfile)
                }
            }
            }
            
            // Si on arrive ici, le profil est incomplet ou n'existe pas
            // On passe à l'onboarding (qui sera affiché automatiquement par ShoplyApp.swift)
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                appleSignInService.errorMessage = "Erreur de synchronisation: \(error.localizedDescription)".localized
            }
                
            // En cas d'erreur, vérifier si un profil local existe
                if let profile = dataManager.loadUserProfile(),
               !profile.firstName.isEmpty {
                // Profil local complet, on peut continuer
            } else {
                // Profil incomplet ou absent, on passera à l'onboarding
            }
        }
    }
    
    private func restoreFromiCloud() async {
        do {
            if let profile = try await CloudKitService.shared.loadUserProfile() {
                await MainActor.run {
                    dataManager.saveUserProfile(profile)
                }
            }
            
            let wardrobeItems = try await CloudKitService.shared.loadWardrobe()
            await MainActor.run {
                dataManager.saveWardrobeItems(wardrobeItems)
            }
            
            let conversations = try await CloudKitService.shared.loadConversations()
            if let data = try? JSONEncoder().encode(conversations) {
                UserDefaults.standard.set(data, forKey: "chatConversations")
            }
            
            let history = try await CloudKitService.shared.loadOutfitHistory()
            await MainActor.run {
                let historyStore = OutfitHistoryStore()
                for historicalOutfit in history {
                    // addOutfit attend un MatchedOutfit et une Date, pas un HistoricalOutfit
                    historyStore.addOutfit(historicalOutfit.outfit, date: historicalOutfit.dateWorn)
                }
            }
        } catch {
            print("⚠️ Erreur restauration iCloud: \(error)")
        }
    }
    
    private func checkProfileExists() {
        if dataManager.loadUserProfile() == nil {
            showingProfileCreation = true
        }
    }
}

// MARK: - Écran de création de profil

struct ProfileCreationScreen: View {
    @StateObject private var dataManager = DataManager.shared
    @Environment(\.dismiss) var dismiss
    
    @State private var firstName: String = ""
    @State private var age: String = ""
    @State private var selectedGender: Gender = .notSpecified
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // En-tête
                        VStack(spacing: 12) {
                            Text("Créer votre profil".localized)
                                .font(.playfairDisplayBold(size: 28))
                                .foregroundColor(AppColors.primaryText)
                            
                            Text("Complétez votre profil pour des suggestions personnalisées".localized)
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 40)
                        
                        // Formulaire
                        VStack(spacing: 24) {
                            // Prénom
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Prénom".localized)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.primaryText)
                                
                                TextField("Votre prénom".localized, text: $firstName)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding()
                                    .background(AppColors.buttonSecondary)
                                    .roundedCorner(16)
                                    .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 3)
                            }
                            
                            // Âge
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Âge".localized)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.primaryText)
                                
                                TextField("Votre âge".localized, text: $age)
                                    .keyboardType(.numberPad)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .padding()
                                    .background(AppColors.buttonSecondary)
                                    .roundedCorner(16)
                                    .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 3)
                            }
                            
                            // Genre
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 4) {
                                Text("Genre".localized)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.primaryText)
                                    Text("(Optionnel)".localized)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(AppColors.secondaryText)
                                }
                                
                                Picker("Genre".localized, selection: $selectedGender) {
                                    ForEach(Gender.allCases, id: \.self) { gender in
                                        Text(gender.rawValue.localized).tag(gender)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding()
                                .background(AppColors.buttonSecondary)
                                .roundedCorner(16)
                                .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 3)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                        .background(AppColors.buttonSecondary)
                        .roundedCorner(24)
                        .shadow(color: AppColors.shadow, radius: 10, x: 0, y: 5)
                        .padding(.horizontal)
                        
                        // Bouton continuer
                        Button {
                            saveProfile()
                        } label: {
                            Text("Continuer".localized)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(AppColors.buttonPrimaryText)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.buttonPrimary)
                                .roundedCorner(16)
                                .shadow(color: AppColors.shadow, radius: 10, x: 0, y: 5)
                        }
                        .disabled(firstName.isEmpty || age.isEmpty)
                        .opacity((firstName.isEmpty || age.isEmpty) ? 0.5 : 1.0)
                        .padding(.horizontal)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Profil".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(AppColors.primaryText)
                    }
                }
            }
        }
    }
    
    private func saveProfile() {
        // Validation : prénom et âge obligatoires, genre optionnel
        guard !firstName.trimmingCharacters(in: .whitespaces).isEmpty,
              let ageInt = Int(age), ageInt >= 1 else { return }
        
        // Récupérer l'email Apple si disponible
        let appleEmail = UserDefaults.standard.string(forKey: "apple_user_email")
        
        let profile = UserProfile(
            firstName: firstName,
            age: ageInt,
            gender: selectedGender, // Peut être notSpecified (optionnel)
            email: appleEmail,
            createdAt: Date()
        )
        
        dataManager.saveUserProfile(profile)
        // saveUserProfile met automatiquement à jour onboardingCompleted
        
        dismiss()
    }
}

