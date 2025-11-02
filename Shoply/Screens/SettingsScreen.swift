//
//  SettingsScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import AuthenticationServices
import SafariServices
import UIKit

/// Écran de paramètres complet
struct SettingsScreen: View {
    @StateObject private var openAIService = OpenAIService.shared
    @StateObject private var geminiService = GeminiService.shared
    @StateObject private var openAIOAuth = OpenAIOAuthService.shared
    @StateObject private var geminiOAuth = GeminiOAuthService.shared
    @StateObject private var settingsManager = AppSettingsManager.shared
    // CloudKitService sera accédé uniquement quand nécessaire, pas au démarrage
    // Utilisation lazy pour éviter l'initialisation au chargement de l'écran
    @State private var cloudKitService: CloudKitService? = nil
    
    private func getCloudKitService() -> CloudKitService {
        if cloudKitService == nil {
            cloudKitService = CloudKitService.shared
            // Vérifier le statut iCloud uniquement quand on accède au service (de manière sécurisée)
            // Utiliser un délai pour éviter les crashes au chargement
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak cloudKitService] in
                guard let service = cloudKitService else { return }
                service.checkAccountStatus()
            }
        }
        return cloudKitService!
    }
    
    // Version sécurisée qui retourne false si le service n'est pas initialisé
    private func isCloudKitSignedIn() -> Bool {
        guard let service = cloudKitService else { return false }
        return service.isSignedIn
    }
    @EnvironmentObject private var dataManager: DataManager
    
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingWebView = false
    @State private var showingDeleteConfirmation = false
    @State private var showingExportSheet = false
    @State private var showingAbout = false
    @State private var showingLanguagePicker = false
    @State private var showingGeminiKeyInput = false
    @State private var geminiAPIKey = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // En-tête
                        VStack(spacing: 8) {
                            Text(LocalizedString.localized("Paramètres", for: settingsManager.selectedLanguage))
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(AppColors.primaryText)
                        }
                        .padding(.top, 20)
                        
                        // Section Apparence
                        SettingsSection(title: "Apparence".localized) {
                            // Mode sombre
                            SettingRow(
                                icon: "moon.fill",
                                title: "Mode sombre".localized,
                                subtitle: getColorSchemeDescription().localized
                            ) {
                                ColorSchemePickerView(
                                    selectedScheme: Binding(
                                        get: { settingsManager.colorScheme },
                                        set: { settingsManager.setColorScheme($0) }
                                    )
                                )
                            }
                            
                            Divider()
                                .background(AppColors.separator)
                                .padding(.vertical, 8)
                            
                            // Langue
                            SettingRow(
                                icon: "globe",
                                title: "Langue".localized,
                                subtitle: settingsManager.selectedLanguage.displayName + " " + settingsManager.selectedLanguage.flag
                            ) {
                                Button(action: {
                                    showingLanguagePicker = true
                                }) {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                }
                            }
                        }
                        
                        // Section IA
                        SettingsSection(title: "Intelligence Artificielle".localized) {
                            // Sélecteur de fournisseur IA
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Fournisseur IA".localized)
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(AppColors.primaryText)
                                
                                Picker("Fournisseur IA".localized, selection: Binding(
                                    get: { settingsManager.aiProvider },
                                    set: { settingsManager.setAIProvider($0) }
                                )) {
                                    ForEach(AppSettingsManager.AIProvider.allCases, id: \.self) { provider in
                                        Text(provider.displayName).tag(provider)
                                    }
                                }
                                .pickerStyle(.segmented)
                                .tint(AppColors.buttonPrimary)
                            }
                            .padding()
                            .background(AppColors.buttonSecondary)
                            .roundedCorner(20)
                            
                            Divider()
                                .background(AppColors.separator)
                                .padding(.vertical, 8)
                            
                            // Statut de connexion
                            if (settingsManager.aiProvider == .chatGPT && (openAIService.isEnabled || openAIOAuth.isAuthenticated)) ||
                               (settingsManager.aiProvider == .gemini && (geminiService.isEnabled || geminiOAuth.isAuthenticated)) {
                                SettingRow(
                                    icon: "checkmark.circle.fill",
                                    title: settingsManager.aiProvider == .chatGPT ? "Connecté à ChatGPT".localized : "Connecté à Gemini".localized,
                                    subtitle: getConnectionStatusSubtitle(),
                                    iconColor: .green
                                ) {
                                    Button("Déconnecter".localized) {
                                        if settingsManager.aiProvider == .chatGPT {
                                            openAIOAuth.signOut()
                                        } else {
                                            geminiOAuth.signOut()
                                        }
                                        alertMessage = "Déconnexion réussie.".localized
                                        showingAlert = true
                                    }
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red)
                                }
                                
                                Divider()
                                    .background(AppColors.separator)
                                    .padding(.vertical, 8)
                            } else {
                                // Options de connexion (OAuth ou clé API)
                                VStack(spacing: 12) {
                                    // Bouton OAuth (recommandé)
                                    Button(action: {
                                        if settingsManager.aiProvider == .chatGPT {
                                            authenticateOpenAI()
                                        } else {
                                            authenticateGemini()
                                        }
                                    }) {
                                        HStack {
                                            Image(systemName: "person.circle.fill")
                                                .foregroundColor(AppColors.buttonPrimary)
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(settingsManager.aiProvider == .chatGPT ? "Se connecter avec OpenAI".localized : "Se connecter avec Google".localized)
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(AppColors.primaryText)
                                                Text(settingsManager.aiProvider == .chatGPT ? "Utiliser votre compte OpenAI (avec quota)".localized : "Utiliser votre compte Google (avec quota)".localized)
                                                    .font(.system(size: 12))
                                                    .foregroundColor(AppColors.secondaryText)
                                            }
                                            Spacer()
                                            Image(systemName: "arrow.right.circle.fill")
                                                .foregroundColor(AppColors.buttonPrimary)
                                        }
                                        .padding()
                                        .background(AppColors.buttonSecondary)
                                        .roundedCorner(16)
                                    }
                                    
                                    // Divider avec "OU"
                                }
                                .padding(.vertical, 8)
                                
                                Divider()
                                    .background(AppColors.separator)
                                    .padding(.vertical, 8)
                            }
                            
                            // Instructions selon le fournisseur
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Comment ça marche ?".localized)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.primaryText)
                                
                                if settingsManager.aiProvider == .chatGPT {
                                    VStack(alignment: .leading, spacing: 10) {
                                        InstructionStep(number: 1, text: LocalizedString.localized("Cliquez sur \"Se connecter avec OpenAI\"", for: settingsManager.selectedLanguage))
                                        InstructionStep(number: 2, text: LocalizedString.localized("Connectez-vous avec votre compte OpenAI/ChatGPT", for: settingsManager.selectedLanguage))
                                        InstructionStep(number: 3, text: LocalizedString.localized("Autorisez l'application à accéder à votre compte", for: settingsManager.selectedLanguage))
                                        InstructionStep(number: 4, text: LocalizedString.localized("Vous pourrez utiliser votre quota directement", for: settingsManager.selectedLanguage))
                                    }
                                } else {
                                    VStack(alignment: .leading, spacing: 10) {
                                        InstructionStep(number: 1, text: LocalizedString.localized("Cliquez sur \"Se connecter avec Google\"", for: settingsManager.selectedLanguage))
                                        InstructionStep(number: 2, text: LocalizedString.localized("Connectez-vous avec votre compte Google", for: settingsManager.selectedLanguage))
                                        InstructionStep(number: 3, text: LocalizedString.localized("Autorisez l'application à utiliser Gemini", for: settingsManager.selectedLanguage))
                                        InstructionStep(number: 4, text: LocalizedString.localized("Vous pourrez utiliser Gemini avec votre quota", for: settingsManager.selectedLanguage))
                                    }
                                }
                            }
                            .padding()
                            .background(AppColors.buttonSecondary)
                            .roundedCorner(20)
                            
                            Divider()
                                .background(AppColors.separator)
                                .padding(.vertical, 8)
                            
                            // Information
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(spacing: 8) {
                                    Image(systemName: "info.circle.fill")
                                        .foregroundColor(AppColors.buttonPrimary)
                                        .font(.system(size: 16))
                                    Text("Information".localized)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(AppColors.primaryText)
                                }
                                
                                Text(settingsManager.aiProvider == .chatGPT ? 
                                     LocalizedString.localized("Connectez-vous avec votre compte OpenAI pour utiliser automatiquement votre quota. Aucune clé API nécessaire !", for: settingsManager.selectedLanguage) :
                                     LocalizedString.localized("Connectez-vous avec votre compte Google pour utiliser automatiquement votre quota Gemini. Aucune clé API nécessaire !", for: settingsManager.selectedLanguage))
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(AppColors.secondaryText)
                                    .lineSpacing(4)
                            }
                            .padding()
                            .background(AppColors.buttonSecondary)
                            .roundedCorner(20)
                        }
                        
                        // Section Données
                        SettingsSection(title: "Données utilisateur".localized) {
                            SettingRow(
                                icon: "square.and.arrow.up",
                                title: "Exporter mes données".localized,
                                subtitle: "Télécharger toutes vos données au format JSON".localized
                            ) {
                                Button(action: {
                                    exportUserData()
                                }) {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                }
                            }
                            
                            Divider()
                                .background(AppColors.separator)
                                .padding(.vertical, 8)
                            
                            SettingRow(
                                icon: "trash.fill",
                                title: "Supprimer toutes mes données".localized,
                                subtitle: "Cette action est irréversible".localized,
                                iconColor: .red
                            ) {
                                Button(action: {
                                    showingDeleteConfirmation = true
                                }) {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                }
                            }
                        }
                        
                        // Section Synchronisation iCloud
                        SettingsSection(title: "Synchronisation iCloud".localized) {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "icloud.fill")
                                        .foregroundColor(AppColors.buttonPrimary)
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Sauvegarde iCloud".localized)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(AppColors.primaryText)
                                        Text(isCloudKitSignedIn() ? 
                                            "Vos données sont synchronisées avec iCloud".localized :
                                            "Connectez-vous à iCloud pour sauvegarder vos données".localized)
                                            .font(.system(size: 12))
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                    Spacer()
                                    if isCloudKitSignedIn() {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                    }
                                }
                                .padding()
                                .background(AppColors.buttonSecondary)
                                .roundedCorner(16)
                                
                                if isCloudKitSignedIn() {
                                    Button(action: {
                                        syncToiCloud()
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.clockwise.circle.fill")
                                            Text("Synchroniser maintenant".localized)
                                        }
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.buttonPrimaryText)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(AppColors.buttonPrimary)
                                        .roundedCorner(16)
                                    }
                                    
                                    Button(action: {
                                        restoreFromiCloud()
                                    }) {
                                        HStack {
                                            Image(systemName: "arrow.down.circle.fill")
                                            Text("Récupérer depuis iCloud".localized)
                                        }
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(AppColors.buttonPrimary)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(AppColors.buttonSecondary)
                                        .roundedCorner(16)
                                    }
                                } else {
                                    Text("Connectez-vous à iCloud dans Réglages → [Votre nom] → iCloud".localized)
                                        .font(.system(size: 12))
                                        .foregroundColor(AppColors.secondaryText)
                                        .multilineTextAlignment(.center)
                                        .padding(.horizontal)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                        
                        Divider()
                            .background(AppColors.separator)
                            .padding(.vertical, 8)
                        
                        // Section Informations
                        SettingsSection(title: "À propos".localized) {
                            SettingRow(
                                icon: "info.circle.fill",
                                title: "À propos de Shoply".localized,
                                subtitle: "\(getAppVersion())".localized
                            ) {
                                Button(action: {
                                    showingAbout = true
                                }) {
                                    HStack {
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                }
                            }
                        }
                        
                        .padding(.bottom, 40)
                    }
                    .id("settings-content-\(settingsManager.selectedLanguage)") // Force le rafraîchissement quand la langue change
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                openAIService.reloadAPIKey()
                geminiService.reloadAPIKey()
            }
            .sheet(isPresented: $showingGeminiKeyInput) {
                GeminiAPIKeyView(isPresented: $showingGeminiKeyInput, onSave: { key in
                    if !key.isEmpty {
                        geminiService.setAPIKey(key)
                        alertMessage = "Clé API enregistrée avec succès.".localized
                        showingAlert = true
                    }
                })
            }
            .alert("Configuration", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .alert("Suppression des données", isPresented: $showingDeleteConfirmation) {
                Button("Annuler", role: .cancel) { }
                Button("Supprimer", role: .destructive) {
                    deleteAllUserData()
                }
            } message: {
                Text("Êtes-vous sûr de vouloir supprimer toutes vos données ? Cette action est irréversible et supprimera votre profil, vos favoris, votre garde-robe et toutes vos préférences.")
            }
            .sheet(isPresented: $showingWebView) {
                NavigationStack {
                    ChatGPTConnectionWebView(onConnected: { key in
                        // Sauvegarder la clé API dans OpenAI Service
                        openAIService.setAPIKey(key)
                        alertMessage = "Clé API enregistrée avec succès.".localized
                        showingAlert = true
                        showingWebView = false
                    })
                }
            }
            .sheet(isPresented: $showingLanguagePicker) {
                LanguagePickerView(selectedLanguage: $settingsManager.selectedLanguage)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView()
            }
        }
    }
    
    // MARK: - Méthodes privées
    private func getColorSchemeDescription() -> String {
        switch settingsManager.colorScheme {
        case .light:
            return "Clair"
        case .dark:
            return "Sombre"
        case .none:
            return "Système"
        @unknown default:
            return "Système"
        }
    }
    
    private func getAppVersion() -> String {
        if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
           let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
            return "\(version) (\(build))"
        }
        return "1.0.0"
    }
    
    private func authenticateOpenAI() {
        Task {
            do {
                try await openAIOAuth.authenticate()
                alertMessage = "Connexion réussie ! Vous pouvez maintenant utiliser ChatGPT avec votre compte.".localized
                showingAlert = true
            } catch {
                alertMessage = "Erreur de connexion: \(error.localizedDescription)".localized
                showingAlert = true
            }
        }
    }
    
    private func authenticateGemini() {
        Task {
            do {
                try await geminiOAuth.authenticate()
                alertMessage = "Connexion réussie ! Vous pouvez maintenant utiliser Gemini avec votre compte Google.".localized
                showingAlert = true
            } catch {
                alertMessage = "Erreur de connexion: \(error.localizedDescription)".localized
                showingAlert = true
            }
        }
    }
    
    private func getConnectionStatusSubtitle() -> String {
        if settingsManager.aiProvider == .chatGPT {
            if openAIOAuth.isAuthenticated, let email = openAIOAuth.userEmail {
                return "Connecté avec votre compte: \(email)"
            }
            return "Non connecté"
        } else {
            if geminiOAuth.isAuthenticated, let email = geminiOAuth.userEmail {
                return "Connecté avec votre compte: \(email)"
            }
            return "Non connecté"
        }
    }
    
    private func syncToiCloud() {
        Task {
            do {
                try await getCloudKitService().syncAllUserData()
                alertMessage = "Synchronisation réussie !".localized
                showingAlert = true
            } catch {
                alertMessage = "Erreur de synchronisation: \(error.localizedDescription)".localized
                showingAlert = true
            }
        }
    }
    
    private func restoreFromiCloud() {
        Task {
            do {
                try await getCloudKitService().restoreAllData()
                alertMessage = "Données restaurées depuis iCloud !".localized
                showingAlert = true
            } catch {
                alertMessage = "Erreur de restauration: \(error.localizedDescription)".localized
                showingAlert = true
            }
        }
    }
    
    private func exportUserData() {
        let userData = dataManager.exportUserData()
        
        // Convertir en JSON
        if let jsonData = try? JSONSerialization.data(withJSONObject: userData, options: .prettyPrinted),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            // Créer un fichier temporaire
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("shoply_export_\(Date().timeIntervalSince1970).json")
            
            do {
                try jsonString.write(to: tempURL, atomically: true, encoding: .utf8)
                
                // Afficher dans une vue de partage
                let activityVC = UIActivityViewController(activityItems: [tempURL], applicationActivities: nil)
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    
                    // Pour iPad
                    if let popover = activityVC.popoverPresentationController {
                        popover.sourceView = window
                        popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                        popover.permittedArrowDirections = []
                    }
                    
                    rootVC.present(activityVC, animated: true)
                    alertMessage = "Utilisez le menu de partage pour sauvegarder ou partager vos données."
                    showingAlert = true
                } else {
                    alertMessage = "Erreur lors de l'affichage du menu de partage."
                    showingAlert = true
                }
            } catch {
                alertMessage = "Erreur lors de l'export de vos données: \(error.localizedDescription)"
                showingAlert = true
            }
        } else {
            alertMessage = "Erreur lors de la conversion de vos données en JSON."
            showingAlert = true
        }
    }
    
    private func deleteAllUserData() {
        dataManager.deleteAllUserData()
        alertMessage = "Toutes vos données ont été supprimées."
        showingAlert = true
    }
}

