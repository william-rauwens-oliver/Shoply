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
    @State private var editedEmail = ""
    @State private var editedDateOfBirth: Date = {
        // Date par défaut : il y a 18 ans
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        var components = DateComponents()
        components.year = currentYear - 18
        components.month = 1
        components.day = 1
        return calendar.date(from: components) ?? Date()
    }()
    @State private var editedGender: Gender = .notSpecified
    @State private var showingSaveAlert = false
    @State private var alertMessage = ""
    @FocusState private var isEmailFocused: Bool
    
    // Propriétés calculées pour les limites de date
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
    private var calculatedEditedAge: Int {
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: editedDateOfBirth, to: Date())
        return ageComponents.year ?? 0
    }
    
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
                // Fond opaque simple
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // Avatar moderne avec opacité
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            AppColors.buttonPrimary.opacity(0.12),
                                            AppColors.buttonPrimary.opacity(0.06)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 120, height: 120)
                                .overlay {
                                    Circle()
                                        .stroke(
                                            LinearGradient(
                                                colors: [
                                                    AppColors.cardBorder.opacity(0.4),
                                                    AppColors.cardBorder.opacity(0.2)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 1.5
                                        )
                                }
                            
                            Image(systemName: "person.fill")
                                .font(.system(size: 52, weight: .light))
                                .foregroundColor(AppColors.primaryText.opacity(0.9))
                        }
                        .padding(.top, 40)
                        .shadow(color: AppColors.shadow.opacity(0.2), radius: 16, x: 0, y: 6)
                        
                        // Informations du profil
                        if isEditing {
                            // Mode édition épuré
                            VStack(spacing: 20) {
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Prénom".localized)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppColors.primaryText)
                                    
                                    TextField("Votre prénom".localized, text: $editedFirstName)
                                        .font(.system(size: 17))
                                        .foregroundColor(AppColors.primaryText)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 18)
                                                .fill(Material.regularMaterial)
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 18)
                                                        .stroke(
                                                            LinearGradient(
                                                                colors: [
                                                                    AppColors.cardBorder.opacity(0.4),
                                                                    AppColors.cardBorder.opacity(0.2)
                                                                ],
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            ),
                                                            lineWidth: 1
                                                        )
                                                }
                                        )
                                        .roundedCorner(18)
                                        .shadow(color: AppColors.shadow.opacity(0.15), radius: 10, x: 0, y: 4)
                                }
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Email".localized)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppColors.primaryText)
                                    
                                    TextField("votre.email@exemple.com".localized, text: $editedEmail)
                                        .font(.system(size: 17))
                                        .foregroundColor(AppColors.primaryText)
                                        .keyboardType(.emailAddress)
                                        .textInputAutocapitalization(.never)
                                        .autocorrectionDisabled(true)
                                        .focused($isEmailFocused)
                                        .padding(.horizontal, 20)
                                        .padding(.vertical, 16)
                                        .background(
                                            RoundedRectangle(cornerRadius: 18)
                                                .fill(Material.regularMaterial)
                                        .overlay {
                                                    RoundedRectangle(cornerRadius: 18)
                                                        .stroke(
                                                            isEmailFocused
                                                                ? LinearGradient(
                                                                    colors: [
                                                                        AppColors.buttonPrimary.opacity(0.6),
                                                                        AppColors.buttonPrimary.opacity(0.3)
                                                                    ],
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                )
                                                                : LinearGradient(
                                                                    colors: [
                                                                        AppColors.cardBorder.opacity(0.4),
                                                                        AppColors.cardBorder.opacity(0.2)
                                                                    ],
                                                                    startPoint: .topLeading,
                                                                    endPoint: .bottomTrailing
                                                                ),
                                                            lineWidth: isEmailFocused ? 2 : 1
                                                        )
                                        }
                                        )
                                        .roundedCorner(18)
                                        .shadow(color: AppColors.shadow.opacity(isEmailFocused ? 0.2 : 0.15), radius: isEmailFocused ? 12 : 10, x: 0, y: isEmailFocused ? 5 : 4)
                                }
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Date de naissance".localized)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppColors.primaryText)
                                    
                                    VStack(spacing: 8) {
                                        DatePicker(
                                            "",
                                            selection: $editedDateOfBirth,
                                            in: maximumDate...minimumDate,
                                            displayedComponents: .date
                                        )
                                        .datePickerStyle(.wheel)
                                        .labelsHidden()
                                        .frame(height: 140)
                                        
                                        if calculatedEditedAge > 0 {
                                            Text("Vous avez \(calculatedEditedAge) ans".localized)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(calculatedEditedAge >= 15 ? .green : .red)
                                        }
                                    }
                                    .background(AppColors.cardBackground)
                                    .overlay {
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 0.5)
                                    }
                                    .roundedCorner(16)
                                    .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 3)
                                }
                                
                                VStack(alignment: .leading, spacing: 10) {
                                    Text("Genre".localized)
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(AppColors.primaryText)
                                    
                                    VStack(spacing: 10) {
                                        ForEach(Gender.allCases, id: \.rawValue) { gender in
                                            Button(action: {
                                                editedGender = gender
                                            }) {
                                                HStack(spacing: 12) {
                                                    Text(gender.rawValue)
                                                        .font(.system(size: 16, weight: .medium))
                                                        .foregroundColor(AppColors.primaryText)
                                                    
                                                    Spacer()
                                                    
                                                    if editedGender == gender {
                                                        Image(systemName: "checkmark.circle.fill")
                                                            .font(.system(size: 20))
                                                            .foregroundColor(AppColors.buttonPrimary)
                                                    }
                                                }
                                                .padding(.horizontal, 18)
                                                .padding(.vertical, 14)
                                                .background(
                                                    editedGender == gender ? AppColors.buttonSecondary : AppColors.cardBackground
                                                )
                                                .overlay {
                                                    RoundedRectangle(cornerRadius: 14)
                                                        .stroke(
                                                            editedGender == gender ? AppColors.buttonPrimary : AppColors.cardBorder.opacity(0.3),
                                                            lineWidth: editedGender == gender ? 1.5 : 0.5
                                                        )
                                                }
                                                .roundedCorner(14)
                                                .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 3)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        } else {
                            // Mode affichage épuré
                            VStack(spacing: 12) {
                                ProfileInfoRow(label: "Prénom".localized, value: profile.firstName.isEmpty ? "Non renseigné".localized : profile.firstName)
                                
                                // Toujours afficher l'email s'il existe
                                if let email = profile.email, !email.isEmpty {
                                    ProfileInfoRow(label: "Email".localized, value: email)
                                } else {
                                    ProfileInfoRow(label: "Email".localized, value: "Non renseigné".localized)
                                }
                                
                                ProfileInfoRow(label: "Âge".localized, value: profile.age > 0 ? "\(profile.age) \("ans".localized)" : "Non renseigné".localized)
                                ProfileInfoRow(label: "Genre".localized, value: profile.gender.rawValue)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        Spacer(minLength: 20)
                        
                        // Bouton Paramètres
                        NavigationLink(destination: SettingsScreen()) {
                            HStack(spacing: 14) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppColors.primaryText)
                                Text("Paramètres".localized)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.primaryText)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.cardBackground)
                            .overlay {
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 0.5)
                            }
                            .roundedCorner(18)
                            .shadow(color: AppColors.shadow.opacity(0.06), radius: 8, x: 0, y: 2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationTitle("Profil")
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
            editedEmail = profile.email ?? ""
            // Utiliser dateOfBirth si disponible, sinon calculer à partir de l'âge
            if let dateOfBirth = profile.dateOfBirth {
                editedDateOfBirth = dateOfBirth
            } else if profile.age > 0 {
                // Calculer une date approximative à partir de l'âge
                let calendar = Calendar.current
                let currentYear = calendar.component(.year, from: Date())
                var components = DateComponents()
                components.year = currentYear - profile.age
                components.month = 1
                components.day = 1
                editedDateOfBirth = calendar.date(from: components) ?? editedDateOfBirth
            }
            editedGender = profile.gender
        }
    }
    
    private func startEditing() {
        editedFirstName = profile.firstName
        editedEmail = profile.email ?? ""
        // Utiliser dateOfBirth si disponible, sinon calculer à partir de l'âge
        if let dateOfBirth = profile.dateOfBirth {
            editedDateOfBirth = dateOfBirth
        } else if profile.age > 0 {
            // Calculer une date approximative à partir de l'âge
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: Date())
            var components = DateComponents()
            components.year = currentYear - profile.age
            components.month = 1
            components.day = 1
            editedDateOfBirth = calendar.date(from: components) ?? editedDateOfBirth
        }
        editedGender = profile.gender
        isEditing = true
    }
    
    private func cancelEditing() {
        isEditing = false
        loadProfile()
    }
    
    @State private var showingTutorial = false
    
    // Fonction pour valider l'email avec vérification du domaine
    private func isValidEmail(_ email: String) -> Bool {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)
        if trimmedEmail.isEmpty {
            return true // Email optionnel - vide est valide
        }
        return EmailValidation.isValidEmail(trimmedEmail)
    }
    
    private func saveProfile() {
        guard !editedFirstName.trimmingCharacters(in: .whitespaces).isEmpty else {
            alertMessage = "Le prénom ne peut pas être vide.".localized
            showingSaveAlert = true
            return
        }
        
        // Valider l'email s'il est renseigné
        let trimmedEmail = editedEmail.trimmingCharacters(in: .whitespaces)
        if !trimmedEmail.isEmpty && !isValidEmail(trimmedEmail) {
            alertMessage = EmailValidation.getErrorMessage()
            showingSaveAlert = true
            return
        }
        
        // Vérifier que l'âge minimum est respecté (15 ans)
        if calculatedEditedAge < 15 {
            alertMessage = "Vous devez avoir au minimum 15 ans.".localized
            showingSaveAlert = true
            return
        }
        
        // Vérifier s'il y a eu des modifications réelles
        let firstNameChanged = editedFirstName.trimmingCharacters(in: .whitespaces) != profile.firstName
        let emailChanged = trimmedEmail != (profile.email ?? "")
        let dateOfBirthChanged = editedDateOfBirth != (profile.dateOfBirth ?? Date())
        let genderChanged = editedGender != profile.gender
        let hasChanges = firstNameChanged || emailChanged || dateOfBirthChanged || genderChanged
        
        // Si aucune modification, ne rien faire et sortir du mode édition
        if !hasChanges {
            isEditing = false
            return
        }
        
        // Vérifier si c'est la première fois qu'un genre valide est défini
        let wasGenderUndefined = profile.gender == .notSpecified
        let isNowDefined = editedGender != .notSpecified
        
        profile.firstName = editedFirstName.trimmingCharacters(in: .whitespaces)
        profile.email = trimmedEmail.isEmpty ? nil : trimmedEmail
        profile.dateOfBirth = editedDateOfBirth
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
        HStack(spacing: 16) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.primaryText)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 0.5)
        }
        .roundedCorner(18)
        .shadow(color: AppColors.shadow.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    ProfileScreen()
}

