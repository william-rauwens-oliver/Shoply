//
//  SmartOutfitSelectionScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import Combine
import CoreLocation

/// Écran de sélection intelligente d'outfit avec météo automatique - Design moderne
struct SmartOutfitSelectionScreen: View {
    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var wardrobeService = WardrobeService()
    @StateObject private var geminiService = GeminiService.shared
    @StateObject private var appleIntelligenceWrapper = AppleIntelligenceServiceWrapper.shared
    @StateObject private var settingsManager = AppSettingsManager.shared
    @StateObject private var collectionService = WardrobeCollectionService.shared
    @State private var selectedCollection: WardrobeCollection?
    @State private var isGenerating = false
    @State private var generatedOutfits: [MatchedOutfit] = []
    @State private var showingResults = false
    @State private var weatherError: String?
    @State private var generationProgress: Double = 0.0
    @State private var useAdvancedAI: Bool = true // Par défaut, utiliser l'IA avancée si disponible
    @State private var showingArticleError = false
    @State private var selectedStyle: OutfitType? = nil
    @State private var customStylePrompt: String = ""
    @State private var showingCustomStyleInput = false
    @State private var userSpecificRequest: String = ""
    @State private var showingUserRequestInput = false
    
    private var isAdvancedAIAvailable: Bool {
        // Vérifier si Apple Intelligence est disponible (priorité)
        if #available(iOS 18.0, *) {
            if appleIntelligenceWrapper.isEnabled {
                return true
            }
        }
        // Sinon utiliser Gemini
        return geminiService.isEnabled
    }
    
    private var selectedAIService: AIServiceType {
        if #available(iOS 18.0, *) {
            if appleIntelligenceWrapper.isEnabled && useAdvancedAI {
                return .appleIntelligence
            }
        }
        if geminiService.isEnabled && useAdvancedAI {
            return .gemini
        }
        return .local
    }
    
    enum AIServiceType {
        case appleIntelligence
        case gemini
        case local
    }
    
    private var userProfile: UserProfile {
        DataManager.shared.loadUserProfile() ?? UserProfile()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond opaque simple
                AppColors.background
                    .ignoresSafeArea()
                
                if isGenerating {
                    ModernLoadingView(
                        message: "Analyse de votre garde-robe...".localized,
                        progress: generationProgress,
                        wardrobeService: wardrobeService
                    )
                } else if showingResults && !generatedOutfits.isEmpty {
                    // Page de résultats - Afficher les outfits générés
                    ModernOutfitResultsView(
                        outfits: generatedOutfits,
                        onRegenerate: {
                            Task {
                                await startOutfitGeneration()
                            }
                        },
                        onBack: {
                            // Retourner à la page de génération
                            showingResults = false
                            generatedOutfits = []
                        }
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            // En-tête moderne avec animation
                            ModernHeaderView(userProfile: userProfile)
                                .padding(.top, DesignSystem.Spacing.lg)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            // Sélection de style vestimentaire (utilise les collections sélectionnées)
                            StyleSelectionCard(
                                selectedStyle: $selectedStyle,
                                customStylePrompt: $customStylePrompt,
                                showingCustomInput: $showingCustomStyleInput,
                                selectedCollection: selectedCollection,
                                collectionService: collectionService
                            )
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            // Demande spécifique de l'utilisateur
                            UserRequestCard(
                                userRequest: $userSpecificRequest,
                                showingInput: $showingUserRequestInput
                            )
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            // Sélecteur d'algorithme (IA locale vs IA avancée)
                            AlgorithmSelectionCard(
                                useAdvancedAI: $useAdvancedAI,
                                isAdvancedAIAvailable: isAdvancedAIAvailable
                            )
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            // Bouton principal moderne avec animation
                            ModernGenerateButton(
                                isEnabled: canGenerate,
                                action: {
                                    // Vérifier les conditions avant de générer
                                    if selectedStyle == nil && customStylePrompt.isEmpty {
                                        showingArticleError = true
                                    } else if !hasEnoughItems() {
                                        showingArticleError = true
                                    } else {
                                    Task {
                                        await startOutfitGeneration()
                                        }
                                    }
                                }
                            )
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.bottom, DesignSystem.Spacing.xxl)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Sélection intelligente".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
            }
            .onAppear {
                setupWeatherService()
                // Par défaut, utiliser l'IA avancée si disponible
                useAdvancedAI = isAdvancedAIAvailable
            }
            .alert("Articles insuffisants".localized, isPresented: $showingArticleError) {
                Button("OK", role: .cancel) { }
            } message: {
                Group {
                    if selectedStyle == nil && customStylePrompt.isEmpty {
                        Text("Veuillez sélectionner un style vestimentaire avant de générer des outfits.".localized)
                    } else {
                        let tops = wardrobeService.items.filter { $0.category == .top }.count
                        let bottoms = wardrobeService.items.filter { $0.category == .bottom }.count
                        let messageText = "Vous devez avoir au moins 3 hauts et 3 bas différents dans votre garde-robe pour générer des outfits.".localized + "\n\n" + String(format: "Actuellement : %d haut(s), %d bas".localized, tops, bottoms)
                        Text(messageText)
                    }
                }
            }
        }
    }
    
    private var canGenerate: Bool {
        // Vérifier qu'un style est sélectionné (obligatoire) - soit selectedStyle, soit customStylePrompt
        guard selectedStyle != nil || !customStylePrompt.isEmpty else {
            return false
        }
        
        // Vérifier la météo
        guard weatherService.morningWeather != nil &&
              weatherService.afternoonWeather != nil else {
            return false
        }
        
        // Vérifier qu'on a au moins 3 hauts et 3 bas différents
        let tops = wardrobeService.items.filter { $0.category == .top }
        let bottoms = wardrobeService.items.filter { $0.category == .bottom }
        
        guard tops.count >= 3, bottoms.count >= 3 else {
            return false
        }
        
        return true
    }
    
    private func hasEnoughItems() -> Bool {
        let tops = wardrobeService.items.filter { $0.category == .top }
        let bottoms = wardrobeService.items.filter { $0.category == .bottom }
        return tops.count >= 3 && bottoms.count >= 3
    }
    
    private func setupWeatherService() {
        if !weatherService.hasLocation {
            Task {
                _ = await weatherService.startLocationUpdates()
                await weatherService.fetchWeatherForToday()
            }
        } else {
            Task {
                await weatherService.fetchWeatherForToday()
            }
        }
    }
    
    private func startOutfitGeneration() async {
        // Vérifier qu'on a au moins 3 hauts et 3 bas
        guard hasEnoughItems() else {
            await MainActor.run {
                let tops = wardrobeService.items.filter { $0.category == .top }.count
                let bottoms = wardrobeService.items.filter { $0.category == .bottom }.count
                weatherError = String(format: "Pas assez d'articles. Vous devez avoir au moins 3 hauts et 3 bas différents. Actuellement : %d haut(s), %d bas".localized, tops, bottoms)
                isGenerating = false
            }
            return
        }
        
        // Vérifier que le style est sélectionné
        guard selectedStyle != nil || !customStylePrompt.isEmpty else {
            await MainActor.run {
                weatherError = "Veuillez sélectionner un style vestimentaire avant de générer des outfits.".localized
                isGenerating = false
            }
            return
        }
        
        await MainActor.run {
            isGenerating = true
            showingResults = false
            weatherError = nil
            generationProgress = 0.0
        }
        
        // Étape 1: S'assurer que la météo est récupérée (10%)
        if weatherService.morningWeather == nil || weatherService.afternoonWeather == nil {
            // Essayer de récupérer la météo
            await weatherService.fetchWeatherForToday()
            
            // Attendre un peu pour que la météo soit chargée
            var attempts = 0
            while (weatherService.morningWeather == nil || weatherService.afternoonWeather == nil) && attempts < 10 {
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 secondes
                attempts += 1
            }
            
        guard weatherService.morningWeather != nil,
              weatherService.afternoonWeather != nil else {
            await MainActor.run {
                weatherError = "Impossible de récupérer la météo. Vérifiez votre connexion et la localisation."
                isGenerating = false
            }
            return
            }
        }
        
        await MainActor.run {
            generationProgress = 0.1
        }
        
        // Étape 2: Préparer les données pour ChatGPT (20%)
        await MainActor.run {
            generationProgress = 0.2
        }
        
        // Préparer le style vestimentaire pour l'algorithme
        var profileWithStyle = userProfile
        if let style = selectedStyle {
            profileWithStyle.preferences.preferredStyle = style
        }
        
        // Utiliser OutfitMatchingAlgorithm avec choix de l'utilisateur
        let algorithm = OutfitMatchingAlgorithm(
            wardrobeService: wardrobeService,
            weatherService: weatherService,
            userProfile: profileWithStyle
        )
        
        await MainActor.run {
            generationProgress = 0.3
        }
        
        // Étape 3: Générer selon le choix de l'utilisateur (50-90%)
        // La progression sera mise à jour pendant la génération
        let outfits: [MatchedOutfit]
        
        // Préparer la demande spécifique de l'utilisateur
        let userRequest = userSpecificRequest.trimmingCharacters(in: .whitespaces)
        let finalUserRequest = !userRequest.isEmpty ? userRequest : nil
        
        // Passer la collection sélectionnée à l'algorithme
        let collectionToUse = selectedCollection
        
        if useAdvancedAI && isAdvancedAIAvailable {
            // Utiliser l'IA avancée sélectionnée (ChatGPT ou Gemini)
            outfits = await algorithm.generateOutfitsWithProgress(forceLocal: false, userRequest: finalUserRequest, selectedCollection: collectionToUse) { progress in
            await MainActor.run {
                self.generationProgress = 0.3 + (progress * 0.6)
                }
            }
        } else {
            // Utiliser l'algorithme local uniquement
            outfits = await algorithm.generateOutfitsWithProgress(forceLocal: true, userRequest: finalUserRequest, selectedCollection: collectionToUse) { progress in
                await MainActor.run {
                    self.generationProgress = 0.3 + (progress * 0.6)
                }
            }
        }
        
        await MainActor.run {
            generationProgress = 1.0
            
            if outfits.isEmpty {
                weatherError = "Aucun outfit trouvé. Assurez-vous d'avoir au moins un haut et un bas dans votre garde-robe."
                isGenerating = false
                showingResults = false
            } else {
                generatedOutfits = outfits
                showingResults = true
                isGenerating = false
            }
        }
    }
}

