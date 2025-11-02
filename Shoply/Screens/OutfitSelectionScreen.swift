//
//  OutfitSelectionScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct OutfitSelectionScreen: View {
    let mood: Mood
    let weather: WeatherType
    @ObservedObject var outfitService: OutfitService
    @State private var selectedOutfit: Outfit?
    @State private var showDetails = false
    
    var filteredOutfits: [Outfit] {
        outfitService.getOutfitsFor(mood: mood, weather: weather)
    }
    
    var body: some View {
        ZStack {
            // Gradient de fond adaptatif
            ZStack {
                AppColors.background
                mood.backgroundColor.opacity(0.2)
            }
            .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 25) {
                    // En-tête
                    VStack(spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("Outfits pour".localized)
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(AppColors.secondaryText)
                                
                                HStack(spacing: 10) {
                                    Image(systemName: mood.icon)
                                        .foregroundColor(AppColors.primaryText)
                                    Text(mood.rawValue)
                                        .font(.playfairDisplayBold(size: 28))
                                        .foregroundColor(AppColors.primaryText)
                                }
                            }
                            
                            Spacer()
                            
                            // Badge météo
                            VStack(spacing: 5) {
                                Image(systemName: weather.icon)
                                    .font(.system(size: 24))
                                    .foregroundColor(AppColors.primaryText)
                                Text(weather.rawValue)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            .padding()
                            .background(
                                AppColors.buttonSecondary,
                                in: RoundedRectangle(cornerRadius: 15)
                            )
                        }
                        .padding(.horizontal)
                        
                        if filteredOutfits.isEmpty {
                            Text("Aucun outfit disponible".localized)
                                .font(.system(size: 16))
                                .foregroundColor(AppColors.secondaryText)
                                .padding(.top, 20)
                        } else {
                            let foundText = filteredOutfits.count > 1 ? "outfits trouvés".localized : "outfit trouvé".localized
                            Text("\(filteredOutfits.count) \(foundText)")
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                    .padding(.top, 10)
                    
                    // Grille d'outfits
                    if !filteredOutfits.isEmpty {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 15),
                            GridItem(.flexible(), spacing: 15)
                        ], spacing: 20) {
                            ForEach(filteredOutfits) { outfit in
                                OutfitCard(
                                    outfit: outfit,
                                    moodColor: AppColors.primaryText
                                ) {
                                    selectedOutfit = outfit
                                    showDetails = true
                                }
                            }
                        }
                        .padding(.horizontal)
                    } else {
                        // Message si aucun outfit
                        VStack(spacing: 20) {
                            Image(systemName: "tshirt.fill")
                                .font(.system(size: 60))
                                .foregroundColor(AppColors.tertiaryText)
                            
                            Text("Aucun outfit disponible".localized)
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppColors.secondaryText)
                            
                            Text("Essayez une autre combinaison d'humeur et de météo".localized)
                                .font(.system(size: 14))
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        .padding(.top, 50)
                    }
                }
                .padding(.vertical)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Choisissez votre style".localized)
                    .font(.playfairDisplayBold(size: 20))
            }
        }
        .sheet(item: $selectedOutfit) { outfit in
            OutfitDetailScreen(
                outfit: outfit,
                mood: mood,
                weather: weather
            )
        }
    }
}

// Carte d'outfit
struct OutfitCard: View {
    let outfit: Outfit
    let moodColor: Color
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                action()
            }
        }) {
            VStack(alignment: .leading, spacing: 12) {
                // Image placeholder
                ZStack {
                    RoundedRectangle(cornerRadius: 15)
                        .fill(AppColors.buttonSecondary)
                        .frame(height: 180)
                    
                    VStack(spacing: 8) {
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 50))
                            .foregroundColor(AppColors.primaryText)
                        Text(outfit.name)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                
                // Informations
                VStack(alignment: .leading, spacing: 6) {
                    Text(outfit.name)
                        .font(.playfairDisplayBold(size: 18))
                        .foregroundColor(AppColors.primaryText)
                        .lineLimit(1)
                    
                    Text(outfit.type.rawValue)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppColors.secondaryText)
                    
                    // Barres de niveau
                    HStack(spacing: 15) {
                        // Confort
                        HStack(spacing: 4) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.primaryText)
                            ForEach(0..<5) { index in
                                Circle()
                                    .fill(index < outfit.comfortLevel ? AppColors.buttonPrimary : AppColors.buttonSecondary)
                                    .frame(width: 6, height: 6)
                            }
                        }
                        
                        // Style
                        HStack(spacing: 4) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 10))
                                .foregroundColor(AppColors.primaryText)
                            ForEach(0..<5) { index in
                                Circle()
                                    .fill(index < outfit.styleLevel ? AppColors.buttonPrimary : AppColors.buttonSecondary)
                                    .frame(width: 6, height: 6)
                            }
                        }
                    }
                    .font(.system(size: 8))
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 8)
            }
            .cleanCard(cornerRadius: 20)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

#Preview {
    NavigationStack {
        OutfitSelectionScreen(
            mood: .energetic,
            weather: .sunny,
            outfitService: OutfitService()
        )
        .environmentObject(DataManager.shared)
    }
}

