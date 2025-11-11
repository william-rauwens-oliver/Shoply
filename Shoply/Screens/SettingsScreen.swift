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
import UniformTypeIdentifiers
import ObjectiveC

/// Écran de paramètres complet
struct SettingsScreen: View {
    @StateObject private var geminiService = GeminiService.shared
    @StateObject private var settingsManager = AppSettingsManager.shared
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
    @State private var showingDocumentPicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond opaque et simple
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 32) {
                        // En-tête simple
                        VStack(spacing: 6) {
                            Text("Paramètres")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(AppColors.primaryText)
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 8)
                        
                        // Section Apparence
                        SettingsSection(title: "Apparence") {
                            // Mode sombre
                            ColorSchemeSettingRow(
                                icon: "moon.fill",
                                title: "Mode sombre",
                                subtitle: getColorSchemeDescription(),
                                    selectedScheme: Binding(
                                        get: { settingsManager.colorScheme },
                                        set: { settingsManager.setColorScheme($0) }
                                    )
                                )
                            
                            Divider()
                                .background(AppColors.separator)
                                .padding(.vertical, 8)
                            
                            // Langue
                            SettingRow(
                                icon: "globe",
                                title: "Langue",
                                subtitle: settingsManager.selectedLanguage.displayName + " " + settingsManager.selectedLanguage.flag,
                                action: {
                                    showingLanguagePicker = true
                                }
                            ) {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(AppColors.secondaryText)
                            }
                        }
                        
                        // Section IA
                        SettingsSection(title: "Intelligence Artificielle") {
                            // Statut Shoply AI
                            SettingRow(
                                icon: "checkmark.circle.fill",
                                title: "Shoply AI",
                                subtitle: "Activé et prêt",
                                iconColor: .green
                            ) {
                                EmptyView()
                            }
                            
                            Divider()
                                .background(AppColors.separator)
                                .padding(.vertical, 8)
                            
                            // Information
                            HStack(spacing: 10) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 16))
                                    .foregroundColor(AppColors.buttonPrimary.opacity(0.8))
                                
                                Text("Shoply AI est disponible pour créer vos tenues")
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(AppColors.secondaryText)
                                    .lineSpacing(2)
                            }
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.buttonSecondary)
                            .roundedCorner(16)
                        }
                        
                        // Section Données
                        SettingsSection(title: "Mes données") {
                            SettingRow(
                                icon: "square.and.arrow.up",
                                title: "Exporter",
                                subtitle: "Télécharger toutes vos données",
                                action: {
                                    exportUserData()
                                }
                            ) {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(AppColors.secondaryText)
                            }
                            
                            Divider()
                                .background(AppColors.separator)
                                .padding(.vertical, 8)
                            
                            SettingRow(
                                icon: "square.and.arrow.down",
                                title: "Importer",
                                subtitle: "Restaurer vos données",
                                action: {
                                    importUserData()
                                }
                            ) {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(AppColors.secondaryText)
                            }
                            
                            Divider()
                                .background(AppColors.separator)
                                .padding(.vertical, 8)
                            
                            SettingRow(
                                icon: "trash.fill",
                                title: "Supprimer tout",
                                subtitle: "Action irréversible",
                                iconColor: .red,
                                action: {
                                    showingDeleteConfirmation = true
                                }
                            ) {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(AppColors.secondaryText)
                            }
                        }
                        
                        
                        // Section Informations
                        SettingsSection(title: "À propos") {
                            SettingRow(
                                icon: "info.circle.fill",
                                title: "Shoply",
                                subtitle: "Version \(getAppVersion())",
                                action: {
                                    showingAbout = true
                                }
                            ) {
                                        Image(systemName: "chevron.right")
                                            .foregroundColor(AppColors.secondaryText)
                            }
                        }
                        
                        .padding(.bottom, 40)
                    }
                    .id("settings-content-\(settingsManager.selectedLanguage)") // Force le rafraîchissement quand la langue change
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
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
            .sheet(isPresented: $showingLanguagePicker) {
                LanguagePickerView(selectedLanguage: $settingsManager.selectedLanguage)
            }
            .sheet(isPresented: $showingAbout) {
                AboutView()
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportDataView()
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker(
                    allowedContentTypes: [UTType.json],
                    onDocumentPicked: { url in
                        importUserDataFromFile(url: url)
                    }
                )
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButtonWithLongPress()
                }
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
    
    
    private func importUserData() {
        showingDocumentPicker = true
    }
    
    private func importUserDataFromFile(url: URL) {
            do {
            let jsonData = try Data(contentsOf: url)
            try dataManager.importUserData(from: jsonData)
            alertMessage = "Données importées avec succès !".localized
                showingAlert = true
            } catch {
            alertMessage = "Erreur lors de l'import: \(error.localizedDescription)".localized
                showingAlert = true
        }
    }
    
    private func exportUserData() {
        let userData = dataManager.exportUserData()
        
        // Convertir en JSON
        guard let jsonData = try? JSONSerialization.data(withJSONObject: userData, options: .prettyPrinted) else {
            alertMessage = "Erreur lors de la conversion de vos données en JSON."
            showingAlert = true
            return
        }
        
        // Créer un nom de fichier avec date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let fileName = "shoply_export_\(formatter.string(from: Date())).json"
        
            // Créer un fichier temporaire
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        do {
            try jsonData.write(to: tempURL)
            
            // Utiliser UIDocumentPickerViewController pour sauvegarder dans Fichiers
            let documentPicker = UIDocumentPickerViewController(forExporting: [tempURL], asCopy: true)
            let delegate = ExportDocumentPickerDelegate(
                tempURL: tempURL,
                onComplete: { success in
                    if success {
                        alertMessage = "Données exportées avec succès ! Vous pouvez maintenant sauvegarder le fichier dans l'app Fichiers."
                    } else {
                        alertMessage = "Export annulé."
                    }
                    showingAlert = true
                }
            )
            // Garder une référence forte au delegate pour éviter la désallocation
            objc_setAssociatedObject(documentPicker, AssociatedKeys.delegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            documentPicker.delegate = delegate
                
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let window = windowScene.windows.first,
                   let rootVC = window.rootViewController {
                    
                    // Pour iPad
                if let popover = documentPicker.popoverPresentationController {
                        popover.sourceView = window
                        popover.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
                        popover.permittedArrowDirections = []
                    }
                    
                rootVC.present(documentPicker, animated: true)
                } else {
                alertMessage = "Erreur lors de l'affichage du sélecteur de fichiers."
                    showingAlert = true
                }
            } catch {
                alertMessage = "Erreur lors de l'export de vos données: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func deleteAllUserData() {
        // Supprimer toutes les données utilisateur
        dataManager.deleteAllUserData()
        
        // Déconnecter Apple Sign In
        AppleSignInService.shared.signOut()
        
        // Réinitialiser TOUS les flags pour revenir à l'état initial
        UserDefaults.standard.removeObject(forKey: "hasSeenAppleSignInScreen")
        UserDefaults.standard.removeObject(forKey: "hasCompletedTutorial")
        UserDefaults.standard.removeObject(forKey: "tutorial_completed")
        UserDefaults.standard.removeObject(forKey: "onboardingCompleted")
        
        // Réinitialiser le profil utilisateur
        UserDefaults.standard.removeObject(forKey: "userProfile")
        
        // NE PAS réinitialiser RGPD - on garde le consentement
        // L'app reviendra à l'écran de bienvenue (OnboardingScreen)
        
        // Forcer la synchronisation
        UserDefaults.standard.synchronize()
        
        // Forcer la mise à jour de l'état du DataManager
        DispatchQueue.main.async {
            // Vérifier à nouveau l'état de l'onboarding
            _ = dataManager.hasCompletedOnboarding()
        }
        
        alertMessage = "Toutes vos données ont été supprimées. L'application va redémarrer sur l'écran de bienvenue.".localized
        showingAlert = true
        
        // Fermer l'écran des paramètres après un court délai pour permettre à l'app de redémarrer
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            // L'app détectera automatiquement que l'onboarding n'est plus complété
            // et affichera l'écran de bienvenue
        }
        
        // L'app va automatiquement revenir à l'écran Apple Sign In car isAuthenticated est maintenant false
        // Grâce à la logique conditionnelle dans ShoplyApp.swift
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
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(AppColors.primaryText)
                .padding(.horizontal, 4)
            
            VStack(spacing: 0) {
                content
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppColors.cardBackground)
            .overlay {
                RoundedRectangle(cornerRadius: 20)
                    .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 0.5)
            }
            .roundedCorner(20)
            .shadow(color: AppColors.shadow.opacity(0.08), radius: 12, x: 0, y: 4)
        }
        .padding(.horizontal, 20)
    }
}

