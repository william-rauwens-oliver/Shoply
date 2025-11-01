//
//  SmartOutfitSelectionScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

/// Écran de sélection intelligente d'outfit avec météo automatique
struct SmartOutfitSelectionScreen: View {
    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var wardrobeService = WardrobeService()
    @State private var isGenerating = false
    @State private var generatedOutfits: [MatchedOutfit] = []
    @State private var showingResults = false
    @State private var weatherError: String?
    
    private var userProfile: UserProfile {
        DataManager.shared.loadUserProfile() ?? UserProfile()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                if isGenerating {
                    LoadingView(message: "Génération en cours...")
                } else if showingResults && !generatedOutfits.isEmpty {
                    OutfitResultsView(outfits: generatedOutfits)
                } else {
                    ScrollView {
                        VStack(spacing: 40) {
                            // En-tête épuré
                            VStack(spacing: 8) {
                                if !userProfile.firstName.isEmpty {
                                    Text(userProfile.firstName)
                                        .font(.system(size: 32, weight: .light))
                                        .foregroundColor(.black)
                                }
                                
                                Text("Sélection intelligente")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundColor(.gray)
                                    .padding(.top, 4)
                            }
                            .padding(.top, 60)
                            
                            // Météo épurée - Toujours observer le service
                            if let morning = weatherService.morningWeather,
                               let afternoon = weatherService.afternoonWeather {
                                WeatherSummaryView(
                                    morning: morning,
                                    afternoon: afternoon,
                                    cityName: weatherService.cityName.isEmpty ? nil : weatherService.cityName
                                )
                            } else if weatherService.isLoading {
                                VStack(spacing: 12) {
                                    ProgressView()
                                        .tint(.black)
                                    Text("Récupération de la météo...")
                                        .font(.system(size: 14, weight: .regular))
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 20)
                            } else if let error = weatherError {
                                WeatherErrorView(error: error) {
                                    Task {
                                        await startOutfitGeneration()
                                    }
                                }
                            }
                            
                            // Stats minimales
                            WardrobeStatsCard(wardrobeService: wardrobeService)
                            
                            Spacer(minLength: 40)
                            
                            // Bouton épuré
                            Button(action: {
                                Task {
                                    await startOutfitGeneration()
                                }
                            }) {
                                Text("Générer")
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(Color.black)
                                    .cornerRadius(0)
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 40)
                            .disabled(wardrobeService.items.isEmpty || weatherService.morningWeather == nil)
                            .opacity(wardrobeService.items.isEmpty || weatherService.morningWeather == nil ? 0.5 : 1.0)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("")
                }
            }
            .onAppear {
                // Vérifier et demander la permission de localisation
                if !weatherService.hasLocation {
                    weatherService.startLocationUpdates()
                } else {
                    // Si on a déjà la localisation, récupérer la météo
                    Task {
                        await weatherService.fetchWeatherForToday()
                    }
                }
            }
        }
    }
    
    private func startOutfitGeneration() async {
        isGenerating = true
        weatherError = nil
        
        // Vérifier que la météo est disponible
        guard weatherService.morningWeather != nil,
              weatherService.afternoonWeather != nil else {
            await MainActor.run {
                weatherError = "Impossible de récupérer la météo. Vérifiez votre connexion et la localisation."
                isGenerating = false
            }
            return
        }
        
        // Vérifier qu'il y a des items avec photos
        let itemsWithPhotos = wardrobeService.items.filter { $0.photoURL != nil && !($0.photoURL?.isEmpty ?? true) }
        guard !itemsWithPhotos.isEmpty else {
            await MainActor.run {
                weatherError = "Ajoutez des photos de vos vêtements dans votre garde-robe pour générer des outfits."
                isGenerating = false
            }
            return
        }
        
        // Générer les outfits
        let algorithm = OutfitMatchingAlgorithm(
            wardrobeService: wardrobeService,
            weatherService: weatherService,
            userProfile: userProfile
        )
        
        let outfits = await algorithm.generateOutfits()
        
        await MainActor.run {
            if outfits.isEmpty {
                weatherError = "Aucun outfit trouvé. Assurez-vous d'avoir des vêtements adaptés à la météo actuelle."
            } else {
                generatedOutfits = outfits
                showingResults = true
            }
            isGenerating = false
        }
    }
}

// MARK: - Résumé météo épuré
struct WeatherSummaryView: View {
    let morning: WeatherData
    let afternoon: WeatherData
    let cityName: String?
    
