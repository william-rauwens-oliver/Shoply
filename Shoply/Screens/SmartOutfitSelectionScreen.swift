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
                    ScrollView {
                        VStack(spacing: 32) {
                            // En-tête moderne avec animation
                            ModernHeaderView(userProfile: userProfile)
                                .padding(.top, 20)
                                .slideIn()
                            
                            // Sélection de style vestimentaire
                            StyleSelectionCard(
                                selectedStyle: $selectedStyle,
                                customStylePrompt: $customStylePrompt,
                                showingCustomInput: $showingCustomStyleInput
                            )
                            .slideIn()
                            
                            // Demande spécifique de l'utilisateur
                            UserRequestCard(
                                userRequest: $userSpecificRequest,
                                showingInput: $showingUserRequestInput
                            )
                                .slideIn()
                            
                            // Carte météo moderne
                            if let morning = weatherService.morningWeather,
                               let afternoon = weatherService.afternoonWeather {
                                VStack(spacing: 16) {
                                    // Message de succès météo
                                    if weatherService.weatherFetchedSuccessfully {
                                        HStack {
                                            Image(systemName: "checkmark.circle.fill")
                                                .foregroundColor(.green)
                                            Text(weatherService.weatherStatusMessage)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.green)
                                        }
                                        .padding()
                                        .background(AppColors.buttonSecondary)
                                        .cornerRadius(12)
                                    }
                                    
                                ModernWeatherCard(
                                    morning: morning,
                                    afternoon: afternoon,
                                    cityName: weatherService.cityName.isEmpty ? nil : weatherService.cityName
                                )
                                }
                                .slideIn()
                            } else if weatherService.isLoading {
                                VStack(spacing: 12) {
                                    ProgressView()
                                    Text(weatherService.weatherStatusMessage)
                                        .font(.system(size: 14))
                                        .foregroundColor(AppColors.secondaryText)
                                }
                                .padding()
                                .cleanCard(cornerRadius: 16)
                                    .slideIn()
                            } else if let error = weatherError {
                                ModernErrorCard(error: error) {
                                    Task {
                                        await startOutfitGeneration()
                                    }
                                }
                            }
                            
                            // Sélecteur d'algorithme (IA locale vs IA avancée)
                            AlgorithmSelectionCard(
                                useAdvancedAI: $useAdvancedAI,
                                isAdvancedAIAvailable: isAdvancedAIAvailable
                            )
                            .slideIn()
                            
                            Spacer(minLength: 20)
                            
                            // Bouton principal moderne avec animation
                            ModernGenerateButton(
                                isEnabled: canGenerate,
                                action: {
                                    // Vérifier les conditions avant de générer
                                    if selectedStyle == nil {
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
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Sélection intelligente".localized)
                        .font(.playfairDisplayBold(size: 20))
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
                    if selectedStyle == nil {
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
        // Vérifier qu'un style est sélectionné (obligatoire)
        guard selectedStyle != nil else {
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
        guard selectedStyle != nil else {
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
        
        if useAdvancedAI && isAdvancedAIAvailable {
            // Utiliser l'IA avancée sélectionnée (ChatGPT ou Gemini)
            outfits = await algorithm.generateOutfitsWithProgress(forceLocal: false, userRequest: finalUserRequest) { progress in
            await MainActor.run {
                self.generationProgress = 0.3 + (progress * 0.6)
                }
            }
        } else {
            // Utiliser l'algorithme local uniquement
            outfits = await algorithm.generateOutfitsWithProgress(forceLocal: true, userRequest: finalUserRequest) { progress in
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
        VStack(spacing: 12) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(AppColors.primaryText)
            
            if !userProfile.firstName.isEmpty {
                Text("\(greetingText), \(userProfile.firstName)")
                    .font(.playfairDisplayBold(size: 32))
                    .foregroundColor(AppColors.primaryText)
            } else {
                Text("Sélection intelligente".localized)
                    .font(.playfairDisplayBold(size: 32))
                    .foregroundColor(AppColors.primaryText)
            }
            
            Text("Laissez l'IA choisir vos meilleurs outfits".localized)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
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

// MARK: - Carte météo moderne

struct ModernWeatherCard: View {
    let morning: WeatherData
    let afternoon: WeatherData
    let cityName: String?
    
    var body: some View {
        VStack(spacing: 20) {
            if let cityName = cityName, !cityName.isEmpty {
                HStack {
                    Image(systemName: "location.fill")
                        .font(.system(size: 14))
                    Text(cityName)
                        .font(.system(size: 18, weight: .semibold))
                }
                .foregroundColor(AppColors.primaryText)
            }
            
            HStack(spacing: 24) {
                WeatherPeriodView(
                    period: "Matin",
                    icon: "sunrise.fill",
                    temperature: Int(morning.temperature),
                    condition: morning.condition.rawValue
                )
                
                Divider()
                    .frame(height: 60)
                    .background(AppColors.separator)
                
                WeatherPeriodView(
                    period: "Après-midi",
                    icon: "sun.max.fill",
                    temperature: Int(afternoon.temperature),
                    condition: afternoon.condition.rawValue
                )
            }
        }
        .padding(24)
        .cleanCard(cornerRadius: 20)
        .padding(.horizontal, 24)
    }
}

struct WeatherPeriodView: View {
    let period: String
    let icon: String
    let temperature: Int
    let condition: String
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                Text(period)
                    .font(.system(size: 13, weight: .medium))
                    .textCase(.uppercase)
                    .tracking(1)
            }
            .foregroundColor(AppColors.secondaryText)
            
            Text("\(temperature)°")
                .font(.system(size: 42, weight: .light))
                .foregroundColor(AppColors.primaryText)
            
            Text(condition)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
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
                .font(.playfairDisplayBold(size: 32))
                .foregroundColor(AppColors.primaryText)
            
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(AppColors.secondaryText)
                .textCase(.uppercase)
                .tracking(0.5)
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
            HStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                
                Text("Générer mes outfits".localized)
                    .font(.system(size: 18, weight: .semibold))
            }
            .foregroundColor(isEnabled ? AppColors.buttonPrimaryText : AppColors.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(isEnabled ? AppColors.buttonPrimary : AppColors.buttonSecondary)
            .cornerRadius(16)
            .shadow(
                color: isEnabled ? AppColors.shadow : Color.clear,
                radius: isEnabled ? 12 : 0,
                x: 0,
                y: isEnabled ? 4 : 0
            )
        }
        .disabled(!isEnabled)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
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
                        .font(.playfairDisplayBold(size: 24))
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
                                .font(.playfairDisplayBold(size: 28))
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
                        .font(.playfairDisplayBold(size: 16))
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
    
    private let availableStyles: [OutfitType] = [.casual, .business, .smartCasual, .formal, .weekend]
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Style vestimentaire".localized)
                        .font(.playfairDisplayBold(size: 18))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Choisissez le style d'outfit que vous souhaitez".localized)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
            }
            
            // Boutons de sélection de style
            VStack(spacing: 12) {
                ForEach(availableStyles, id: \.self) { style in
                    Button(action: {
                        selectedStyle = style
                        showingCustomInput = false
                        customStylePrompt = ""
                    }) {
                        HStack {
                            Image(systemName: getStyleIcon(style))
                                .font(.system(size: 18))
                                .foregroundColor(selectedStyle == style ? AppColors.buttonPrimaryText : AppColors.primaryText)
                            
                            Text(style.rawValue)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(selectedStyle == style ? AppColors.buttonPrimaryText : AppColors.primaryText)
                            
                            Spacer()
                            
                            if selectedStyle == style {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(AppColors.buttonPrimaryText)
                            }
                        }
                        .padding()
                        .background(selectedStyle == style ? AppColors.buttonPrimary : AppColors.buttonSecondary)
                        .roundedCorner(12)
                        .shadow(color: AppColors.shadow, radius: selectedStyle == style ? 8 : 4, x: 0, y: selectedStyle == style ? 4 : 2)
                    }
                }
            }
        }
        .padding(20)
        .cleanCard(cornerRadius: 16)
        .padding(.horizontal, 24)
    }
    
    private func getStyleIcon(_ style: OutfitType) -> String {
        switch style {
        case .casual:
            return "tshirt.fill"
        case .business:
            return "briefcase.fill"
        case .smartCasual:
            return "shirt.fill"
        case .formal:
            return "person.suit.cloth.fill"
        case .weekend:
            return "sun.max.fill"
        }
    }
}

// MARK: - Carte de demande spécifique utilisateur

struct UserRequestCard: View {
    @Binding var userRequest: String
    @Binding var showingInput: Bool
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Demande spécifique".localized)
                        .font(.playfairDisplayBold(size: 18))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Dites-moi quel vêtement vous voulez (ex: je veux mon short rouge)".localized)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                Button(action: {
                    showingInput.toggle()
                    if !showingInput {
                        userRequest = ""
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            isTextFieldFocused = true
                        }
                    }
                }) {
                    Image(systemName: showingInput ? "xmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(showingInput ? .red : AppColors.buttonPrimary)
                }
            }
            
            if showingInput {
                TextField("Ex: je veux mon short rouge, mon t-shirt bleu...".localized, text: $userRequest, axis: .vertical)
                    .focused($isTextFieldFocused)
                    .font(.system(size: 15))
                    .foregroundColor(AppColors.primaryText)
                    .padding()
                    .background(AppColors.buttonSecondary)
                    .roundedCorner(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isTextFieldFocused ? AppColors.buttonPrimary : AppColors.cardBorder.opacity(0.3), lineWidth: isTextFieldFocused ? 2 : 1)
                    )
                    .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 4)
                    .lineLimit(2...4)
            }
        }
        .padding(20)
        .cleanCard(cornerRadius: 16)
        .padding(.horizontal, 24)
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
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Méthode de génération".localized)
                        .font(.playfairDisplayBold(size: 18))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Choisissez comment générer vos outfits".localized)
                        .font(.system(size: 13))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
            }
            
            // Toggle principal
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: isAppleIntelligence ? "applelogo" : "brain.head.profile")
                                .font(.system(size: 18))
                                .foregroundColor(useAdvancedAI ? (isAppleIntelligence ? .blue : .purple) : AppColors.secondaryText)
                            
                            Text("\(providerDisplayName) ".localized + "(IA avancée)".localized)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.primaryText)
                        }
                        
                        Text(isAppleIntelligence ? "Plus puissant • Données restent sur votre appareil • Privé et sécurisé".localized : "Plus puissant • Plus de chances de trouver • Données envoyées à".localized + " \(providerDisplayName)")
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { useAdvancedAI && isAdvancedAIAvailable },
                        set: { useAdvancedAI = $0 && isAdvancedAIAvailable }
                    ))
                    .disabled(!isAdvancedAIAvailable)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(useAdvancedAI && isAdvancedAIAvailable ? (isAppleIntelligence ? Color.blue.opacity(0.1) : Color.purple.opacity(0.1)) : AppColors.buttonSecondary)
                )
                
                HStack {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            Image(systemName: "cpu")
                                .font(.system(size: 18))
                                .foregroundColor(!useAdvancedAI ? AppColors.buttonPrimary : AppColors.secondaryText)
                            
                            Text("Mon algorithme (local)".localized)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.primaryText)
                        }
                        
                        Text("Moins puissant • Données restent sur votre appareil".localized)
                            .font(.system(size: 12))
                            .foregroundColor(AppColors.secondaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Spacer()
                    
                    Toggle("", isOn: Binding(
                        get: { !useAdvancedAI },
                        set: { useAdvancedAI = !$0 }
                    ))
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(!useAdvancedAI ? AppColors.buttonSecondary : Color.clear)
                )
            }
            
            // Avertissement si l'IA avancée n'est pas disponible
            if !isAdvancedAIAvailable {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(AppColors.secondaryText)
                    Text("\(providerDisplayName) " + "n'est pas configuré. Utilisation de l'algorithme local.".localized)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.secondaryText)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(20)
        .cleanCard(cornerRadius: 16)
    }
}

#Preview {
    SmartOutfitSelectionScreen()
}
