//
//  SmartOutfitSelectionScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import Combine
import CoreLocation

/// Écran de sélection intelligente d'outfit avec météo automatique - Design moderne refait
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
    @State private var useAdvancedAI: Bool = true // Toujours activé maintenant
    @State private var showingArticleError = false
    @State private var selectedStyle: OutfitType? = nil
    @State private var customStylePrompt: String = ""
    @State private var showingCustomStyleInput = false
    @State private var userSpecificRequest: String = ""
    @State private var showingUserRequestInput = false
    @Environment(\.colorScheme) var colorScheme
    
    private var isAdvancedAIAvailable: Bool {
        if #available(iOS 18.0, *) {
            if appleIntelligenceWrapper.isEnabled {
                return true
            }
        }
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
                // Fond adaptatif selon le mode
                AppColors.background
                    .ignoresSafeArea()
                
                if isGenerating {
                    ModernLoadingView(
                        message: "Analyse de votre garde-robe...".localized,
                        progress: generationProgress,
                        wardrobeService: wardrobeService
                    )
                } else if showingResults && !generatedOutfits.isEmpty {
                    ModernOutfitResultsView(
                        outfits: generatedOutfits,
                        onRegenerate: {
                            Task {
                                await startOutfitGeneration()
                            }
                        },
                        onBack: {
                            showingResults = false
                            generatedOutfits = []
                        }
                    )
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: DesignSystem.Spacing.xl) {
                            // En-tête moderne
                            ModernHeaderSection(userProfile: userProfile)
                                .padding(.top, DesignSystem.Spacing.lg)
                                .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            // Section Collections
                            CollectionsSection(
                                selectedCollection: $selectedCollection,
                                customStylePrompt: $customStylePrompt,
                                collectionService: collectionService
                            )
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            // Section Demande utilisateur
                            UserRequestSection(
                                userRequest: $userSpecificRequest,
                                showingInput: $showingUserRequestInput
                            )
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            // Section Algorithme
                            AlgorithmSection(
                                useAdvancedAI: $useAdvancedAI,
                                isAdvancedAIAvailable: isAdvancedAIAvailable
                            )
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            
                            // Bouton de génération
                            GenerateButtonSection(
                                isEnabled: canGenerate,
                                action: {
                                    if selectedCollection == nil && customStylePrompt.isEmpty {
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
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Sélection intelligente".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButtonWithLongPress()
                }
            }
            .onAppear {
                setupWeatherService()
                useAdvancedAI = isAdvancedAIAvailable
            }
            .alert("Articles insuffisants".localized, isPresented: $showingArticleError) {
                Button("OK", role: .cancel) { }
            } message: {
                Group {
                    if selectedCollection == nil && customStylePrompt.isEmpty {
                        Text("Veuillez sélectionner une collection avant de générer des outfits.".localized)
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
        guard selectedCollection != nil || !customStylePrompt.isEmpty else {
            return false
        }
        
        guard weatherService.morningWeather != nil &&
              weatherService.afternoonWeather != nil else {
            return false
        }
        
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
        guard hasEnoughItems() else {
            await MainActor.run {
                let tops = wardrobeService.items.filter { $0.category == .top }.count
                let bottoms = wardrobeService.items.filter { $0.category == .bottom }.count
                weatherError = String(format: "Pas assez d'articles. Vous devez avoir au moins 3 hauts et 3 bas différents. Actuellement : %d haut(s), %d bas".localized, tops, bottoms)
                isGenerating = false
            }
            return
        }
        
        guard selectedCollection != nil || !customStylePrompt.isEmpty else {
            await MainActor.run {
                weatherError = "Veuillez sélectionner une collection avant de générer des outfits.".localized
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
        
        if weatherService.morningWeather == nil || weatherService.afternoonWeather == nil {
            await weatherService.fetchWeatherForToday()
            
            var attempts = 0
            while (weatherService.morningWeather == nil || weatherService.afternoonWeather == nil) && attempts < 10 {
                try? await Task.sleep(nanoseconds: 500_000_000)
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
        
        await MainActor.run {
            generationProgress = 0.2
        }
        
        var profileWithStyle = userProfile
        if let style = selectedStyle {
            profileWithStyle.preferences.preferredStyle = style
        }
        
        let algorithm = OutfitMatchingAlgorithm(
            wardrobeService: wardrobeService,
            weatherService: weatherService,
            userProfile: profileWithStyle
        )
        
        await MainActor.run {
            generationProgress = 0.3
        }
        
        let outfits: [MatchedOutfit]
        let userRequest = userSpecificRequest.trimmingCharacters(in: .whitespaces)
        let finalUserRequest = !userRequest.isEmpty ? userRequest : nil
        let collectionToUse = selectedCollection
        
        if useAdvancedAI && isAdvancedAIAvailable {
            outfits = await algorithm.generateOutfitsWithProgress(forceLocal: false, userRequest: finalUserRequest, selectedCollection: collectionToUse) { progress in
                await MainActor.run {
                    self.generationProgress = 0.3 + (progress * 0.6)
                }
            }
        } else {
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

// MARK: - En-tête moderne

struct ModernHeaderSection: View {
    let userProfile: UserProfile
    @StateObject private var weatherService = WeatherService.shared
    @State private var greetingKey = "Bonjour"
    @State private var currentTime = Date()
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Icône principale avec gradient
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
                    .frame(width: 100, height: 100)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 48, weight: .medium))
                    .foregroundColor(AppColors.buttonPrimary)
                    .modifier(SymbolEffectModifier())
            }
            
            VStack(spacing: DesignSystem.Spacing.sm) {
                if !userProfile.firstName.isEmpty {
                    Text("\(greetingKey.localized), \(userProfile.firstName)")
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
        }
        .onAppear {
            updateGreeting()
        }
        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { _ in
            currentTime = Date()
            updateGreeting()
        }
    }
    
    private func updateGreeting() {
        let now = currentTime
        
        if let location = weatherService.location {
            let lat = location.coordinate.latitude
            let lon = location.coordinate.longitude
            guard !lat.isNaN && !lon.isNaN && !lat.isInfinite && !lon.isInfinite else {
                let hour = Calendar.current.component(.hour, from: now)
                greetingKey = (hour >= 5 && hour < 18) ? "Bonjour" : "Bonsoir"
                return
            }
            greetingKey = SunsetService.shared.getGreeting(
                latitude: lat,
                longitude: lon,
                currentTime: now
            )
        } else {
            // Si pas de localisation, essayer de la demander
            Task {
                _ = await weatherService.startLocationUpdates()
                await MainActor.run {
                    updateGreeting()
                }
            }
            // Fallback temporaire basé sur l'heure
            let hour = Calendar.current.component(.hour, from: now)
            greetingKey = (hour >= 5 && hour < 18) ? "Bonjour" : "Bonsoir"
        }
    }
}

// MARK: - Section Collections

struct CollectionsSection: View {
    @Binding var selectedCollection: WardrobeCollection?
    @Binding var customStylePrompt: String
    @ObservedObject var collectionService: WardrobeCollectionService
    @State private var showingCustomInput = false
    
    private var availableCollections: [WardrobeCollection] {
        collectionService.collections
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
            // En-tête de section moderne
            HStack {
                HStack(spacing: 12) {
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
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "square.grid.2x2.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.buttonPrimary)
                    }
                    
                    Text("Collection".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                        .fontWeight(.bold)
                }
                
                Spacer()
            }
            
            // Liste des collections
            if availableCollections.isEmpty {
                EmptyCollectionsView()
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(availableCollections) { collection in
                            ModernCollectionSelectionCard(
                                collection: collection,
                                isSelected: selectedCollection?.id == collection.id,
                                onTap: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        if selectedCollection?.id == collection.id {
                                            selectedCollection = nil
                                        } else {
                                            selectedCollection = collection
                                            customStylePrompt = ""
                                        }
                                    }
                                }
                            )
                            .frame(width: 110, height: 140)
                        }
                    }
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.xs)
                }
                .frame(height: 160)
                .scrollIndicators(.hidden)
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .liquidGlassCard(cornerRadius: DesignSystem.Radius.xl)
    }
}

struct ModernCollectionSelectionCard: View {
    let collection: WardrobeCollection
    let isSelected: Bool
    let onTap: () -> Void
    @State private var isPressed = false
    
    private var collectionColor: Color {
        colorFromString(collection.color)
    }
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            VStack(spacing: 12) {
                // Icône avec fond gradient
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: isSelected ? [
                                    collectionColor.opacity(0.3),
                                    collectionColor.opacity(0.15)
                                ] : [
                                    AppColors.buttonSecondary,
                                    AppColors.buttonSecondary.opacity(0.7)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                        .overlay {
                            Circle()
                                .stroke(
                                    isSelected ? collectionColor.opacity(0.5) : AppColors.cardBorder.opacity(0.3),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        }
                    
                    Image(systemName: collection.icon)
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(isSelected ? collectionColor : AppColors.primaryText)
                }
                
                // Nom de la collection
                Text(collection.name)
                    .font(DesignSystem.Typography.footnote())
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(1)
                    .frame(maxWidth: 100)
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                    .fill(isSelected ? collectionColor.opacity(0.08) : AppColors.cardBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                    .stroke(
                        isSelected ? collectionColor.opacity(0.4) : AppColors.cardBorder.opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.96 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .highPriorityGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "gray", "grey": return .gray
        case "pink": return .pink
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "mint": return .mint
        default: return AppColors.buttonPrimary
        }
    }
}

struct EmptyCollectionsView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(AppColors.secondaryText)
            
            Text("Aucune collection disponible".localized)
                .font(DesignSystem.Typography.footnote())
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DesignSystem.Spacing.lg)
    }
}

// MARK: - Section Demande utilisateur

struct UserRequestSection: View {
    @Binding var userRequest: String
    @Binding var showingInput: Bool
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.buttonPrimary)
                
                Text("Demande spécifique".localized)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(AppColors.primaryText)
                
                Spacer()
                
                Button {
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
                } label: {
                    Image(systemName: showingInput ? "xmark.circle.fill" : "plus.circle.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(showingInput ? .red : AppColors.buttonPrimary)
                }
            }
            
            if showingInput {
                TextField("Ex: un style décontracté avec des couleurs vives".localized, text: $userRequest, axis: .vertical)
                    .focused($isTextFieldFocused)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(AppColors.primaryText)
                    .padding(DesignSystem.Spacing.md)
                    .background(AppColors.buttonSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
                    .overlay(
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                            .stroke(isTextFieldFocused ? AppColors.buttonPrimary : AppColors.cardBorder, lineWidth: isTextFieldFocused ? 2 : 1)
                    )
                    .lineLimit(2...4)
                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
            }
        }
        .padding(DesignSystem.Spacing.lg)
        .liquidGlassCard(cornerRadius: DesignSystem.Radius.lg)
    }
}

