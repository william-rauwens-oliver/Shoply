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
                            SettingRow(
                                icon: "moon.fill",
                                title: "Mode sombre",
                                subtitle: getColorSchemeDescription()
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
                                title: "Langue",
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
                        SettingsSection(title: "Intelligence Artificielle") {
                            // Statut Gemini
                            SettingRow(
                                icon: "checkmark.circle.fill",
                                title: "Gemini",
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
                                
                                Text("Gemini est disponible pour créer vos tenues")
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
                                subtitle: "Télécharger toutes vos données"
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
                                title: "Importer",
                                subtitle: "Restaurer vos données"
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
                                title: "Supprimer tout",
                                subtitle: "Action irréversible",
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
                        SettingsSection(title: "À propos") {
                            SettingRow(
                                icon: "info.circle.fill",
                                title: "Shoply",
                                subtitle: "Version \(getAppVersion())"
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
                    VStack(spacing: 32) {
                        // En-tête avec logo et version
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                AppColors.buttonPrimary.opacity(0.8),
                                                AppColors.buttonPrimary.opacity(0.6)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 100, height: 100)
                                    .shadow(color: AppColors.shadow, radius: 12, x: 0, y: 6)
                                
                                Image(systemName: "sparkles")
                                    .font(.system(size: 50, weight: .light))
                                    .foregroundColor(AppColors.buttonPrimaryText)
                            }
                            
                            Text("Shoply")
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(AppColors.primaryText)
                            
                            if let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String,
                               let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String {
                                Text("Version \(version) (\(build))")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(AppColors.secondaryText)
                            }
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 24) {
                            // Description
                            VStack(alignment: .leading, spacing: 12) {
                            Text("Description")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppColors.primaryText)
                            
                                Text("Shoply est votre assistant personnel intelligent pour créer des tenues parfaites selon votre humeur, la météo et votre style personnel. L'application utilise l'intelligence artificielle avancée (Gemini) pour vous proposer des combinaisons d'outfits adaptées à vos préférences et à votre garde-robe.")
                                    .font(.system(size: 15, weight: .regular))
                                .foregroundColor(AppColors.secondaryText)
                                .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.cardBackground)
                            .roundedCorner(16)
                            .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 4)
                            
                            // Fonctionnalités
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Fonctionnalités principales")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(AppColors.primaryText)
                                
                                VStack(spacing: 10) {
                                    FeatureRow(icon: "photo.fill", text: "Gestion complète de votre garde-robe")
                                    FeatureRow(icon: "sparkles", text: "Suggestions intelligentes d'outfits avec IA")
                                    FeatureRow(icon: "cloud.sun.fill", text: "Intégration météo en temps réel")
                                FeatureRow(icon: "heart.fill", text: "Système de favoris")
                                    FeatureRow(icon: "calendar", text: "Historique et calendrier des outfits")
                                    FeatureRow(icon: "message.fill", text: "Assistant IA conversationnel")
                            }
                        }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.cardBackground)
                            .roundedCorner(16)
                            .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 4)
                            
                            // Développement
                            VStack(alignment: .leading, spacing: 12) {
                            Text("Développement")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(AppColors.primaryText)
                            
                                Text("Développé avec SwiftUI pour iOS et iPadOS, utilisant les dernières technologies d'intelligence artificielle pour offrir une expérience utilisateur exceptionnelle.")
                                    .font(.system(size: 15, weight: .regular))
                                    .foregroundColor(AppColors.secondaryText)
                                    .lineSpacing(4)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.cardBackground)
                            .roundedCorner(16)
                            .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 4)
                            
                            // Contact développeur
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Contact")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(AppColors.primaryText)
                                
                                Button(action: {
                                    if let url = URL(string: "https://urlr.me/5M3nYj") {
                                        UIApplication.shared.open(url)
                                    }
                                }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: "link.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(AppColors.buttonPrimary)
                                        
                                        Text("Me contacter sur LinkedIn")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(AppColors.primaryText)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.right")
                                            .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColors.secondaryText)
                        }
                                    .padding(16)
                                    .background(AppColors.buttonSecondary)
                                    .roundedCorner(12)
                                    .shadow(color: AppColors.shadow, radius: 6, x: 0, y: 3)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.cardBackground)
                            .roundedCorner(16)
                            .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("À propos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                    .foregroundColor(AppColors.buttonPrimary)
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