// MARK: - Header moderne

struct ModernHeaderView: View {
    let userProfile: UserProfile
    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var settingsManager = AppSettingsManager.shared
    @State private var greetingKey = "Bonjour"
    @State private var currentTime = Date()
    
    private var greetingText: String {
        greetingKey.localized
    }
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            ZStack {
                Circle()
                    .fill(AppColors.buttonSecondary)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 40, weight: .medium))
                    .foregroundColor(AppColors.buttonPrimary)
            }
            
            if !userProfile.firstName.isEmpty {
                Text("\(greetingText), \(userProfile.firstName)")
                    .font(DesignSystem.Typography.title())
                    .foregroundColor(AppColors.primaryText)
            } else {
                Text("Sélection intelligente".localized)
                    .font(DesignSystem.Typography.title())
                    .foregroundColor(AppColors.primaryText)
            }
            
            Text("Laissez l'IA choisir vos meilleurs outfits".localized)
                .font(DesignSystem.Typography.subheadline())
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .onAppear {
            updateGreeting()
        }
        .onChange(of: currentTime) { _, _ in
            updateGreeting()
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            currentTime = Date()
        }
    }
    
    private func updateGreeting() {
        if let location = weatherService.location {
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            // Protection contre les valeurs invalides
            guard !lat.isNaN && !lon.isNaN && !lat.isInfinite && !lon.isInfinite else {
                let hour = Calendar.current.component(.hour, from: currentTime)
                greetingKey = (hour >= 5 && hour < 18) ? "Bonjour" : "Bonsoir"
                return
            }
            greetingKey = SunsetService.shared.getGreeting(
                latitude: lat,
                longitude: lon,
                currentTime: currentTime
            )
        } else {
            let hour = Calendar.current.component(.hour, from: currentTime)
            greetingKey = (hour >= 5 && hour < 18) ? "Bonjour" : "Bonsoir"
        }
    }
}


