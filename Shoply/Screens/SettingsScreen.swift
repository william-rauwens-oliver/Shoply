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
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 28) {
                        // En-tête épuré
                        VStack(spacing: 4) {
                            Text(LocalizedString.localized("Paramètres", for: settingsManager.selectedLanguage))
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(AppColors.primaryText)
                        }
                        .padding(.top, 24)
                        .padding(.bottom, 8)
                        
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
                            // Statut Gemini
                            SettingRow(
                                icon: "checkmark.circle.fill",
                                title: "Gemini activé".localized,
                                subtitle: "Gemini est prêt à être utilisé".localized,
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
                                
                                Text("Gemini est intégré et prêt à être utilisé dans toute l'application.".localized)
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
                                icon: "square.and.arrow.down",
                                title: "Importer mes données".localized,
                                subtitle: "Restaurer vos données depuis un fichier JSON".localized
                            ) {
                                Button(action: {
                                    importUserData()
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
        // Supprimer toutes les données utilisateur
        dataManager.deleteAllUserData()
        
        // Déconnecter Apple Sign In
        AppleSignInService.shared.signOut()
        
        // Supprimer tous les autres flags et données SAUF RGPD
        UserDefaults.standard.removeObject(forKey: "hasSeenAppleSignInScreen")
        UserDefaults.standard.removeObject(forKey: "hasCompletedTutorial")
        
        // NE PAS réinitialiser RGPD - on garde le consentement
        // On retourne juste à Apple Sign In pour permettre une nouvelle connexion
        
        // Forcer la synchronisation
        UserDefaults.standard.synchronize()
        
        alertMessage = "Toutes vos données ont été supprimées. Vous allez être redirigé vers l'écran de connexion."
        showingAlert = true
        
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
    
    init(icon: String, title: String, subtitle: String, iconColor: Color = AppColors.primaryText, @ViewBuilder accessory: () -> Content) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.iconColor = iconColor
        self.accessory = accessory()
    }
    
    var body: some View {
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

#Preview {
    SettingsScreen()
        .environmentObject(DataManager.shared)
}
