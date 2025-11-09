//
//  ProfileScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import PhotosUI

struct ProfileScreen: View {
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var settingsManager = AppSettingsManager.shared
    @State private var profile: UserProfile
    @State private var isEditing = false
    @State private var editedFirstName = ""
    @State private var editedEmail = ""
    @State private var editedDateOfBirth: Date = {
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
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var showingCropView = false
    @State private var showingPhotoPicker = false
    @State private var showingTutorial = false
    @State private var minimumDate: Date = {
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        var components = DateComponents()
        components.year = currentYear - 15
        components.month = 12
        components.day = 31
        return calendar.date(from: components) ?? Date()
    }()
    @State private var maximumDate: Date = {
        var components = DateComponents()
        components.year = 1920
        components.month = 1
        components.day = 1
        return Calendar.current.date(from: components) ?? Date()
    }()
    
    init() {
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
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Header avec photo et nom
                        ProfileHeaderSection(
                            photo: profile.profilePhoto,
                            firstName: profile.firstName,
                            isEditing: isEditing,
                            onPhotoTap: {
                                if isEditing {
                                    showingPhotoPicker = true
                                }
                            }
                        )
                        .padding(.top, DesignSystem.Spacing.xl)
                        .padding(.bottom, DesignSystem.Spacing.lg)
                        
                        // Contenu principal
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            if isEditing {
                                EditProfileSection(
                                    firstName: $editedFirstName,
                                    email: $editedEmail,
                                    dateOfBirth: $editedDateOfBirth,
                                    gender: $editedGender,
                                    minimumDate: minimumDate,
                                    maximumDate: maximumDate
                                )
                            } else {
                                DisplayProfileSection(profile: profile)
                            }
                            
                            // Bouton Paramètres
                            if !isEditing {
                                NavigationLink(destination: SettingsScreen().environmentObject(dataManager)) {
                                    HStack(spacing: DesignSystem.Spacing.md) {
                                        ZStack {
                                            Circle()
                                                .fill(AppColors.buttonSecondary)
                                                .frame(width: 40, height: 40)
                                            
                                            Image(systemName: "gearshape.fill")
                                                .font(.system(size: 18, weight: .medium))
                                                .foregroundColor(AppColors.primaryText)
                                        }
                                        
                                        Text("Paramètres de l'application".localized)
                                            .font(DesignSystem.Typography.body())
                                            .foregroundColor(AppColors.primaryText)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                    .padding(DesignSystem.Spacing.md)
                                    .background(AppColors.cardBackground)
                                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
                                    .overlay {
                                        RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                                            .stroke(AppColors.cardBorder, lineWidth: 1.5)
                                    }
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.bottom, DesignSystem.Spacing.xxl)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditing {
                        HStack(spacing: DesignSystem.Spacing.md) {
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
            .sheet(isPresented: $showingTutorial) {
                TutorialScreen(isPresented: $showingTutorial)
            }
            .photosPicker(
                isPresented: $showingPhotoPicker,
                selection: $selectedPhoto,
                matching: .images,
                photoLibrary: .shared()
            )
            .onChange(of: selectedPhoto) { oldValue, newValue in
                Task {
                    if let newValue = newValue {
                        if let data = try? await newValue.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                selectedImage = image
                                showingCropView = true
                            }
                        }
                    } else {
                        await MainActor.run {
                            selectedImage = nil
                        }
                    }
                }
            }
            .sheet(isPresented: $showingCropView) {
                if selectedImage != nil {
                    ImageCropView(image: Binding(
                        get: { selectedImage },
                        set: { selectedImage = $0 }
                    ))
                }
            }
            .onChange(of: selectedImage) { oldValue, newValue in
                if let newValue = newValue {
                    profile.profilePhoto = newValue
                }
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
            
            // Gérer la date de naissance avec validation
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: Date())
            
            if let dateOfBirth = profile.dateOfBirth {
                // Valider que la date est dans la plage valide
                if dateOfBirth >= maximumDate && dateOfBirth <= minimumDate {
                    editedDateOfBirth = dateOfBirth
                } else {
                    // Date invalide, utiliser une date par défaut
                    var components = DateComponents()
                    components.year = currentYear - 25
                    components.month = 1
                    components.day = 1
                    if let defaultDate = calendar.date(from: components) {
                        if defaultDate >= maximumDate && defaultDate <= minimumDate {
                            editedDateOfBirth = defaultDate
                        } else {
                            editedDateOfBirth = minimumDate
                        }
                    } else {
                        editedDateOfBirth = minimumDate
                    }
                }
            } else if profile.age > 0 {
                var components = DateComponents()
                components.year = currentYear - profile.age
                components.month = 1
                components.day = 1
                if let calculatedDate = calendar.date(from: components) {
                    if calculatedDate >= maximumDate && calculatedDate <= minimumDate {
                        editedDateOfBirth = calculatedDate
                    } else {
                        editedDateOfBirth = minimumDate
                    }
                } else {
                    editedDateOfBirth = minimumDate
                }
            } else {
                // Pas de date, utiliser une date par défaut
                var components = DateComponents()
                components.year = currentYear - 25
                components.month = 1
                components.day = 1
                if let defaultDate = calendar.date(from: components) {
                    if defaultDate >= maximumDate && defaultDate <= minimumDate {
                        editedDateOfBirth = defaultDate
                    } else {
                        editedDateOfBirth = minimumDate
                    }
                } else {
                    editedDateOfBirth = minimumDate
                }
            }
            
            editedGender = profile.gender
        }
    }
    
    private func startEditing() {
        // Recharger le profil depuis le dataManager pour s'assurer qu'il est à jour
        if let loadedProfile = dataManager.loadUserProfile() {
            profile = loadedProfile
        }
        
        // Initialiser les valeurs d'édition de manière sécurisée
        editedFirstName = profile.firstName.isEmpty ? "" : profile.firstName
        editedEmail = profile.email ?? ""
        
        // Gérer la date de naissance - toujours avoir une date valide
        // maximumDate est la date la plus ancienne (1920), minimumDate est la date la plus récente (il y a 15 ans)
        let calendar = Calendar.current
        let currentYear = calendar.component(.year, from: Date())
        
        if let dateOfBirth = profile.dateOfBirth {
            // Vérifier que la date est dans la plage valide (maximumDate <= date <= minimumDate)
            if dateOfBirth >= maximumDate && dateOfBirth <= minimumDate {
                editedDateOfBirth = dateOfBirth
            } else {
                // Si la date n'est pas valide, utiliser une date par défaut (25 ans)
                var components = DateComponents()
                components.year = currentYear - 25
                components.month = 1
                components.day = 1
                if let defaultDate = calendar.date(from: components) {
                    // S'assurer que la date par défaut est dans la plage valide
                    if defaultDate >= maximumDate && defaultDate <= minimumDate {
                        editedDateOfBirth = defaultDate
                    } else {
                        // Si même la date par défaut n'est pas valide, utiliser minimumDate
                        editedDateOfBirth = minimumDate
                    }
                } else {
                    editedDateOfBirth = minimumDate
                }
            }
        } else if profile.age > 0 {
            var components = DateComponents()
            components.year = currentYear - profile.age
            components.month = 1
            components.day = 1
            if let calculatedDate = calendar.date(from: components) {
                // Vérifier que la date calculée est dans la plage valide
                if calculatedDate >= maximumDate && calculatedDate <= minimumDate {
                    editedDateOfBirth = calculatedDate
                } else {
                    // Si la date calculée n'est pas valide, utiliser minimumDate
                    editedDateOfBirth = minimumDate
                }
            } else {
                editedDateOfBirth = minimumDate
            }
        } else {
            // Pas de date de naissance, utiliser une date par défaut
            var components = DateComponents()
            components.year = currentYear - 25
            components.month = 1
            components.day = 1
            if let defaultDate = calendar.date(from: components) {
                if defaultDate >= maximumDate && defaultDate <= minimumDate {
                    editedDateOfBirth = defaultDate
                } else {
                    editedDateOfBirth = minimumDate
                }
            } else {
                editedDateOfBirth = minimumDate
            }
        }
        
        // S'assurer que editedGender est valide
        editedGender = profile.gender
        
        // Activer le mode édition de manière sécurisée avec animation
        withAnimation(.easeInOut(duration: 0.2)) {
            isEditing = true
        }
    }
    
    private func cancelEditing() {
        isEditing = false
        loadProfile()
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailPredicate.evaluate(with: email)
    }
    
    private func saveProfile() {
        let trimmedEmail = editedEmail.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if !trimmedEmail.isEmpty && !isValidEmail(trimmedEmail) {
            alertMessage = "L'adresse email n'est pas valide.".localized
            showingSaveAlert = true
            return
        }
        
        // Vérifier si des modifications ont été apportées
        let trimmedFirstName = editedFirstName.trimmingCharacters(in: .whitespaces)
        let hasFirstNameChanged = trimmedFirstName != profile.firstName
        let hasEmailChanged = trimmedEmail != (profile.email ?? "")
        
        // Comparaison de date : normaliser les dates pour comparer uniquement jour/mois/année
        let calendar = Calendar.current
        let hasDateChanged: Bool
        if let profileDate = profile.dateOfBirth {
            let editedComponents = calendar.dateComponents([.year, .month, .day], from: editedDateOfBirth)
            let profileComponents = calendar.dateComponents([.year, .month, .day], from: profileDate)
            hasDateChanged = editedComponents != profileComponents
        } else {
            // Si le profil n'avait pas de date, considérer qu'il y a un changement si la date n'est pas la date par défaut
            let defaultDate = calendar.date(byAdding: .year, value: -25, to: Date()) ?? editedDateOfBirth
            let editedComponents = calendar.dateComponents([.year, .month, .day], from: editedDateOfBirth)
            let defaultComponents = calendar.dateComponents([.year, .month, .day], from: defaultDate)
            hasDateChanged = editedComponents != defaultComponents
        }
        
        let hasGenderChanged = editedGender != profile.gender
        let hasPhotoChanged = selectedImage != nil // Si une nouvelle photo a été sélectionnée
        
        let hasChanges = hasFirstNameChanged || hasEmailChanged || hasDateChanged || hasGenderChanged || hasPhotoChanged
        
        // Si aucune modification, simplement fermer le mode édition
        if !hasChanges {
            isEditing = false
            return
        }
        
        let wasGenderUndefined = profile.gender == .notSpecified
        let isNowDefined = editedGender != .notSpecified
        
        profile.firstName = trimmedFirstName
        profile.email = trimmedEmail.isEmpty ? nil : trimmedEmail
        profile.dateOfBirth = editedDateOfBirth
        profile.gender = editedGender
        
        dataManager.saveUserProfile(profile)
        
        isEditing = false
        alertMessage = "Profil mis à jour avec succès.".localized
        showingSaveAlert = true
        
        if wasGenderUndefined && isNowDefined && !UserDefaults.hasCompletedTutorial() {
            showingTutorial = true
        }
    }
}

// MARK: - Composants ProfileScreen

struct ProfileHeaderSection: View {
    let photo: UIImage?
    let firstName: String
    let isEditing: Bool
    let onPhotoTap: () -> Void
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Photo de profil
            Button(action: onPhotoTap) {
                ZStack {
                    if let photo = photo {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 120, height: 120)
                            .clipShape(Circle())
                    } else {
                        Circle()
                            .fill(AppColors.buttonSecondary)
                            .frame(width: 120, height: 120)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 52, weight: .light))
                                    .foregroundColor(AppColors.primaryText)
                            }
                    }
                    