// MARK: - Section Algorithme

struct AlgorithmSection: View {
    @Binding var useAdvancedAI: Bool
    let isAdvancedAIAvailable: Bool
    
    @StateObject private var appleIntelligenceWrapper = AppleIntelligenceServiceWrapper.shared
    @StateObject private var geminiService = GeminiService.shared
    
    private var providerDisplayName: String {
        if #available(iOS 18.0, *) {
            if appleIntelligenceWrapper.isEnabled {
                return "Apple Intelligence"
            }
        }
        return "Shoply AI"
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
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
            HStack {
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(AppColors.buttonPrimary)
                
                Text("Méthode de génération".localized)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(AppColors.primaryText)
            }
            
            VStack(spacing: DesignSystem.Spacing.md) {
                // Option Shoply AI (IA avancée)
                AIOptionCard(
                    icon: isAppleIntelligence ? "applelogo" : "star.circle.fill",
                    title: "Shoply AI",
                    description: isAppleIntelligence ? "Intelligence artificielle avancée • Données restent sur votre appareil • Privé et sécurisé" : "Intelligence artificielle avancée • Suggestions personnalisées et intelligentes • Optimisé pour vos préférences",
                    isSelected: true,
                    color: advancedAIColor,
                    isEnabled: isAdvancedAIAvailable,
                    action: {
                        // Toujours activé
                    }
                )
            }
            
