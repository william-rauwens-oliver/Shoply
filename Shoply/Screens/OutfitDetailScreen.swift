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
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 25) {
                        // Image principale
                        ZStack {
                            RoundedRectangle(cornerRadius: 25)
                                .fill(AppColors.buttonSecondary)
                                .frame(height: 350)
                            
                            VStack(spacing: 15) {
                                Image(systemName: "tshirt.fill")
                                    .font(.system(size: 100))
                                    .foregroundColor(AppColors.primaryText)
                                
                                Text(outfit.name)
                                    .font(.playfairDisplayBold(size: 32))
                                    .foregroundColor(AppColors.primaryText)
                                
                                Text(outfit.type.rawValue)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.secondaryText)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Description
                        VStack(alignment: .leading, spacing: 15) {
                            Text("À propos de cet outfit".localized)
                                .font(.playfairDisplayBold(size: 22))
                                .foregroundColor(AppColors.primaryText)
                            
                            Text(outfit.description)
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.secondaryText)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal)
                        
                        // Composants de l'outfit
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Composition".localized)
                                .font(.playfairDisplayBold(size: 22))
                                .foregroundColor(AppColors.primaryText)
                            
                            OutfitComponentRow(icon: "tshirt.fill", title: "Haut".localized, value: outfit.top)
                            OutfitComponentRow(icon: "figure.walk", title: "Bas".localized, value: outfit.bottom)
                            OutfitComponentRow(icon: "shoe.fill", title: "Chaussures".localized, value: outfit.shoes)
                            
                            if !outfit.accessories.isEmpty {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(AppColors.primaryText)
                                        Text("Accessoires".localized)
                                            .font(.system(size: 18, weight: .semibold))
                                            .foregroundColor(AppColors.primaryText)
                                    }
                                    
                                    ForEach(outfit.accessories, id: \.self) { accessory in
                                        HStack {
                                            Circle()
                                                .fill(AppColors.primaryText.opacity(0.3))
                                                .frame(width: 8, height: 8)
                                            Text(accessory)
                                                .font(.system(size: 16))
                                                .foregroundColor(AppColors.secondaryText)
                                        }
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                        
                        // Statistiques
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Caractéristiques".localized)
                                .font(.playfairDisplayBold(size: 22))
                                .foregroundColor(AppColors.primaryText)
                            
                            StatCard(
                                title: "Confort",
                                level: outfit.comfortLevel,
                                color: AppColors.primaryText,
                                icon: "heart.fill"
                            )
                            
                            StatCard(
                                title: "Style",
                                level: outfit.styleLevel,
                                color: AppColors.primaryText,
                                icon: "sparkles"
                            )
                        }
                        .padding(.horizontal)
                        
                        // Compatibilité
                        VStack(alignment: .leading, spacing: 15) {
                            Text("Parfait pour")
                                .font(.playfairDisplayBold(size: 22))
                                .foregroundColor(AppColors.primaryText)
                            
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
                            .foregroundColor(AppColors.buttonPrimaryText)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.buttonPrimary)
                            .cornerRadius(16)
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
                            .foregroundColor(AppColors.secondaryText)
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
                            .foregroundColor(isFavorite ? AppColors.primaryText : AppColors.secondaryText)
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
                .foregroundColor(AppColors.primaryText)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.secondaryText)
                Text(value)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
            }
            
            Spacer()
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppColors.buttonSecondary)
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
                    .foregroundColor(AppColors.primaryText)
            }
            
            HStack(spacing: 8) {
                ForEach(0..<5) { index in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(index < level ? AppColors.buttonPrimary : AppColors.buttonSecondary)
                        .frame(height: 8)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(AppColors.buttonSecondary)
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
        .foregroundColor(AppColors.buttonPrimaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(AppColors.buttonPrimary)
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
        .foregroundColor(AppColors.buttonPrimaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(AppColors.buttonPrimary)
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

