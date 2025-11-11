//
//  WatchOutfitSuggestionsView.swift
//  ShoplyWatchApp
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct WatchOutfitSuggestionsView: View {
    @EnvironmentObject var watchOutfitService: WatchOutfitService
    @EnvironmentObject var watchWeatherService: WatchWeatherService
    @State private var suggestions: [WatchOutfitSuggestion] = []
    @State private var isLoading = false
    @State private var selectedStyle: String = "Décontracté"
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Sélecteur de style
                StylePicker(selectedStyle: $selectedStyle)
                
                // Bouton pour générer
                Button(action: generateSuggestions) {
                    HStack {
                        if isLoading {
                            ProgressView()
                                .scaleEffect(0.7)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text("Générer des suggestions")
                    }
                    .font(.caption)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .disabled(isLoading)
                
                // Liste des suggestions
                if !suggestions.isEmpty {
                    ForEach(suggestions, id: \.id) { suggestion in
                        OutfitSuggestionDetailCard(suggestion: suggestion)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .navigationTitle("Suggestions")
    }
    
    private func generateSuggestions() {
        isLoading = true
        Task {
            // Convertir le style string en OutfitStyle
            let style: OutfitStyle
            switch selectedStyle {
            case "Professionnel":
                style = .professional
            case "Sport":
                style = .sport
            case "Soirée":
                style = .evening
            default:
                style = .casual
            }
            
            let newSuggestions = await watchOutfitService.generateSuggestions(
                style: style,
                weather: watchWeatherService.currentWeather
            )
            await MainActor.run {
                suggestions = newSuggestions
                isLoading = false
            }
        }
    }
}

struct StylePicker: View {
    @Binding var selectedStyle: String
    
    private let styles = ["Décontracté", "Professionnel", "Sport", "Soirée"]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(styles, id: \.self) { style in
                    Button(action: {
                        selectedStyle = style
                    }) {
                        Text(style)
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(selectedStyle == style ? Color.blue : Color.secondary.opacity(0.2))
                            .foregroundColor(selectedStyle == style ? .white : .primary)
                            .cornerRadius(6)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct OutfitSuggestionDetailCard: View {
    let suggestion: WatchOutfitSuggestion
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(suggestion.title)
                .font(.headline)
            
            if !suggestion.description.isEmpty {
                Text(suggestion.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            if !suggestion.items.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(Array(suggestion.items.enumerated()), id: \.offset) { index, item in
                        HStack(spacing: 4) {
                            Image(systemName: "tshirt.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text(item)
                                .font(.caption2)
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}


