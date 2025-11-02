//
//  OutfitCalendarScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import EventKit

/// Écran de calendrier pour planifier les outfits à l'avance
struct OutfitCalendarScreen: View {
    @StateObject private var wardrobeService = WardrobeService()
    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var historyStore = OutfitHistoryStore()
    @StateObject private var openAIService = OpenAIService.shared
    @StateObject private var geminiService = GeminiService.shared
    @StateObject private var settingsManager = AppSettingsManager.shared
    @State private var selectedDate = Date()
    @State private var scheduledOutfits: [Date: MatchedOutfit] = [:]
    @State private var showingOutfitSelection = false
    @State private var selectedOutfit: MatchedOutfit?
    @State private var isGenerating = false
    @State private var generationError: String?
    @State private var generationProgress: Double = 0.0
    @State private var useAdvancedAI: Bool = true // Par défaut, utiliser l'IA avancée si disponible
    @State private var showingArticleError = false
    
    private var isAdvancedAIAvailable: Bool {
        // Utiliser Gemini uniquement
        return geminiService.isEnabled
    }
    @State private var weatherFetchedForSelectedDate = false
    @State private var isFetchingWeather = false
    @State private var weatherErrorMessage: String?
    
    // Vérifier si la date est trop loin dans le futur
    private var isDateTooFar: Bool {
        let calendar = Calendar.current
        let daysDifference = calendar.dateComponents([.day], from: Date(), to: selectedDate).day ?? 0
        return daysDifference > 7 // Plus de 7 jours dans le futur
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Sélecteur de date épuré
                        VStack(spacing: 16) {
                            DatePicker("Date", selection: $selectedDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                            
                            // Bouton pour récupérer la météo
                            if !weatherFetchedForSelectedDate && !isFetchingWeather {
                                Button(action: {
                                    Task {
                                        await fetchWeatherForSelectedDate()
                                    }
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "cloud.sun.fill")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("Récupérer la météo pour cette date".localized)
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                    .foregroundColor(AppColors.buttonPrimaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(AppColors.buttonPrimary)
                                    .roundedCorner(14)
                                }
                            }
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
                        .padding(.horizontal, 20)
                        .onChange(of: selectedDate) { oldValue, newValue in
                            // Réinitialiser l'état météo quand on change de date
                            weatherFetchedForSelectedDate = false
                            weatherErrorMessage = nil
                            scheduledOutfits.removeValue(forKey: Calendar.current.startOfDay(for: newValue))
                        }
                        
                        // Afficher le statut de la météo
                        if isFetchingWeather || weatherService.isLoading {
                            HStack(spacing: 12) {
                                ProgressView()
                                Text(isDateTooFar ? "Vérification de la disponibilité météo..." : weatherService.weatherStatusMessage)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            .padding(18)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.cardBackground)
                            .overlay {
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 0.5)
                            }
                            .roundedCorner(18)
                            .shadow(color: AppColors.shadow.opacity(0.06), radius: 8, x: 0, y: 2)
                            .padding(.horizontal, 20)
                        } else if let error = weatherErrorMessage {
                            VStack(spacing: 14) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(AppColors.secondaryText.opacity(0.7))
                                
                                Text(error)
                                    .font(.system(size: 14, weight: .regular))
                                    .foregroundColor(AppColors.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .lineSpacing(2)
                            }
                            .padding(22)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(AppColors.cardBackground)
                            .overlay {
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 0.5)
                            }
                            .roundedCorner(18)
                            .shadow(color: AppColors.shadow.opacity(0.06), radius: 8, x: 0, y: 2)
                            .padding(.horizontal, 20)
                        } else if weatherFetchedForSelectedDate && weatherService.morningWeather != nil {
                            // Message de succès météo épuré
                            VStack(spacing: 14) {
                                HStack(spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18))
                                        .foregroundColor(.green)
                                    Text(weatherService.weatherStatusMessage)
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.green)
                                }
                                .padding(16)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(AppColors.buttonSecondary)
                                .roundedCorner(14)
                                
                                // Afficher les détails météo si disponibles
                                if let morning = weatherService.morningWeather,
                                   let afternoon = weatherService.afternoonWeather {
                                    ModernWeatherCard(
                                        morning: morning,
                                        afternoon: afternoon,
                                        cityName: weatherService.cityName.isEmpty ? nil : weatherService.cityName
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            
                            // Sélecteur d'algorithme
                            AlgorithmSelectionCard(
                                useAdvancedAI: $useAdvancedAI,
                                isAdvancedAIAvailable: isAdvancedAIAvailable
                            )
                            .padding(.horizontal, 20)
                            
                            // Bouton pour générer l'outfit
                            Button(action: {
                                if wardrobeService.items.count < 2 {
                                    showingArticleError = true
                                } else {
                                    Task {
                                        await generateOutfitForDate()
                                    }
                                }
                            }) {
                                HStack(spacing: 10) {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 16, weight: .medium))
                                    Text("Générer l'outfit pour cette date".localized)
                                        .font(.system(size: 15, weight: .semibold))
                                }
                                .foregroundColor(AppColors.buttonPrimaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(AppColors.buttonPrimary)
                                .roundedCorner(14)
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // Affichage de la génération en cours
                        if isGenerating {
                            ModernLoadingView(
                                message: "Analyse de votre garde-robe...",
                                progress: generationProgress,
                                wardrobeService: wardrobeService
                            )
                            .padding(.horizontal, 20)
                        } else if let error = generationError {
                            ModernErrorCard(error: error) {
                                Task {
                                    await generateOutfitForDate()
                                }
                            }
                            .padding(.horizontal, 20)
                        } else if let outfit = scheduledOutfits[Calendar.current.startOfDay(for: selectedDate)] {
                            // Affichage de l'outfit généré épuré
                            VStack(spacing: 18) {
                                Text(verbatim: "\(LocalizedString.localized("Outfit pour le")) \(selectedDate.formatted(date: .long, time: .omitted))")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(AppColors.primaryText)
                                
                                ScheduledOutfitCard(outfit: outfit) {
                                    selectedOutfit = outfit
                                    showingOutfitSelection = true
                                }
                                .slideIn()
                                
                                // Bouton pour ajouter à l'historique
                                Button(action: {
                                    historyStore.addOutfit(outfit, date: selectedDate)
                                }) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 16, weight: .medium))
                                        Text("J'ai porté cet outfit".localized)
                                            .font(.system(size: 15, weight: .semibold))
                                    }
                                    .foregroundColor(AppColors.buttonPrimaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .background(AppColors.buttonPrimary)
                                    .roundedCorner(14)
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Calendrier".localized)
            .navigationBarTitleDisplayMode(.large)
            .sheet(item: $selectedOutfit) { outfit in
                ScheduledOutfitDetailView(outfit: outfit, date: selectedDate)
            }
            .onAppear {
                // Par défaut, utiliser l'IA avancée si disponible
                useAdvancedAI = isAdvancedAIAvailable
            }
            .alert("Articles insuffisants".localized, isPresented: $showingArticleError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Vous devez avoir au moins 2 articles dans votre garde-robe avec leurs photos pour générer des outfits. Ajoutez des vêtements depuis la section \"Ma Garde-robe\".".localized)
            }
        }
    }
    