                    Circle()
                        .stroke(AppColors.cardBorder, lineWidth: 2)
                        .frame(width: 120, height: 120)
                    
                    if isEditing {
                        VStack {
                            Spacer()
                            HStack {
                                Spacer()
                                ZStack {
                                    Circle()
                                        .fill(AppColors.buttonPrimary)
                                        .frame(width: 36, height: 36)
                                    
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(AppColors.buttonPrimaryText)
                                }
                                .offset(x: -4, y: -4)
                            }
                        }
                        .frame(width: 120, height: 120)
                    }
                }
            }
            .disabled(!isEditing)
            
            // Nom de l'utilisateur
            if !firstName.isEmpty {
                Text(firstName)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(AppColors.primaryText)
            }
        }
    }
}

struct EditProfileSection: View {
    @Binding var firstName: String
    @Binding var email: String
    @Binding var dateOfBirth: Date
    @Binding var gender: Gender
    let minimumDate: Date
    let maximumDate: Date
    @FocusState private var isEmailFocused: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProfileFormField(label: "Prénom".localized, text: $firstName, isFocused: nil)
            ProfileFormField(label: "Email".localized, text: $email, keyboardType: .emailAddress, isFocused: $isEmailFocused)
            ProfileDateField(label: "Date de naissance".localized, date: $dateOfBirth, minimumDate: maximumDate, maximumDate: minimumDate)
            ProfileGenderField(label: "Genre".localized, gender: $gender)
        }
    }
}

