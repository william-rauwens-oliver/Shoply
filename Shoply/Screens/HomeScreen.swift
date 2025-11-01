//
//  HomeScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import Combine

struct HomeScreen: View {
    @StateObject private var outfitService = OutfitService()
    @State private var currentTime = Date()
    @State private var selectedMood: Mood?
    @State private var favoritesCount = 0
    @State private var todayOutfit: Outfit?
    @State private var navigateToMoodSelection = false
    @State private var navigateToOutfitSelection = false
    @State private var selectedWeather: WeatherType = .sunny
    
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient de fond adaptatif
                adaptiveGradient()
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        // En-tête personnalisé
                        HeaderSection(currentTime: currentTime)
                            .padding(.top, 10)
                        
                        // Carte principale - Sélection rapide
                        QuickSelectionCard(
                            navigateToMoodSelection: $navigateToMoodSelection
                        )
                        
                        // Outfit du jour
                        if let outfit = todayOutfit {
                            NavigationLink(
                                destination: OutfitDetailScreen(
                                    outfit: outfit,
                                    mood: selectedMood ?? .energetic,
                                    weather: .sunny
                                )
                            ) {
                                TodayOutfitCard(outfit: outfit)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        
                        // Statistiques
                        StatsSection(
                            favoritesCount: favoritesCount,
                            totalOutfits: outfitService.outfits.count
                        )
                        
                        // Humeurs rapides avec navigation
                        QuickMoodsSection(
                            selectedMood: $selectedMood,
                            selectedWeather: $selectedWeather,
                            navigateToOutfitSelection: $navigateToOutfitSelection
                        )
                        
                        // Suggestions basées sur la météo
                        WeatherSuggestionsSection(
                            outfitService: outfitService,
                            selectedMood: $selectedMood,
                            selectedWeather: $selectedWeather,
                            navigateToOutfitSelection: $navigateToOutfitSelection
                        )
                        
                        // Derniers outfits consultés
                        RecentOutfitsSection(
                            outfitService: outfitService
                        )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Shoply")
                        .font(.custom("PlayfairDisplay-Bold", size: 24))
                        .foregroundColor(.primary)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink(destination: FavoritesScreen()) {
                        Image(systemName: "heart.fill")
                            .foregroundColor(.pink)
                    }
                }
            }
        }
        .navigationDestination(isPresented: $navigateToMoodSelection) {
            MoodSelectionScreen()
        }
        .navigationDestination(isPresented: $navigateToOutfitSelection) {
            if let mood = selectedMood {
                OutfitSelectionScreen(
                    mood: mood,
                    weather: selectedWeather,
                    outfitService: outfitService
                )
            } else {
                OutfitSelectionScreen(
                    mood: .energetic,
                    weather: selectedWeather,
                    outfitService: outfitService
                )
            }
        }
        .onReceive(timer) { _ in
            currentTime = Date()
        }
        .onAppear {
            loadTodayOutfit()
            updateFavoritesCount()
        }
    }
    
    private func loadTodayOutfit() {
        if !outfitService.outfits.isEmpty {
            todayOutfit = outfitService.outfits.randomElement()
        }
    }
    
    private func updateFavoritesCount() {
        favoritesCount = outfitService.outfits.filter { $0.isFavorite }.count
    }
}

// Section d'en-tête
struct HeaderSection: View {
    let currentTime: Date
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 5) {
                    Text(greeting)
                        .font(.custom("PlayfairDisplay-Bold", size: 32))
                        .foregroundColor(.primary)
                    
                    Text(formattedDate)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Avatar
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.pink.opacity(0.3), Color.purple.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: "person.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.primary)
                }
            }
        }
    }
    
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: currentTime)
        switch hour {
        case 5..<12:
            return "Bonjour ! ☀️"
        case 12..<17:
            return "Bon après-midi ! 🌤️"
        case 17..<22:
            return "Bonsoir ! 🌙"
        default:
            return "Bonne nuit ! ✨"
        }
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE d MMMM"
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: currentTime).capitalized
    }
}

// Carte de sélection rapide
struct QuickSelectionCard: View {
    @Binding var navigateToMoodSelection: Bool
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Choisissez votre outfit")
                        .font(.custom("PlayfairDisplay-Bold", size: 24))
                        .foregroundColor(.primary)
                    
                    Text("Selon votre humeur du jour")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "sparkles")
                    .font(.system(size: 32))
                    .foregroundColor(.yellow)
            }
            
            Button(action: {
                navigateToMoodSelection = true
            }) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("Commencer la sélection")
                        .font(.system(size: 18, weight: .semibold))
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                .foregroundColor(.white)
                .padding()
                .background(
                    LinearGradient(
                        colors: [
                            Color.pink,
                            Color.purple.opacity(0.8)
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .cornerRadius(16)
                .shadow(color: Color.pink.opacity(0.3), radius: 10, x: 0, y: 5)
            }
        }
        .padding(25)
        .adaptiveCard(cornerRadius: 25)
    }
}

// Carte outfit du jour
struct TodayOutfitCard: View {
    let outfit: Outfit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Outfit du jour")
                    .font(.custom("PlayfairDisplay-Bold", size: 22))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "calendar")
                    .foregroundColor(.blue)
            }
            
            HStack(spacing: 15) {
                // Image placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.pink.opacity(0.3),
                                    Color.purple.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.pink)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(outfit.name)
                        .font(.custom("PlayfairDisplay-Bold", size: 20))
                        .foregroundColor(.primary)
                    
                    Text(outfit.type.rawValue)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 15) {
                        Label("\(outfit.comfortLevel)/5", systemImage: "heart.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.pink)
                        
                        Label("\(outfit.styleLevel)/5", systemImage: "sparkles")
                            .font(.system(size: 12))
                            .foregroundColor(.yellow)
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .adaptiveCard(cornerRadius: 20)
    }
}