struct SettingRow<Content: View>: View {
    let icon: String
    let title: String
    let subtitle: String
    var iconColor: Color = AppColors.primaryText
    let accessory: Content
    var action: (() -> Void)? = nil
    
    init(icon: String, title: String, subtitle: String, iconColor: Color = AppColors.primaryText, action: (() -> Void)? = nil, @ViewBuilder accessory: () -> Content) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.action = action
        self.accessory = accessory()
    }
    
    var body: some View {
        Button(action: {
            action?()
        }) {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .regular))
                .foregroundColor(iconColor)
                .frame(width: 28, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                
                Text(subtitle)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
            
            accessory
        }
        .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ColorSchemeSettingRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var selectedScheme: ColorScheme?
    @State private var showingPicker = false
    
    var body: some View {
        Button(action: {
            showingPicker = true
        }) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .regular))
                    .foregroundColor(AppColors.primaryText)
                    .frame(width: 28, height: 28)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(subtitle)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(AppColors.secondaryText)
            }
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .confirmationDialog("Choisir le thème", isPresented: $showingPicker, titleVisibility: .visible) {
            Button("Clair") {
                selectedScheme = .light
            }
            
            Button("Sombre") {
                selectedScheme = .dark
            }
            
            Button("Système") {
                selectedScheme = nil
            }
            
            Button("Annuler", role: .cancel) { }
        }
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
            Image(systemName: "chevron.right")
                .foregroundColor(AppColors.secondaryText)
        }
            .confirmationDialog("Choisir le thème", isPresented: $showingPicker, titleVisibility: .visible) {
            Button("Clair") {
                selectedScheme = .light
            }
            
            Button("Sombre") {
                selectedScheme = .dark
            }
            
            Button("Système") {
                selectedScheme = nil
            }
            
            Button("Annuler", role: .cancel) { }
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
            .navigationTitle("Langue")
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
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // En-tête avec logo
                        VStack(spacing: 20) {
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
                                
                                Image(systemName: "sparkles")
                                    .font(.system(size: 56, weight: .light))
                                    .foregroundColor(AppColors.buttonPrimary)
                            }
                            
                            VStack(spacing: 8) {
                                Text("Shoply")
                                    .font(DesignSystem.Typography.largeTitle())
                                    .foregroundColor(AppColors.primaryText)
                                
                                if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                                   let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                                    Text("Version \(version) (\(build))")
                                        .font(DesignSystem.Typography.caption())
                                        .foregroundColor(AppColors.secondaryText)
                                }
                            }
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 8)
                        
                        // Description
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Description".localized)
                                    .font(DesignSystem.Typography.title2())
                                    .foregroundColor(AppColors.primaryText)
                                
                                Text("Shoply est votre assistant personnel intelligent pour gérer votre garde-robe et créer des tenues parfaites. L'application vous permet de gérer vos vêtements, créer des collections, planifier vos outfits, suivre votre historique, et bénéficier de suggestions intelligentes adaptées à la météo, aux occasions et à votre style personnel grâce à Shoply AI.\n\nShoply AI - Créé uniquement par William RAUWENS OLIVER. Aucune équipe n'a créé cette application, elle a été entièrement développée par une seule personne.".localized)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.secondaryText)
                                    .lineSpacing(6)
                            }
                            .padding(24)
                        }
                        .padding(.horizontal, 20)
                        
                        // Fonctionnalités
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 20) {
                                Text("Fonctionnalités principales".localized)
                                    .font(DesignSystem.Typography.title2())
                                    .foregroundColor(AppColors.primaryText)
                                
                                VStack(spacing: 16) {
                                    FeatureRow(icon: "tshirt.fill", text: "Gestion complète de votre garde-robe".localized)
                                    FeatureRow(icon: "sparkles", text: "Sélection intelligente d'outfits avec Shoply AI".localized)
                                    FeatureRow(icon: "folder.fill", text: "Collections personnalisées".localized)
                                    FeatureRow(icon: "heart.fill", text: "Wishlist et favoris".localized)
                                    FeatureRow(icon: "airplane", text: "Mode Voyage avec checklist Shoply AI".localized)
                                    FeatureRow(icon: "briefcase.fill", text: "Suggestions pour occasions professionnelles et romantiques".localized)
                                    FeatureRow(icon: "calendar", text: "Calendrier et historique des outfits".localized)
                                    FeatureRow(icon: "message.fill", text: "Chat avec Shoply AI".localized)
                                    FeatureRow(icon: "star.fill", text: "Gamification avec badges et niveaux".localized)
                                    FeatureRow(icon: "barcode.viewfinder", text: "Scanner de codes-barres".localized)
                                    FeatureRow(icon: "chart.line.uptrend.xyaxis", text: "Analyse de tendances mode".localized)
                                }
                            }
                            .padding(24)
                        }
                        .padding(.horizontal, 20)
                        
                        // Développement
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Développement".localized)
                                    .font(DesignSystem.Typography.title2())
                                    .foregroundColor(AppColors.primaryText)
                                
                                Text("Développé avec SwiftUI pour iOS et iPadOS par William RAUWENS OLIVER, utilisant Shoply AI, une intelligence artificielle avancée, pour offrir une expérience utilisateur exceptionnelle.\n\nCette application a été créée entièrement par une seule personne, sans équipe. Tous les aspects du développement, du design à l'implémentation, ont été réalisés par William RAUWENS OLIVER.".localized)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.secondaryText)
                                    .lineSpacing(6)
                            }
                            .padding(24)
                        }
                        .padding(.horizontal, 20)
                        
                        // Contact
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Contact".localized)
                                    .font(DesignSystem.Typography.title2())
                                    .foregroundColor(AppColors.primaryText)
                                
                                Button {
                                    if let url = URL(string: "https://urlr.me/5M3nYj") {
                                        UIApplication.shared.open(url)
                                    }
                                } label: {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(AppColors.buttonPrimary.opacity(0.15))
                                                .frame(width: 44, height: 44)
                                            
                                            Image(systemName: "link.circle.fill")
                                                .font(.system(size: 22, weight: .semibold))
                                                .foregroundColor(AppColors.buttonPrimary)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Me contacter sur LinkedIn".localized)
                                                .font(DesignSystem.Typography.headline())
                                                .foregroundColor(AppColors.primaryText)
                                            
                                            Text("William RAUWENS OLIVER".localized)
                                                .font(DesignSystem.Typography.caption())
                                                .foregroundColor(AppColors.secondaryText)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                    .padding(16)
                                    .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(24)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("À propos".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("À propos".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.primaryText)
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
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.buttonPrimary.opacity(0.12))
                    .frame(width: 40, height: 40)
                
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.buttonPrimary)
            }
            
            Text(text)
                .font(DesignSystem.Typography.body())
                .foregroundColor(AppColors.primaryText)
            
            Spacer()
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