// MARK: - Stats moderne

struct ModernWardrobeStatsCard: View {
    @ObservedObject var wardrobeService: WardrobeService
    
    var body: some View {
        let stats = wardrobeService.getWardrobeStats()
        
        HStack(spacing: 0) {
            ModernStatItem(
                icon: "tshirt.fill",
                value: "\(stats.totalItems)",
                label: "Articles"
            )
            
            Divider()
                .frame(height: 50)
                .background(AppColors.separator)
                .padding(.horizontal, 20)
            
            ModernStatItem(
                icon: "photo.fill",
                value: "\(stats.totalPhotos)",
                label: "Photos"
            )
            
            Divider()
                .frame(height: 50)
                .background(AppColors.separator)
                .padding(.horizontal, 20)
            
            ModernStatItem(
                icon: "heart.fill",
                value: "\(stats.favoriteItems)",
                label: "Favoris"
            )
        }
        .padding(.vertical, 20)
        .padding(.horizontal, 24)
        .cleanCard(cornerRadius: 20)
        .padding(.horizontal, 24)
    }
}

struct ModernStatItem: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppColors.primaryText)
            
            Text(value)
                .font(DesignSystem.Typography.title())
                .foregroundColor(AppColors.primaryText)
            
            Text(label)
                .font(DesignSystem.Typography.caption())
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Bouton moderne