// Section statistiques
struct StatsSection: View {
    let favoritesCount: Int
    let totalOutfits: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Statistiques")
                .font(.custom("PlayfairDisplay-Bold", size: 22))
                .foregroundColor(.primary)
            
            HStack(spacing: 15) {
                HomeStatCard(
                    icon: "tshirt.fill",
                    title: "Outfits",
                    value: "\(totalOutfits)",
                    color: .blue
                )
                
                HomeStatCard(
                    icon: "heart.fill",
                    title: "Favoris",
                    value: "\(favoritesCount)",
                    color: .pink
                )
            }
        }
    }
}

// Carte de statistique
struct HomeStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(color)
            
            Text(value)
                .font(.custom("PlayfairDisplay-Bold", size: 32))
                .foregroundColor(.primary)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .adaptiveCard(cornerRadius: 20)
    }
}

// Section humeurs rapides
struct QuickMoodsSection: View {
    @Binding var selectedMood: Mood?
    @Binding var selectedWeather: WeatherType
    @Binding var navigateToOutfitSelection: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Humeurs rapides")
                .font(.custom("PlayfairDisplay-Bold", size: 22))
                .foregroundColor(.primary)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(Mood.allCases) { mood in
                        QuickMoodChip(
                            mood: mood,
                            isSelected: selectedMood == mood
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if selectedMood == mood {
                                    selectedMood = nil
                                } else {
                                    selectedMood = mood
                                    // Navigation automatique vers les outfits
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        navigateToOutfitSelection = true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// Puce humeur rapide
struct QuickMoodChip: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: mood.icon)
                    .font(.system(size: 16))
                Text(mood.rawValue)
                    .font(.system(size: 14, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : .primary)
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(isSelected ? mood.color : Color.gray.opacity(0.2))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// Section suggestions météo
struct WeatherSuggestionsSection: View {
    @ObservedObject var outfitService: OutfitService
    @Binding var selectedMood: Mood?
    @Binding var selectedWeather: WeatherType
    @Binding var navigateToOutfitSelection: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Suggestions météo")
                    .font(.custom("PlayfairDisplay-Bold", size: 22))
                    .foregroundColor(.primary)
                
                Spacer()
                
                Image(systemName: "cloud.sun.fill")
                    .foregroundColor(.orange)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(WeatherType.allCases, id: \.self) { weather in
                        Button(action: {
                            selectedWeather = weather
                            // Si pas d'humeur sélectionnée, utiliser énergique par défaut
                            if selectedMood == nil {
                                selectedMood = .energetic
                            }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                navigateToOutfitSelection = true
                            }
                        }) {
                            WeatherSuggestionCard(
                                weather: weather,
                                outfitCount: outfitService.outfits.filter { $0.suitableWeather.contains(weather) }.count
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

// Carte suggestion météo
struct WeatherSuggestionCard: View {
    let weather: WeatherType
    let outfitCount: Int
    
    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: weather.icon)
                .font(.system(size: 32))
                .foregroundColor(weather.color)
            
            Text(weather.rawValue)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("\(outfitCount) outfit\(outfitCount > 1 ? "s" : "")")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(width: 120)
        .padding(15)
        .adaptiveCard(cornerRadius: 15)
    }
}

// Section derniers outfits
struct RecentOutfitsSection: View {
    @ObservedObject var outfitService: OutfitService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Text("Outfits populaires")
                    .font(.custom("PlayfairDisplay-Bold", size: 22))
                    .foregroundColor(.primary)
                
                Spacer()
                
                NavigationLink("Voir tout") {
                    OutfitSelectionScreen(
                        mood: .energetic,
                        weather: .sunny,
                        outfitService: outfitService
                    )
                }
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.blue)
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(Array(outfitService.outfits.prefix(5))) { outfit in
                        NavigationLink(
                            destination: OutfitDetailScreen(
                                outfit: outfit,
                                mood: .energetic,
                                weather: .sunny
                            )
                        ) {
                            CompactOutfitCard(outfit: outfit)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
        }
    }
}

// Carte outfit compacte
struct CompactOutfitCard: View {
    let outfit: Outfit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.pink.opacity(0.3),
                                Color.purple.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 150, height: 150)
                
                Image(systemName: "tshirt.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.pink.opacity(0.7))
            }
            
            Text(outfit.name)
                .font(.custom("PlayfairDisplay-Bold", size: 16))
                .foregroundColor(.primary)
                .lineLimit(1)
            
            Text(outfit.type.rawValue)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .frame(width: 150)
    }
}

// Écran des favoris
struct FavoritesScreen: View {
    @StateObject private var outfitService = OutfitService()
    
    var favoriteOutfits: [Outfit] {
        outfitService.outfits.filter { $0.isFavorite }
    }
    
    var body: some View {
        ZStack {
            adaptiveGradient()
                .ignoresSafeArea()
            
            if favoriteOutfits.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "heart.slash")
                        .font(.system(size: 60))
                        .foregroundColor(.gray.opacity(0.3))
                    
                    Text("Aucun favori")
                        .font(.custom("PlayfairDisplay-Bold", size: 24))
                        .foregroundColor(.primary)
                    
                    Text("Ajoutez des outfits à vos favoris")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
            } else {
                ScrollView {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 15) {
                        ForEach(favoriteOutfits) { outfit in
                            NavigationLink(
                                destination: OutfitDetailScreen(
                                    outfit: outfit,
                                    mood: .energetic,
                                    weather: .sunny
                                )
                            ) {
                                CompactOutfitCard(outfit: outfit)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Favoris")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    HomeScreen()
}