    var body: some View {
        VStack(spacing: 24) {
            // Ville
            if let cityName = cityName, !cityName.isEmpty {
                Text(cityName)
                    .font(.system(size: 18, weight: .light))
                    .foregroundColor(.black)
            }
            
            // Températures épurées
            HStack(spacing: 0) {
                WeatherPeriodCard(
                    period: "Matin",
                    weather: morning
                )
                
                Divider()
                    .frame(height: 60)
                    .padding(.horizontal, 20)
                
                WeatherPeriodCard(
                    period: "Après-midi",
                    weather: afternoon
                )
            }
        }
        .padding(.horizontal, 24)
    }
}

struct WeatherPeriodCard: View {
    let period: String
    let weather: WeatherData
    
    var body: some View {
        VStack(spacing: 4) {
            Text(period)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .tracking(0.5)
            
            Text("\(Int(weather.temperature))°")
                .font(.system(size: 36, weight: .light))
                .foregroundColor(.black)
            
            Text(weather.condition.rawValue)
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Chargement météo
struct WeatherLoadingView: View {
    let cityName: String?
    
    var body: some View {
        VStack(spacing: 15) {
            if let cityName = cityName, !cityName.isEmpty {
                HStack {
                    Image(systemName: "location.fill")
                        .foregroundColor(.blue)
                    Text(cityName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                }
            }
            
            ProgressView()
            
            Text(cityName != nil ? "Récupération de la météo..." : "Localisation en cours...")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
        }
        .padding()
        .adaptiveCard(cornerRadius: 20)
        .padding(.horizontal)
    }
}

// MARK: - Erreur épurée
struct WeatherErrorView: View {
    let error: String
    let retry: () -> Void
    
    var body: some View {
        VStack(spacing: 20) {
            Text(error)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            
            Button(action: retry) {
                Text("Réessayer")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.black)
                    .underline()
            }
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Stats épurées
struct WardrobeStatsCard: View {
    @ObservedObject var wardrobeService: WardrobeService
    
    var body: some View {
        let stats = wardrobeService.getWardrobeStats()
        
        HStack(spacing: 0) {
            StatItem(
                value: "\(stats.totalItems)",
                label: "Articles"
            )
            
            Divider()
                .frame(height: 40)
                .padding(.horizontal, 20)
            
            StatItem(
                value: "\(stats.totalPhotos)",
                label: "Photos"
            )
            
            Divider()
                .frame(height: 40)
                .padding(.horizontal, 20)
            
            StatItem(
                value: "\(stats.favoriteItems)",
                label: "Favoris"
            )
        }
        .padding(.horizontal, 24)
    }
}

struct StatItem: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.system(size: 28, weight: .light))
                .foregroundColor(.black)
            
            Text(label)
                .font(.system(size: 11, weight: .regular))
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Vue de chargement épurée
struct LoadingView: View {
    let message: String
    
    var body: some View {
        VStack(spacing: 24) {
            ProgressView()
                .tint(.black)
            
            Text(message)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Résultats épurés
struct OutfitResultsView: View {
    let outfits: [MatchedOutfit]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("Suggestions")
                    .font(.system(size: 24, weight: .light))
                    .foregroundColor(.black)
                    .padding(.top, 20)
                
                ForEach(Array(outfits.enumerated()), id: \.element.id) { index, outfit in
                    MatchedOutfitCard(outfit: outfit, index: index + 1)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Carte outfit épurée
struct MatchedOutfitCard: View {
    let outfit: MatchedOutfit
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Numéro
            Text("\(index)")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .tracking(1)
            
            // Items
            VStack(alignment: .leading, spacing: 12) {
                ForEach(outfit.items, id: \.id) { item in
                    OutfitItemRow(item: item)
                }
            }
            
            // Trait de séparation fin
            Divider()
                .padding(.top, 4)
        }
        .padding(.vertical, 20)
    }
}

struct OutfitItemRow: View {
    let item: WardrobeItem
    
    var body: some View {
        HStack(spacing: 16) {
            // Photo minimaliste
            if let photoURL = item.photoURL,
               let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipped()
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.15))
                    .frame(width: 48, height: 48)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(.black)
                
                Text(item.category.rawValue.lowercased())
                    .font(.system(size: 12, weight: .regular))
                    .foregroundColor(.gray)
            }
            
            Spacer()
        }
    }
}

#Preview {
    SmartOutfitSelectionScreen()
}