struct ModernGenerateButton: View {
    let isEnabled: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(isEnabled ? AppColors.buttonPrimaryText.opacity(0.2) : AppColors.buttonSecondary)
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(isEnabled ? AppColors.buttonPrimaryText : AppColors.secondaryText)
                }
                
                Text("Générer mes outfits".localized)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(isEnabled ? AppColors.buttonPrimaryText : AppColors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DesignSystem.Spacing.lg)
            .background(isEnabled ? AppColors.buttonPrimary : AppColors.buttonSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                    .stroke(isEnabled ? AppColors.buttonPrimary.opacity(0.3) : AppColors.cardBorder, lineWidth: isEnabled ? 2 : 1.5)
            )
            .shadow(
                color: isEnabled ? AppColors.shadow.opacity(0.4) : Color.clear,
                radius: isEnabled ? 16 : 0,
                x: 0,
                y: isEnabled ? 6 : 0
            )
        }
        .disabled(!isEnabled)
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if isEnabled { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Loading moderne

struct ModernLoadingView: View {
    let message: String
    let progress: Double
    @ObservedObject var wardrobeService: WardrobeService
    @State private var currentStep = 0
    
    @StateObject private var settingsManager = AppSettingsManager.shared
    
    private var aiSteps: [(message: String, threshold: Double)] {
        let providerName = "Gemini"
        return [
            ("Préparation de vos vêtements...", 0.1),
            ("Chargement de \(wardrobeService.items.count) article(s)...", 0.2),
            ("Envoi des photos à \(providerName)...", 0.4),
            ("Envoi à \(providerName)...", 0.5),
            ("\(providerName) réfléchit...", 0.7),
            ("\(providerName) sélectionne vos vêtements...", 0.85),
            ("Création des meilleurs outfits...", 0.95),
            ("Finalisation...", 1.0)
        ]
    }
    
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .stroke(AppColors.buttonSecondary, lineWidth: 8)
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(AppColors.buttonPrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 120, height: 120)
                    .rotationEffect(.degrees(-90))
                    .animation(.linear(duration: 0.3), value: progress)
                
                VStack(spacing: 4) {
                    let isAIActive = GeminiService.shared.isEnabled
                    if isAIActive && progress > 0.5 && progress < 0.9 {
                        // Animation de réflexion pendant que l'IA pense
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 32))
                            .foregroundColor(AppColors.buttonPrimary)
                            .symbolEffect(.pulse, options: .repeating)
                    } else {
                    Text("\(Int(progress * 100))%")
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
            
            VStack(spacing: 16) {
            Text(message)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppColors.primaryText)
            
            let isAIActive = GeminiService.shared.isEnabled
            if isAIActive {
                    VStack(spacing: 12) {
                        ForEach(Array(aiSteps.enumerated()), id: \.offset) { index, step in
                            if progress >= step.threshold - 0.15 { // Afficher les étapes proches
                                HStack(spacing: 8) {
                                    if progress >= step.threshold {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 14))
                                            .transition(.scale.combined(with: .opacity))
                                    } else if progress >= step.threshold - 0.1 {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(AppColors.buttonPrimary)
                                    } else {
                                        Circle()
                                            .fill(AppColors.buttonSecondary)
                                            .frame(width: 14, height: 14)
                                    }
                                    
                                    Text(step.message)
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(progress >= step.threshold ? .green : AppColors.secondaryText)
                                }
                                .animation(.easeInOut(duration: 0.3), value: progress)
                            }
                        }
                    }
                        .padding(.horizontal, 40)
            } else {
                Text("Analyse des couleurs, matières et styles...")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                }
            }
        }
        .onChange(of: progress) { oldValue, newValue in
            // Animer les changements de progression
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = Int(newValue * 10)
            }
        }
    }
}