    // MARK: - Récupération de la météo pour la date sélectionnée
    
    private func fetchWeatherForSelectedDate() async {
        await MainActor.run {
            isFetchingWeather = true
            weatherFetchedForSelectedDate = false
            weatherErrorMessage = nil
            scheduledOutfits.removeValue(forKey: Calendar.current.startOfDay(for: selectedDate))
        }
        
        // Vérifier si la date est trop loin dans le futur
        if isDateTooFar {
            await MainActor.run {
                weatherErrorMessage = "Les prévisions météo ne sont disponibles que pour les 7 prochains jours. Veuillez sélectionner une date plus proche."
                isFetchingWeather = false
            }
            return
        }
        
        // Récupérer la météo pour la date sélectionnée
        await weatherService.fetchWeatherForDate(selectedDate)
        
        // Attendre que la météo soit récupérée
        var attempts = 0
        while (weatherService.morningWeather == nil || weatherService.afternoonWeather == nil) && 
              !weatherService.weatherFetchedSuccessfully && 
              attempts < 15 {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 secondes
            attempts += 1
        }
        
        await MainActor.run {
            if weatherService.morningWeather != nil && weatherService.afternoonWeather != nil {
                weatherFetchedForSelectedDate = true
                weatherErrorMessage = nil
            } else {
                weatherErrorMessage = "Impossible de récupérer la météo pour cette date. Vérifiez votre connexion et la localisation."
            }
            isFetchingWeather = false
        }
    }
    