// MARK: - Composants réutilisables

struct SettingsSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppColors.primaryText)
            
            VStack(spacing: 0) {
                content
            }
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Material.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppColors.cardBorder.opacity(0.3),
                                        AppColors.cardBorder.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    )
                    .shadow(color: AppColors.shadow.opacity(0.2), radius: 12, x: 0, y: 4)
            )
        }
        .padding(.horizontal, 24)
    }
}

struct SettingRow<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    var iconColor: Color = AppColors.primaryText
    let accessory: Content
    
    init(icon: String, title: String, subtitle: String, iconColor: Color = AppColors.primaryText, @ViewBuilder accessory: () -> Content) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.accessory = accessory()
    }
    
    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(iconColor)
                .frame(width: 24, height: 24)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(AppColors.primaryText)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
            
            accessory
        }
        .padding(.vertical, 8)
    }
}

struct ColorSchemePickerView: View {
    @Binding var selectedScheme: ColorScheme?
    @StateObject private var settingsManager = AppSettingsManager.shared
    @State private var showingPicker = false
    
    var body: some View {
        Button(action: {
            showingPicker = true
        }) {
            HStack {
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.secondaryText)
            }
        }
        .confirmationDialog("Choisir le thème".localized, isPresented: $showingPicker, titleVisibility: .visible) {
            Button("Clair".localized) {
                selectedScheme = .light
            }
            
            Button("Sombre".localized) {
                selectedScheme = .dark
            }
            
            Button("Système".localized) {
                selectedScheme = nil
            }
            
            Button("Annuler".localized, role: .cancel) { }
        }
    }
}