struct ModernLoadingCard: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 16) {
            ProgressView()
                .tint(AppColors.primaryText)
            
            Text(message)
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColors.primaryText)
        }
        .padding(20)
        .cleanCard(cornerRadius: 16)
        .padding(.horizontal, 24)
    }
}

// MARK: - Erreur moderne

struct ModernErrorCard: View {
    let error: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(AppColors.secondaryText)
            
            Text(error)
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            
            Button(action: retry) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Réessayer")
                }
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(AppColors.buttonPrimaryText)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(AppColors.buttonPrimary)
                .cornerRadius(12)
            }
        }
        .padding(24)
        .cleanCard(cornerRadius: 20)
        .padding(.horizontal, 24)
    }
}

// MARK: - Résultats modernes

struct ModernOutfitResultsView: View {
    let outfits: [MatchedOutfit]
    let onRegenerate: () -> Void
    let onBack: (() -> Void)?
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header avec bouton retour
                    HStack {
                        if let onBack = onBack {
                            Button(action: onBack) {
                                HStack(spacing: 8) {
                                    Image(systemName: "chevron.left")
                                    Text("Retour".localized)
                                }
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.primaryText)
                            }
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("\(outfits.count) " + "outfits générés".localized)
                                .font(DesignSystem.Typography.title())
                                .foregroundColor(AppColors.primaryText)
                            
                            Text("Sélectionnés pour vous".localized)
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(AppColors.secondaryText)
                        }
                        
                        Spacer()
                        
                        Button(action: onRegenerate) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 18))
                                .foregroundColor(AppColors.primaryText)
                                .padding(12)
                                .background(AppColors.buttonSecondary)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                
                // Liste des outfits
                ForEach(Array(outfits.enumerated()), id: \.element.id) { index, outfit in
                    ModernOutfitCard(outfit: outfit, rank: index + 1)
                        .padding(.horizontal, 24)
                        .slideIn()
                }
                
                    Spacer(minLength: 40)
                }
            }
        }
    }
}

struct ModernOutfitCard: View {
    let outfit: MatchedOutfit
    let rank: Int
    @StateObject private var historyStore = OutfitHistoryStore()
    @StateObject private var settingsManager = AppSettingsManager.shared
    @State private var showingAddedConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header de la carte avec badge ChatGPT
            VStack(spacing: 12) {
            HStack {
                // Rank badge
                ZStack {
                    Circle()
                        .fill(AppColors.buttonPrimary)
                        .frame(width: 32, height: 32)
                    
                    Text("\(rank)")
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.buttonPrimaryText)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                    Text("Score: \(Int(outfit.score))%")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.primaryText)
                            
                            if outfit.reason.contains("ChatGPT") || outfit.reason.contains("Gemini") || outfit.reason.contains("Suggestion") {
                                Image(systemName: "brain.head.profile")
                                    .font(.system(size: 12))
                                    .foregroundColor(.purple)
                            }
                        }
                    
