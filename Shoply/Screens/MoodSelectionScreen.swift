//
//  MoodSelectionScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import Combine

struct MoodSelectionScreen: View {
    @StateObject private var outfitService = OutfitService()
    @State private var selectedMood: Mood?
    @State private var selectedWeather: WeatherType = .sunny
    @State private var navigateToOutfits = false
    @State private var currentTime = Date()
    
    let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Gradient de fond adaptatif
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 30) {
                        // En-tête avec salutation
                        VStack(spacing: 10) {
                            Text(greeting)
                                .font(.playfairDisplayRegular(size: 32))
                                .foregroundColor(AppColors.primaryText)
                            
                            Text("Comment vous sentez-vous ce matin ?")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .padding(.top, 20)
                        
                        // Section météo
                        WeatherSection(selectedWeather: $selectedWeather)
                        
                        // Section humeurs
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Choisissez votre humeur")
                                .font(.playfairDisplayBold(size: 24))
                                .foregroundColor(AppColors.primaryText)
                                .padding(.horizontal)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 15),
                                GridItem(.flexible(), spacing: 15)
                            ], spacing: 15) {
                                ForEach(Mood.allCases) { mood in
                                    MoodCard(
                                        mood: mood,
                                        isSelected: selectedMood == mood
                                    ) {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                            selectedMood = mood
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                        
                        // Bouton de navigation
                        if let mood = selectedMood {
                            NavigationLink(
                                destination: OutfitSelectionScreen(
                                    mood: mood,
                                    weather: selectedWeather,
                                    outfitService: outfitService
                                )
                            ) {
                                HStack {
                                    Text("Voir les outfits")
                                        .font(.system(size: 18, weight: .semibold))
                                    Image(systemName: "arrow.right")
                                }
                                .foregroundColor(AppColors.buttonPrimaryText)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.buttonPrimary)
                                .cornerRadius(16)
                            }
                            .padding(.horizontal)
                            .padding(.top, 10)
                        }
                    }
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(timer) { _ in
                currentTime = Date()
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
}

// Carte d'humeur
struct MoodCard: View {
    let mood: Mood
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                action()
            }
        }) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(AppColors.buttonSecondary)
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: mood.icon)
                        .font(.system(size: 32))
                        .foregroundColor(AppColors.primaryText)
                }
                
                Text(mood.rawValue)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
            }
            .frame(height: 140)
            .frame(maxWidth: .infinity)
            .padding()
            .cleanCard(cornerRadius: 20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        isSelected ? AppColors.buttonPrimary : Color.clear,
                        lineWidth: 3
                    )
            )
            .background(
                isSelected ? AppColors.buttonSecondary : Color.clear
            )
            .shadow(
                color: isSelected ? AppColors.shadow : AppColors.shadow,
                radius: isSelected ? 10 : 5,
                x: 0,
                y: isSelected ? 5 : 2
            )
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

// Section météo
struct WeatherSection: View {
    @Binding var selectedWeather: WeatherType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Météo du jour")
                .font(.playfairDisplayBold(size: 22))
                .foregroundColor(AppColors.primaryText)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 15) {
                    ForEach(WeatherType.allCases, id: \.self) { weather in
                        WeatherChip(
                            weather: weather,
                            isSelected: selectedWeather == weather
                        ) {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedWeather = weather
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

// Puce météo
struct WeatherChip: View {
    let weather: WeatherType
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: weather.icon)
                    .font(.system(size: 16))
                Text(weather.rawValue)
                    .font(.system(size: 14, weight: .medium))
            }
            .foregroundColor(isSelected ? AppColors.buttonPrimaryText : AppColors.primaryText)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(isSelected ? AppColors.buttonPrimary : AppColors.buttonSecondary)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationStack {
        MoodSelectionScreen()
            .environmentObject(DataManager.shared)
    }
}