struct LanguagePickerView: View {
    @Binding var selectedLanguage: AppLanguage
    @Environment(\.dismiss) private var dismiss
    @StateObject private var settingsManager = AppSettingsManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                List {
                    ForEach(AppLanguage.allCases) { language in
                        Button(action: {
                            selectedLanguage = language
                            settingsManager.setLanguage(language)
                            dismiss()
                        }) {
                            HStack {
                                Text(language.flag)
                                    .font(.system(size: 24))
                                Text(language.displayName)
                                    .foregroundColor(AppColors.primaryText)
                                Spacer()
                                if selectedLanguage == language {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(AppColors.buttonPrimary)
                                        .fontWeight(.semibold)
                                }
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Sélectionner la langue".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
        }
    }
}

struct AboutView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        VStack(spacing: 16) {
                            Text("Shoply")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(AppColors.primaryText)
                            
                            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
                                Text("Version \(version)")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(AppColors.secondaryText)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Description")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppColors.primaryText)
                            
                            Text("Shoply est votre assistant personnel pour créer des tenues parfaites selon votre humeur, la météo et votre style. L'application utilise l'intelligence artificielle pour vous proposer des combinaisons d'outfits adaptées à vos préférences.")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(AppColors.secondaryText)
                                .lineSpacing(4)
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Fonctionnalités")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppColors.primaryText)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                FeatureRow(icon: "photo.fill", text: "Gestion de votre garde-robe")
                                FeatureRow(icon: "sparkles", text: "Suggestions intelligentes d'outfits")
                                FeatureRow(icon: "cloud.sun.fill", text: "Intégration météo")
                                FeatureRow(icon: "heart.fill", text: "Système de favoris")
                                FeatureRow(icon: "calendar", text: "Historique et calendrier")
                            }
                        }
                        
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Développement")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppColors.primaryText)
                            
                            Text("Développé avec SwiftUI pour iOS et macOS")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(AppColors.secondaryText)
                        }
                        
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationTitle("À propos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColors.primaryText)
                .frame(width: 24)
            Text(text)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(AppColors.secondaryText)
        }
    }
}

struct ExportDataView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack {
                    Text("Vue d'export des données")
                        .foregroundColor(AppColors.primaryText)
                }
            }
            .navigationTitle("Exporter les données")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Badge numéroté avec design amélioré
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.buttonPrimary.opacity(0.9),
                                AppColors.buttonPrimary.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                AppColors.buttonPrimaryText.opacity(0.2),
                                lineWidth: 1
                            )
                    )
                
                Text("\(number)")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColors.buttonPrimaryText)
            }
            .frame(width: 28, height: 28)
            
            // Texte de l'instruction
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(AppColors.primaryText)
                .fixedSize(horizontal: false, vertical: false)
            
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    SettingsScreen()
        .environmentObject(DataManager.shared)
}