                    Text(outfit.reason)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
                            .lineLimit(2)
                }
                
                Spacer()
                
                // Score bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Rectangle()
                            .fill(AppColors.buttonSecondary)
                            .frame(height: 4)
                        
                        Rectangle()
                            .fill(AppColors.buttonPrimary)
                            .frame(width: geometry.size.width * CGFloat(outfit.score / 100), height: 4)
                    }
                    .cornerRadius(2)
                }
                .frame(width: 60, height: 4)
                }
                
                // Badge "IA a sélectionné"
                let providerName = "Gemini"
                if outfit.reason.contains("ChatGPT") || outfit.reason.contains("Gemini") || outfit.reason.contains("Suggestion") {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 12))
                        Text("\(providerName) " + "a sélectionné ces vêtements pour vous".localized)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            .padding(20)
            
            Divider()
                .background(AppColors.separator)
            
            // Items avec indication claire des vêtements sélectionnés
            VStack(spacing: 0) {
                let providerName = "Gemini"
                Text("Vêtements sélectionnés par".localized + " \(providerName):")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.secondaryText)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
                
                ForEach(outfit.items, id: \.id) { item in
                    ModernOutfitItemRow(item: item)
                    
                    if item.id != outfit.items.last?.id {
                        Divider()
                            .background(AppColors.separator)
                            .padding(.leading, 84)
                    }
                }
            }
            
            // Bouton pour ajouter à l'historique
            Button(action: {
                historyStore.addOutfit(outfit)
                showingAddedConfirmation = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    showingAddedConfirmation = false
                }
            }) {
                HStack {
                    if showingAddedConfirmation {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Ajouté à l'historique".localized)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.green)
                    } else {
                        Image(systemName: "clock.fill")
                        Text("J'ai porté cet outfit".localized)
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
                .foregroundColor(showingAddedConfirmation ? .green : AppColors.buttonPrimaryText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(showingAddedConfirmation ? AppColors.buttonSecondary : AppColors.buttonPrimary)
                .cornerRadius(10)
            }
            .padding()
        }
        .cleanCard(cornerRadius: 20)
    }
}

struct ModernOutfitItemRow: View {
    let item: WardrobeItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Photo
            if let photoURL = item.photoURL,
               let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.buttonSecondary)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: item.category.icon)
                            .foregroundColor(AppColors.secondaryText)
                    )
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(item.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.primaryText)
                    
                    if item.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.primaryText)
                    }
                }
                
                HStack(spacing: 12) {
                    Label(item.category.rawValue, systemImage: item.category.icon)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("•")
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text(item.color)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            
            Spacer()
        }
        .padding(20)
    }
}

// MARK: - Sélection de style vestimentaire

struct StyleSelectionCard: View {
    @Binding var selectedStyle: OutfitType?
    @Binding var customStylePrompt: String
    @Binding var showingCustomInput: Bool
    var selectedCollection: WardrobeCollection?
    @ObservedObject var collectionService: WardrobeCollectionService
    
    // Utiliser les collections au lieu des styles
    private var availableCollections: [WardrobeCollection] {
        collectionService.collections.filter { !$0.itemIds.isEmpty }
    }
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                headerSection
                
