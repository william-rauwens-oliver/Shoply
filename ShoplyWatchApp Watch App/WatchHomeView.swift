//
//  WatchHomeView.swift
//  ShoplyWatchApp
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    @EnvironmentObject var watchOutfitService: WatchOutfitService
    @EnvironmentObject var watchWeatherService: WatchWeatherService
    @State private var currentOutfit: WatchOutfitSuggestion?
    @State private var isLoading = true
    @State private var greeting = ""
    @State private var userName = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Salutation personnalisée
                if !userName.isEmpty {
                    GreetingCard(greeting: greeting, userName: userName)
                }
                
                // En-tête avec météo
                if let weather = watchWeatherService.currentWeather {
                    WeatherCard(weather: weather)
                }
                
                // Suggestion d'outfit du jour
                if let outfit = currentOutfit {
                    OutfitSuggestionCard(outfit: outfit)
                } else if isLoading {
                    ProgressView()
                        .padding()
                } else {
                    Text("Aucune suggestion disponible")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding()
                }
                
                // Actions rapides
                QuickActionsView()
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .navigationTitle("Shoply")
        .onAppear {
            loadGreeting()
            loadTodayOutfit()
        }
    }
    
    private func loadGreeting() {
        let profile = watchDataManager.getUserProfile()
        userName = profile.firstName
        
        let hour = Calendar.current.component(.hour, from: Date())
        if hour >= 5 && hour < 18 {
            greeting = "Bonjour"
        } else {
            greeting = "Bonsoir"
        }
    }
    
    private func loadTodayOutfit() {
        isLoading = true
        Task {
            let outfit = await watchOutfitService.getTodaySuggestion()
            await MainActor.run {
                currentOutfit = outfit
                isLoading = false
            }
        }
    }
}

struct WeatherCard: View {
    let weather: WatchWeather
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: weatherIcon)
                    .font(.title3)
                Text("\(Int(weather.temperature))°")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Text(weather.condition)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
    
    private var weatherIcon: String {
        switch weather.condition.lowercased() {
        case let condition where condition.contains("pluie"):
            return "cloud.rain.fill"
        case let condition where condition.contains("nuage"):
            return "cloud.fill"
        case let condition where condition.contains("soleil"):
            return "sun.max.fill"
        default:
            return "cloud.sun.fill"
        }
    }
}

struct OutfitSuggestionCard: View {
    let outfit: WatchOutfitSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Outfit du jour")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(outfit.title)
                .font(.headline)
            
            if !outfit.items.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    ForEach(outfit.items.prefix(3), id: \.self) { item in
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text(item)
                                .font(.caption)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

struct GreetingCard: View {
    let greeting: String
    let userName: String
    
    var body: some View {
        HStack {
            Text("\(greeting), \(userName) !")
                .font(.headline)
            Spacer()
        }
        .padding(8)
        .background(Color.blue.opacity(0.1))
        .cornerRadius(8)
    }
}

struct QuickActionsView: View {
    var body: some View {
        VStack(spacing: 8) {
            NavigationLink(destination: WatchOutfitSuggestionsView()) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Nouvelle suggestion")
                }
                .font(.caption)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(8)
            }
            
            NavigationLink(destination: WatchChatView()) {
                HStack {
                    Image(systemName: "message.fill")
                    Text("Chat IA")
                }
                .font(.caption)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.2))
                .cornerRadius(8)
            }
        }
    }
}