    // MARK: - Génération d'outfit
    
    private func generateOutfitForDate() async {
        // Vérifier qu'on a assez d'articles
        guard wardrobeService.items.count >= 2 else {
            await MainActor.run {
                showingArticleError = true
                isGenerating = false
            }
            return
        }
        
        // Vérifier que la météo a été récupérée
        guard weatherFetchedForSelectedDate,
              weatherService.morningWeather != nil,
              weatherService.afternoonWeather != nil else {
            await MainActor.run {
                generationError = "Veuillez d'abord récupérer la météo pour cette date."
                isGenerating = false
            }
            return
        }
        
        await MainActor.run {
            isGenerating = true
            generationError = nil
            generationProgress = 0.0
            scheduledOutfits.removeValue(forKey: Calendar.current.startOfDay(for: selectedDate))
        }
        
        await MainActor.run {
            generationProgress = 0.1
        }
        
        guard let userProfile = DataManager.shared.loadUserProfile() else {
            await MainActor.run {
                generationError = "Profil utilisateur non trouvé."
                isGenerating = false
            }
            return
        }
        
        await MainActor.run {
            generationProgress = 0.2
        }
        
        // Utiliser l'algorithme selon le choix de l'utilisateur
        let algorithm = OutfitMatchingAlgorithm(
            wardrobeService: wardrobeService,
            weatherService: weatherService,
            userProfile: userProfile
        )
        
        // Étape 3: Générer selon le choix de l'utilisateur (50-90%)
        let outfits: [MatchedOutfit]
        
        if useAdvancedAI && isAdvancedAIAvailable {
            // Utiliser l'IA avancée sélectionnée (ChatGPT ou Gemini)
            outfits = await algorithm.generateOutfitsWithProgress(forceLocal: false) { progress in
                await MainActor.run {
                    self.generationProgress = 0.3 + (progress * 0.6)
                }
            }
        } else {
            // Utiliser l'algorithme local uniquement
            outfits = await algorithm.generateOutfitsWithProgress(forceLocal: true) { progress in
                await MainActor.run {
                    self.generationProgress = 0.3 + (progress * 0.6)
                }
            }
        }
        
        await MainActor.run {
            generationProgress = 1.0
            
            if outfits.isEmpty {
                generationError = "Aucun outfit trouvé. Assurez-vous d'avoir au moins un haut et un bas dans votre garde-robe."
                isGenerating = false
            } else {
                scheduledOutfits[Calendar.current.startOfDay(for: selectedDate)] = outfits.first
                isGenerating = false
            }
        }
    }
}

struct ScheduledOutfitCard: View {
    let outfit: MatchedOutfit
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(outfit.displayName)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("Score: \(Int(outfit.score))%")
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(AppColors.secondaryText)
                }
                
                // Aperçu des items
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(outfit.items) { item in
                            if let photoURL = item.photoURL,
                               let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                                Image(uiImage: image)
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(width: 60, height: 60)
                                    .cornerRadius(8)
                            }
                        }
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity)
            .cleanCard(cornerRadius: 16)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ScheduledOutfitDetailView: View {
    let outfit: MatchedOutfit
    let date: Date
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Outfit du \(date, style: .date)")
                        .font(.playfairDisplayBold(size: 24))
                        .foregroundColor(AppColors.primaryText)
                        .padding()
                    
                    ForEach(outfit.items) { item in
                        OutfitItemDetailRow(item: item)
                    }
                }
                .padding()
            }
            .background(AppColors.background)
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

struct OutfitItemDetailRow: View {
    let item: WardrobeItem
    
    var body: some View {
        HStack(spacing: 16) {
            if let photoURL = item.photoURL,
               let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 80, height: 80)
                    .cornerRadius(12)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.buttonSecondary)
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: item.category.icon)
                            .foregroundColor(AppColors.secondaryText)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                
                Text(item.category.rawValue)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.secondaryText)
                
                Text(item.color)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.tertiaryText)
            }
            
            Spacer()
        }
        .padding()
        .cleanCard(cornerRadius: 16)
    }
}

extension Date {
    var startOfDay: Date {
        Calendar.current.startOfDay(for: self)
    }
}

#Preview {
    OutfitCalendarScreen()
}


