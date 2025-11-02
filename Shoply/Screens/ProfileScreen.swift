//
//  ProfileScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

/// Écran de profil utilisateur pour voir et modifier le profil
struct ProfileScreen: View {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var settingsManager = AppSettingsManager.shared
    @State private var profile: UserProfile
    @State private var isEditing = false
    @State private var editedFirstName = ""
    @State private var editedAge = 18
    @State private var editedGender: Gender = .notSpecified
    @State private var showingSaveAlert = false
    @State private var alertMessage = ""
    
    init() {
        // Charger le profil initial ou créer un profil par défaut
        if let loadedProfile = DataManager.shared.loadUserProfile() {
            _profile = State(initialValue: loadedProfile)
        } else {
            _profile = State(initialValue: UserProfile())
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar
                        ZStack {
                            Circle()
                                .fill(AppColors.buttonSecondary)
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppColors.primaryText)
                        }
                        .padding(.top, 20)
                        
                        // Informations du profil
                        if isEditing {
                            // Mode édition
                            VStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Prénom".localized)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.secondaryText)
                                    
                                    TextField("Votre prénom".localized, text: $editedFirstName)
                                        .font(.system(size: 18))
                                        .padding()
                                        .background(AppColors.buttonSecondary)
                                        .roundedCorner(20)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Âge".localized)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.secondaryText)
                                    
                                    Picker("Âge".localized, selection: $editedAge) {
                                        ForEach(10..<100) { age in
                                            Text("\(age) \("ans".localized)").tag(age)
                                        }
                                    }
                                    .pickerStyle(.wheel)
                                    .frame(height: 150)
                                    .background(AppColors.buttonSecondary)
                                    .roundedCorner(20)
                                }
                                
                                VStack(alignment: .leading, spacing: 8) {
                                    Text("Genre".localized)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.secondaryText)
                                    
                                    ForEach(Gender.allCases, id: \.rawValue) { gender in
                                        Button(action: {
                                            editedGender = gender
                                        }) {
                                            HStack {
                                                Text(gender.rawValue)
                                                    .font(.system(size: 18))
                                                    .foregroundColor(AppColors.primaryText)
                                                
                                                Spacer()
                                                
                                                if editedGender == gender {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundColor(AppColors.buttonPrimary)
                                                        .font(.title3)
                                                }
                                            }
                                            .padding()
                                            .background(
                                                RoundedRectangle(cornerRadius: 20)
                                                    .fill(editedGender == gender ? AppColors.buttonSecondary : AppColors.buttonSecondary.opacity(0.5))
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 20)
                                                            .stroke(editedGender == gender ? AppColors.buttonPrimary : Color.clear, lineWidth: 2)
                                                    )
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            // Mode affichage
                            VStack(spacing: 16) {
                                ProfileInfoRow(label: "Prénom".localized, value: profile.firstName.isEmpty ? "Non renseigné".localized : profile.firstName)
                                ProfileInfoRow(label: "Âge".localized, value: profile.age > 0 ? "\(profile.age) \("ans".localized)" : "Non renseigné".localized)
                                ProfileInfoRow(label: "Genre".localized, value: profile.gender.rawValue)
                            }
                            .padding(.horizontal)
                        }
                        
                        Spacer(minLength: 20)
                        
                        // Bouton Paramètres
                        NavigationLink(destination: SettingsScreen()) {
                            HStack {
                                Image(systemName: "gearshape.fill")
                                    .foregroundColor(AppColors.primaryText)
                                Text("Paramètres".localized)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.primaryText)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            .padding()
                            .background(AppColors.buttonSecondary)
                            .roundedCorner(20)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Profil".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        HStack(spacing: 16) {
                            Button("Annuler".localized) {
                                cancelEditing()
                            }
                            .foregroundColor(AppColors.secondaryText)
                            
                            Button("Enregistrer".localized) {
                                saveProfile()
                            }
                            .foregroundColor(AppColors.buttonPrimary)
                            .fontWeight(.semibold)
                        }
                    } else {
                        Button("Modifier".localized) {
                            startEditing()
                        }
                        .foregroundColor(AppColors.buttonPrimary)
                    }
                }
            }
            .alert("Profil".localized, isPresented: $showingSaveAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .id("profile-\(settingsManager.selectedLanguage)") // Force le rafraîchissement quand la langue change
            .sheet(isPresented: $showingTutorial) {
                TutorialScreen(isPresented: $showingTutorial)
            }
        }
        .onAppear {
            loadProfile()
        }
    }
    
    private func loadProfile() {
        if let loadedProfile = dataManager.loadUserProfile() {
            profile = loadedProfile
            editedFirstName = profile.firstName
            editedAge = profile.age
            editedGender = profile.gender
        }
    }
    
    private func startEditing() {
        editedFirstName = profile.firstName
        editedAge = profile.age
        editedGender = profile.gender
        isEditing = true
    }
    
    private func cancelEditing() {
        isEditing = false
        loadProfile()
    }
    
    @State private var showingTutorial = false
    
    private func saveProfile() {
        guard !editedFirstName.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "Le prénom ne peut pas être vide.".localized
            showingSaveAlert = true
            return
        }
        
        // Vérifier s'il y a eu des modifications réelles
        let firstNameChanged = editedFirstName.trimmingCharacters(in: .whitespaces) != profile.firstName
        let ageChanged = editedAge != profile.age
        let genderChanged = editedGender != profile.gender
        let hasChanges = firstNameChanged || ageChanged || genderChanged
        
        // Si aucune modification, ne rien faire et sortir du mode édition
        if !hasChanges {
            isEditing = false
            return
        }
        
        // Vérifier si c'est la première fois qu'un genre valide est défini
        let wasGenderUndefined = profile.gender == .notSpecified
        let isNowDefined = editedGender != .notSpecified
        
        profile.firstName = editedFirstName.trimmingCharacters(in: .whitespaces)
        profile.age = editedAge
        profile.gender = editedGender
        
        dataManager.saveUserProfile(profile)
        
        // La synchronisation iCloud se fait automatiquement depuis ShoplyApp.checkAndSyncWithiCloud()
        // et peut aussi être déclenchée manuellement depuis SettingsScreen
        
        isEditing = false
        alertMessage = "Profil mis à jour avec succès.".localized
        showingSaveAlert = true
        
        // Si c'est la première fois qu'un genre est défini, afficher le tutoriel
        if wasGenderUndefined && isNowDefined && !UserDefaults.hasCompletedTutorial() {
            showingTutorial = true
        }
    }
}

struct ProfileInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 18))
                .foregroundColor(AppColors.primaryText)
        }
        .padding()
        .background(AppColors.buttonSecondary)
        .roundedCorner(20)
    }
}

#Preview {
    ProfileScreen()
}