            if !isAdvancedAIAvailable {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14, weight: .medium))
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
        .liquidGlassCard(cornerRadius: DesignSystem.Radius.lg)
    }
}

struct AIOptionCard: View {
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
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                        .fill(isSelected ? color.opacity(0.2) : AppColors.buttonSecondary)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(isSelected ? color : AppColors.secondaryText)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(title.localized)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.primaryText)
                        .multilineTextAlignment(.leading)
                    
                    Text(description.localized)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer()
                
                ZStack {
                    if isSelected {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 28, height: 28)
                        
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(color)
                    } else {
                        Circle()
                            .stroke(AppColors.cardBorder, lineWidth: 2)
                            .frame(width: 24, height: 24)
                    }
                }
            }
            .padding(DesignSystem.Spacing.md)
            .background(isSelected ? color.opacity(0.1) : AppColors.buttonSecondary)
            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
            .overlay(
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .stroke(isSelected ? color.opacity(0.6) : AppColors.cardBorder, lineWidth: isSelected ? 2 : 1)
            )
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

// MARK: - Section Bouton Génération

struct GenerateButtonSection: View {
    let isEnabled: Bool
    let action: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(isEnabled ? AppColors.buttonPrimaryText.opacity(0.2) : AppColors.buttonSecondary)
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(isEnabled ? AppColors.buttonPrimaryText : AppColors.secondaryText)
                        .modifier(SymbolEffectModifier())
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
                    .stroke(isEnabled ? AppColors.buttonPrimary.opacity(0.3) : AppColors.cardBorder, lineWidth: isEnabled ? 2 : 1)
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

// MARK: - Loading moderne (conservé)

struct ModernLoadingView: View {
    let message: String
    let progress: Double
    @ObservedObject var wardrobeService: WardrobeService
    @State private var currentStep = 0
    
