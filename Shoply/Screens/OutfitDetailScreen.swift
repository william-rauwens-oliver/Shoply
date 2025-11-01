//
//  OutfitDetailScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct OutfitDetailScreen: View {
    let outfit: Outfit
    let mood: Mood
    let weather: WeatherType
    @Environment(\.dismiss) var dismiss
    @State private var isFavorite = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond gradient adaptatif
                ZStack {
                    adaptiveGradient()
                    mood.backgroundColor.opacity(0.3)
                }
                .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        // Image principale
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            mood.color.opacity(0.3),
                                            mood.backgroundColor.opacity(0.5)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 350)
                            
                            VStack(spacing: 15) {
                                Image(systemName: "tshirt.fill")
                                    .font(.system(size: 100))
                                    .foregroundColor(mood.color.opacity(0.7))
                                
                                Text(outfit.name)
                                    .font(.playfairDisplayBold(size: 32))
                                    .foregroundColor(.primary)
                                
                                Text(outfit.type.rawValue)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Description
                        VStack(alignment: .leading, spacing: 15) {
                            Text("À propos de cet outfit")
                                .font(.playfairDisplayBold(size: 22))
                                .foregroundColor(.primary)
                            
                            Text(outfit.description)
                                .font(.system(size: 16))
                                .foregroundColor(.secondary)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal)
                        
                        // Composants de l'outfit
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Composition")
                                .font(.playfairDisplayBold(size: 22))
                                .foregroundColor(.primary)
                            
                            OutfitComponentRow(icon: "tshirt.fill", title: "Haut", value: outfit.top)
                            OutfitComponentRow(icon: "figure.walk", title: "Bas", value: outfit.bottom)
                            OutfitComponentRow(icon: "shoe.fill", title: "Chaussures", value: outfit.shoes)
                            
                            if !outfit.accessories.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(mood.color)
                                        Text("Accessoires")
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(.primary)
                                    }
                                    
                                    ForEach(outfit.accessories, id: \.self) { accessory in
                                        HStack {
                                            Circle()
                                                .fill(mood.color.opacity(0.3))
                                                .frame(width: 8, height: 8)
                                            Text(accessory)
                                                .font(.system(size: 16))
                                                .foregroundColor(.secondary)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Statistiques
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Caractéristiques")
                                .font(.playfairDisplayBold(size: 22))
                                .foregroundColor(.primary)
                            
                            StatCard(
                                title: "Confort",
                                level: outfit.comfortLevel,
                                color: .pink,
                                icon: "heart.fill"
                            )
                            
                            StatCard(
                                title: "Style",
                                level: outfit.styleLevel,
                                color: .yellow,
                                icon: "sparkles"
                            )
                        }
                        .padding(.horizontal)
                        
                        // Compatibilité
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Parfait pour")
                                .font(.playfairDisplayBold(size: 22))
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 15) {
                                ForEach(outfit.suitableMoods) { suitableMood in
                                    MoodBadge(mood: suitableMood)
                                }
                            }
                            
                            HStack(spacing: 15) {
                                ForEach(outfit.suitableWeather, id: \.self) { suitableWeather in
                                    WeatherBadge(weather: suitableWeather)
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Bouton d'action
                        Button(action: {
                            // Action pour sauvegarder ou partager l'outfit
                        }) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text("J'adopte cet outfit !")
                                    .font(.system(size: 18, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [mood.color, mood.color.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                            .shadow(color: mood.color.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 30)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isFavorite.toggle()
                        }
                    }) {
                        Image(systemName: isFavorite ? "heart.fill" : "heart")
                            .font(.system(size: 24))
                            .foregroundColor(isFavorite ? .pink : .secondary)
                    }
                }
            }
        }
    }
}

// Composant d'outfit
struct OutfitComponentRow: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.primary)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.gray.opacity(0.1))
        )
    }
}

// Carte de statistique
struct StatCard: View {
    let title: String
    let level: Int
    let color: Color
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(index < level ? color : Color.gray.opacity(0.2))
                        .frame(height: 8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(Color.white.opacity(0.7))
        )
    }
}

// Badge d'humeur
struct MoodBadge: View {
    let mood: Mood
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: mood.icon)
                .font(.system(size: 12))
            Text(mood.rawValue)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(mood.color)
        )
    }
}

// Badge météo
struct WeatherBadge: View {
    let weather: WeatherType
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: weather.icon)
                .font(.system(size: 12))
            Text(weather.rawValue)
                .font(.system(size: 12, weight: .medium))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(weather.color)
        )
    }
}

#Preview {
    NavigationStack {
        OutfitDetailScreen(
            outfit: PreviewHelpers.sampleOutfit,
            mood: .energetic,
            weather: .sunny
        )
        .environmentObject(DataManager.shared)
    }
}