                // Boutons de sélection de collection
                if availableCollections.isEmpty {
                    emptyStateView
                } else {
                    collectionsList
                }
            }
            .padding(DesignSystem.Spacing.lg)
        }
    }
    
    private var headerSection: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ZStack {
                Circle()
                    .fill(AppColors.buttonPrimary.opacity(0.15))
                    .frame(width: 36, height: 36)
                
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.buttonPrimary)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text("Style vestimentaire".localized)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(AppColors.primaryText)
                
                Text("Choisissez une collection pour votre outfit".localized)
                    .font(DesignSystem.Typography.footnote())
                    .foregroundColor(AppColors.secondaryText)
            }
        }
    }
    
    private var emptyStateView: some View {
        Text("Aucune collection disponible".localized)
            .font(DesignSystem.Typography.footnote())
            .foregroundColor(AppColors.secondaryText)
            .padding(.vertical, DesignSystem.Spacing.sm)
    }
    
    private var collectionsList: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            ForEach(availableCollections) { collection in
                CollectionStyleButton(
                    collection: collection,
                    isSelected: customStylePrompt == collection.name,
                    onTap: {
                        selectedStyle = nil
                        customStylePrompt = collection.name
                    }
                )
            }
        }
    }
}

private struct CollectionStyleButton: View {
    let collection: WardrobeCollection
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: DesignSystem.Spacing.md) {
                iconView
                textView
                Spacer()
                if isSelected {
                    checkmarkView
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(isSelected ? AppColors.buttonPrimary : AppColors.buttonSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
        }
    }
    
    private var iconView: some View {
        ZStack {
            Circle()
                .fill(isSelected ? AppColors.buttonPrimaryText.opacity(0.2) : AppColors.buttonSecondary)
                .frame(width: 40, height: 40)
            
            Image(systemName: collection.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isSelected ? AppColors.buttonPrimaryText : AppColors.primaryText)
        }
    }
    
    private var textView: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(collection.name)
                .font(DesignSystem.Typography.headline())
                .foregroundColor(isSelected ? AppColors.buttonPrimaryText : AppColors.primaryText)
            
            Text("\(collection.itemIds.count) items")
                .font(DesignSystem.Typography.caption())
                .foregroundColor(isSelected ? AppColors.buttonPrimaryText.opacity(0.8) : AppColors.secondaryText)
        }
    }
    
    private var checkmarkView: some View {
        Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(AppColors.buttonPrimaryText)
    }
}

// MARK: - Carte de demande spécifique utilisateur

struct UserRequestCard: View {
    @Binding var userRequest: String
    @Binding var showingInput: Bool
    @FocusState private var isTextFieldFocused: Bool
    @State private var isPressed = false
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(AppColors.buttonPrimary.opacity(0.2))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "text.bubble.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(AppColors.buttonPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Demande spécifique".localized)
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("Dites-moi quel vêtement vous voulez (ex: je veux mon short rouge)".localized)
                            .font(DesignSystem.Typography.footnote())
                            .foregroundColor(AppColors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showingInput.toggle()
                            if !showingInput {
                                userRequest = ""
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    isTextFieldFocused = true
                                }
                            }
                        }
                    }) {
                        ZStack {
                            Circle()
                                .fill(showingInput ? AppColors.buttonSecondary : AppColors.buttonPrimary.opacity(0.15))
                                .frame(width: 44, height: 44)
                            
                            Image(systemName: showingInput ? "xmark" : "plus")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(showingInput ? AppColors.secondaryText : AppColors.buttonPrimary)
                        }
                    }
                    .scaleEffect(isPressed ? 0.95 : 1.0)
                    .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in isPressed = true }
                            .onEnded { _ in isPressed = false }
                    )
                }
                
                if showingInput {
                    TextField("Ex: je veux mon short rouge, mon t-shirt bleu...".localized, text: $userRequest, axis: .vertical)
                        .focused($isTextFieldFocused)
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(AppColors.primaryText)
                        .padding(DesignSystem.Spacing.lg)
                        .background(AppColors.buttonSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
                        .overlay(
                            RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                                .stroke(isTextFieldFocused ? AppColors.buttonPrimary : AppColors.cardBorder, lineWidth: isTextFieldFocused ? 2.5 : 1.5)
                        )
                        .lineLimit(2...4)
                        .transition(.opacity.combined(with: .scale(scale: 0.95)))
                }
            }
            .padding(DesignSystem.Spacing.lg)
        }
    }
}