    private var aiSteps: [(message: String, threshold: Double)] {
        let providerName = "Shoply AI"
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
                        ZStack {
                            Circle()
                                .stroke(AppColors.buttonPrimary.opacity(0.3), lineWidth: 3)
                                .frame(width: 50, height: 50)
                                .rotationEffect(.degrees(progress * 360))
                            
                            Image(systemName: "sparkles")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(AppColors.buttonPrimary)
                                .modifier(SymbolEffectModifier())
                        }
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
                            if progress >= step.threshold - 0.15 {
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
        .onChange(of: progress) { newValue in
            withAnimation(.easeInOut(duration: 0.3)) {
                currentStep = Int(newValue * 10)
            }
        }
    }
}

// MARK: - Résultats modernes (conservé)

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
    @State private var showingAddedConfirmation = false
    
    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                HStack {
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
                                Image(systemName: "sparkles")
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
                
                if outfit.reason.contains("ChatGPT") || outfit.reason.contains("Gemini") || outfit.reason.contains("Suggestion") {
                    let providerName = "Shoply AI"
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
            
            VStack(spacing: 0) {
                let providerName = "Shoply AI"
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
        .liquidGlassCard(cornerRadius: DesignSystem.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                .stroke(AppColors.cardBorder, lineWidth: 1)
        )
    }
}

struct ModernOutfitItemRow: View {
    let item: WardrobeItem
    
    var body: some View {
        HStack(spacing: 16) {
            if let photoURL = item.photoURL,
               let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
            } else {
                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
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

#Preview {
    SmartOutfitSelectionScreen()
}
