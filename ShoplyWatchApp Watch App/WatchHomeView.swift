//
//  WatchHomeView.swift
//  ShoplyWatchApp
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct WatchHomeView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    @State private var greeting = ""
    @State private var userName = ""
    @State private var recentHistory: [WatchOutfitHistoryItem] = []
    @State private var favoriteOutfits: [WatchOutfitHistoryItem] = []
    @State private var showingChat = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                // Section 1: Parler à Shoply AI
                VStack(alignment: .leading, spacing: 8) {
                    if !userName.isEmpty {
                        Text("\(greeting), \(userName) !")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal, 4)
                    }
                    
                    Button(action: {
                        showingChat = true
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "message.fill")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("Parler à Shoply AI")
                                .font(.headline)
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                
                // Section 2: Historique des outfits portés
                if !recentHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Historique")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal, 4)
                        
                        ForEach(recentHistory) { item in
                            HistoryItemCard(item: item)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Historique")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal, 4)
                        
                        Text("Aucun historique")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                    }
                }
                
                // Section 3: Outfits favoris
                if !favoriteOutfits.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Favoris")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal, 4)
                            .padding(.top, 4)
                        
                        ForEach(favoriteOutfits) { outfit in
                            FavoriteOutfitCard(outfit: outfit)
                        }
                    }
                } else {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Favoris")
                            .font(.headline)
                            .fontWeight(.bold)
                            .padding(.horizontal, 4)
                            .padding(.top, 4)
                        
                        Text("Aucun favori")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 4)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .navigationTitle("Shoply")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showingChat) {
            WatchChatView()
                .environmentObject(watchDataManager)
        }
        .onAppear {
            loadGreeting()
            loadHistory()
            loadFavorites()
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
    
    private func loadHistory() {
        recentHistory = watchDataManager.getOutfitHistory()
    }
    
    private func loadFavorites() {
        favoriteOutfits = watchDataManager.getFavoriteOutfits()
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
        VStack(alignment: .leading, spacing: 8) {
            Text("Outfit du jour")
                .font(.caption)
                .foregroundColor(.secondary)
                .textCase(.uppercase)
            
            Text("Outfit du jour")
                .font(.headline)
                .fontWeight(.bold)
            
            if !outfit.items.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(outfit.items.prefix(3), id: \.self) { item in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text(item)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(12)
    }
}

struct GreetingCard: View {
    let greeting: String
    let userName: String
    
    var body: some View {
        HStack {
            Text("\(greeting), \(userName) !")
                .font(.headline)
                .fontWeight(.bold)
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.blue.opacity(0.1)]),
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .cornerRadius(12)
    }
}