// MARK: - Sélecteur d'algorithme

struct AlgorithmSelectionCard: View {
    @Binding var useAdvancedAI: Bool
    let isAdvancedAIAvailable: Bool
    
    // Détecter le service IA disponible
    @StateObject private var appleIntelligenceWrapper = AppleIntelligenceServiceWrapper.shared
    @StateObject private var geminiService = GeminiService.shared
    
    // Computed properties pour déterminer le service IA
    private var providerDisplayName: String {
        if #available(iOS 18.0, *) {
            if appleIntelligenceWrapper.isEnabled {
                return "Apple Intelligence"
            }
        }
        return "Gemini"
    }
    
    private var isAppleIntelligence: Bool {
        if #available(iOS 18.0, *) {
            return appleIntelligenceWrapper.isEnabled
        }
        return false
    }
    
    private var advancedAIColor: Color {
        if isAppleIntelligence {
            return Color.blue
        }
        return Color.purple
    }
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                HStack(spacing: DesignSystem.Spacing.md) {
                    ZStack {
                        Circle()
                            .fill(AppColors.buttonPrimary.opacity(0.2))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "brain.head.profile")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundColor(AppColors.buttonPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text("Méthode de génération".localized)
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("Choisissez comment générer vos outfits".localized)
                            .font(DesignSystem.Typography.footnote())
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                
                // Options d'IA
                VStack(spacing: DesignSystem.Spacing.md) {
                    // Option Gemini/Apple Intelligence
                    AIOptionButton(
                        icon: isAppleIntelligence ? "applelogo" : "star.circle.fill",
                        title: "\(providerDisplayName) (IA avancée)",
                        description: isAppleIntelligence ? "Plus puissant • Données restent sur votre appareil • Privé et sécurisé" : "Plus puissant • Plus de chances de trouver • Données envoyées à \(providerDisplayName)",
                        isSelected: useAdvancedAI && isAdvancedAIAvailable,
                        color: advancedAIColor,
                        isEnabled: isAdvancedAIAvailable,
                        action: {
                            if isAdvancedAIAvailable {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    useAdvancedAI = true
                                }
                            }
                        }
                    )
                    
                    // Option Shoply AI (local)
                    AIOptionButton(
                        icon: "sparkles",
                        title: "Shoply AI",
                        description: "Moins puissant • Données restent sur votre appareil",
                        isSelected: !useAdvancedAI,
                        color: AppColors.buttonPrimary,
                        isEnabled: true,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                useAdvancedAI = false
                            }
                        }
                    )
                }
                
                // Avertissement si l'IA avancée n'est pas disponible
                if !isAdvancedAIAvailable {
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.secondaryText)
                        Text("\(providerDisplayName) " + "n'est pas configuré. Utilisation de l'algorithme local.".localized)
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .padding(DesignSystem.Spacing.md)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.buttonSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
                }
            }
            .padding(DesignSystem.Spacing.lg)
        }
    }
}

// MARK: - Composant réutilisable pour les options IA

struct AIOptionButton: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let color: Color
    let isEnabled: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(isSelected ? color.opacity(0.25) : AppColors.buttonSecondary)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isSelected ? color : AppColors.secondaryText)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(title.localized)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(description.localized)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.secondaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 32, height: 32)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(color)
                    } else {
                        Circle()
                            .stroke(AppColors.cardBorder, lineWidth: 2.5)
                            .frame(width: 28, height: 28)
                    }
                }
            }
            .padding(DesignSystem.Spacing.lg)
            .background(isSelected ? color.opacity(0.12) : AppColors.buttonSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                    .stroke(isSelected ? color.opacity(0.6) : AppColors.cardBorder, lineWidth: isSelected ? 2.5 : 1.5)
            )
            .shadow(color: isSelected ? color.opacity(0.2) : Color.clear, radius: isSelected ? 8 : 0, x: 0, y: isSelected ? 4 : 0)
        }
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1.0 : 0.6)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in if isEnabled { isPressed = true } }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    SmartOutfitSelectionScreen()
}