// MARK: - Export Document Picker Delegate
class ExportDocumentPickerDelegate: NSObject, UIDocumentPickerDelegate {
    let tempURL: URL
    let onComplete: (Bool) -> Void
    
    init(tempURL: URL, onComplete: @escaping (Bool) -> Void) {
        self.tempURL = tempURL
        self.onComplete = onComplete
        super.init()
    }
    
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        // L'export est terminé avec succès
        // Le fichier temporaire sera automatiquement copié à l'emplacement choisi par l'utilisateur
        onComplete(true)
        
        // Nettoyer le fichier temporaire après un court délai
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            try? FileManager.default.removeItem(at: self.tempURL)
        }
    }
    
    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        onComplete(false)
        
        // Nettoyer le fichier temporaire
        try? FileManager.default.removeItem(at: tempURL)
    }
}

// MARK: - Document Picker
struct DocumentPicker: UIViewControllerRepresentable {
    let allowedContentTypes: [UTType]
    let onDocumentPicked: (URL) -> Void
    
    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let picker = UIDocumentPickerViewController(forOpeningContentTypes: allowedContentTypes, asCopy: true)
        picker.delegate = context.coordinator
        picker.allowsMultipleSelection = false
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
        // Pas besoin de mise à jour
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onDocumentPicked: onDocumentPicked)
    }
    
    class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onDocumentPicked: (URL) -> Void
        
        init(onDocumentPicked: @escaping (URL) -> Void) {
            self.onDocumentPicked = onDocumentPicked
        }
        
        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            
            // Sécuriser l'accès au fichier
            let isAccessing = url.startAccessingSecurityScopedResource()
            defer {
                if isAccessing {
                    url.stopAccessingSecurityScopedResource()
                }
            }
            
            onDocumentPicked(url)
        }
        
        func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
            // L'utilisateur a annulé
        }
    }
}

// Clé pour garder une référence au delegate
private struct AssociatedKeys {
    static var delegateKey: UnsafeRawPointer = {
        return UnsafeRawPointer(bitPattern: "exportDelegate".hashValue)!
    }()
}

#Preview {
    SettingsScreen()
        .environmentObject(DataManager.shared)
}
