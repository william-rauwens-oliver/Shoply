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
                        VStack(spacing: 16) {
                            Button {
                                // Utiliser le service pour déclencher la connexion
                                // S'assurer qu'on est sur le thread principal
                                DispatchQueue.main.async {
                                    appleSignInService.signInWithApple()
                                }
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
                                .shadow(color: AppColors.shadow.opacity(0.2), radius: 8, x: 0, y: 4)
                            }
                            
                            // Bouton pour passer et continuer sans Apple Sign In
                            Button {
                                // Marquer comme authentifié pour continuer (sans vraiment utiliser Apple Sign In)
                                appleSignInService.isAuthenticated = true
                                appleSignInService.errorMessage = nil
                            } label: {
                                Text("Passer cette étape".localized)
                                    .font(.system(size: 14))
                                    .foregroundColor(AppColors.secondaryText)
                                    .underline()
                            }
                        }
                    }
                    
                    if let errorMessage = appleSignInService.errorMessage {
                        VStack(spacing: 12) {
                            Text(errorMessage)
                                .font(.caption)
                                .foregroundColor(.red)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            // Bouton pour réessayer
                            Button {
                                appleSignInService.errorMessage = nil
                                appleSignInService.signInWithApple()
                            } label: {
                                Text("Réessayer".localized)
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.buttonPrimary)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 10)
                                    .background(AppColors.buttonSecondary)
                                    .roundedCorner(12)
                            }
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
            // Vérifier si des données existent dans iCloud
            let hasData = try await CloudKitService.shared.checkIfDataExists()
            
            if hasData {
                // Récupérer les données depuis iCloud
                await restoreFromiCloud()
            } else {
                // Vérifier si un profil local existe
                if dataManager.loadUserProfile() == nil {
                    // Créer un nouveau profil
                    await MainActor.run {
                        showingProfileCreation = true
                    }
                } else {
                    // Sauvegarder les données locales dans iCloud
                    try await CloudKitService.shared.syncAllUserData()
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                appleSignInService.errorMessage = "Erreur de synchronisation: \(error.localizedDescription)".localized
                
                // Si erreur mais pas de profil, créer le profil
                if dataManager.loadUserProfile() == nil {
                    showingProfileCreation = true
                }
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
                            }
                            
                            // Genre
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Genre".localized)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.primaryText)
                                
                                Picker("Genre".localized, selection: $selectedGender) {
                                    ForEach(Gender.allCases, id: \.self) { gender in
                                        Text(gender.rawValue.localized).tag(gender)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding()
                                .background(AppColors.buttonSecondary)
                                .roundedCorner(16)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                        .background(AppColors.buttonSecondary)
                        .roundedCorner(24)
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
                        }
                        .disabled(firstName.isEmpty || age.isEmpty || selectedGender == .notSpecified)
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
        guard let ageInt = Int(age) else { return }
        
        let profile = UserProfile(
            firstName: firstName,
            age: ageInt,
            gender: selectedGender
        )
        
        dataManager.saveUserProfile(profile)
        // saveUserProfile met automatiquement à jour onboardingCompleted
        
        dismiss()
    }
}