struct DisplayProfileSection: View {
    let profile: UserProfile
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ProfileInfoCard(
                icon: "person.fill",
                label: "Prénom".localized,
                value: profile.firstName.isEmpty ? "Non renseigné".localized : profile.firstName
            )
            ProfileInfoCard(
                icon: "envelope.fill",
                label: "Email".localized,
                value: profile.email ?? "Non renseigné".localized
            )
            ProfileInfoCard(
                icon: "calendar",
                label: "Âge".localized,
                value: "\(profile.age) ans"
            )
            ProfileInfoCard(
                icon: "person.text.rectangle.fill",
                label: "Genre".localized,
                value: profile.gender.rawValue
            )
        }
    }
}

struct ProfileFormField: View {
    let label: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default
    var isFocused: FocusState<Bool>.Binding?
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(label)
                .font(DesignSystem.Typography.footnote())
                .foregroundColor(AppColors.secondaryText)
                .padding(.horizontal, DesignSystem.Spacing.xs)
            
            Group {
                if let isFocused = isFocused {
                    TextField("", text: $text, prompt: Text("Entrez votre \(label.lowercased())").foregroundColor(AppColors.secondaryText))
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(AppColors.primaryText)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused(isFocused)
                } else {
                    TextField("", text: $text, prompt: Text("Entrez votre \(label.lowercased())").foregroundColor(AppColors.secondaryText))
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(AppColors.primaryText)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(AppColors.cardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                    .stroke(AppColors.cardBorder, lineWidth: 1.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
        }
    }
}

struct ProfileDateField: View {
    let label: String
    @Binding var date: Date
    let minimumDate: Date
    let maximumDate: Date
    
    // Variable locale pour stocker la date validée
    @State private var validatedDate: Date
    
    init(label: String, date: Binding<Date>, minimumDate: Date, maximumDate: Date) {
        self.label = label
        self._date = date
        self.minimumDate = minimumDate
        self.maximumDate = maximumDate
        
        // Initialiser validatedDate avec la date clampée
        // minimumDate est la date la plus ancienne, maximumDate est la date la plus récente
        let initialDate = date.wrappedValue
        let clamped: Date
        if initialDate < minimumDate {
            clamped = minimumDate
        } else if initialDate > maximumDate {
            clamped = maximumDate
        } else {
            clamped = initialDate
        }
        _validatedDate = State(initialValue: clamped)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
            Text(label)
                .font(DesignSystem.Typography.footnote())
                .foregroundColor(AppColors.secondaryText)
                .padding(.horizontal, DesignSystem.Spacing.xs)
            
            HStack {
                DatePicker("", selection: Binding(
                    get: { validatedDate },
                    set: { newDate in
                        // Clamper la date dans la plage valide
                        // minimumDate est la date la plus ancienne, maximumDate est la date la plus récente
                        let clamped: Date
                        if newDate < minimumDate {
                            clamped = minimumDate
                        } else if newDate > maximumDate {
                            clamped = maximumDate
                        } else {
                            clamped = newDate
                        }
                        validatedDate = clamped
                        date = clamped
                    }
                ), in: minimumDate...maximumDate, displayedComponents: .date)
                    .datePickerStyle(.compact)
                    .labelsHidden()
                
                Spacer()
            }
            .padding(DesignSystem.Spacing.md)
            .background(AppColors.cardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                    .stroke(AppColors.cardBorder, lineWidth: 1.5)
            }
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
                .onChange(of: date) { oldValue, newValue in
                    // Synchroniser validatedDate avec date si elle change de l'extérieur
                    // minimumDate est la date la plus ancienne, maximumDate est la date la plus récente
                    let clamped: Date
                    if newValue < minimumDate {
                        clamped = minimumDate
                    } else if newValue > maximumDate {
                        clamped = maximumDate
                    } else {
                        clamped = newValue
                    }
                    if validatedDate != clamped {
                        validatedDate = clamped
                    }
                }
        }
    }
}

struct ProfileGenderField: View {
    let label: String
    @Binding var gender: Gender
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            Text(label)
                .font(DesignSystem.Typography.footnote())
                .foregroundColor(AppColors.secondaryText)
                .padding(.horizontal, DesignSystem.Spacing.xs)
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(Gender.allCases, id: \.self) { genderOption in
                    GenderOptionButton(
                        gender: genderOption,
                        isSelected: gender == genderOption,
                        action: {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                gender = genderOption
                            }
                        }
                    )
                }
            }
        }
    }
}

private struct GenderOptionButton: View {
    let gender: Gender
    let isSelected: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    private var genderIcon: String {
        switch gender {
        case .male:
            return "person.fill"
        case .female:
            return "person.fill"
        case .notSpecified:
            return "person.crop.circle"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: DesignSystem.Spacing.xs) {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppColors.buttonPrimary.opacity(0.2) : AppColors.buttonSecondary)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: genderIcon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? AppColors.buttonPrimary : AppColors.secondaryText)
                }
                
                Text(gender.rawValue)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(isSelected ? AppColors.buttonPrimary : AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.md)
            .padding(.horizontal, DesignSystem.Spacing.sm)
            .background(isSelected ? AppColors.buttonPrimary.opacity(0.1) : AppColors.buttonSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .stroke(isSelected ? AppColors.buttonPrimary : AppColors.cardBorder, lineWidth: isSelected ? 2 : 1.5)
            )
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct ProfileInfoCard: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        Card {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Icône
                ZStack {
                    Circle()
                        .fill(AppColors.buttonSecondary)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.primaryText)
                }
                
                // Label et valeur
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(label)
                        .font(DesignSystem.Typography.footnote())
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text(value)
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(AppColors.primaryText)
                }
                
                Spacer()
            }
        }
    }
}
