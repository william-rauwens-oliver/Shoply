//
//  Outfit.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import SwiftUI
import Combine

// Enum pour les humeurs
enum Mood: String, CaseIterable, Identifiable {
    case energetic = "Energique"
    case calm = "Calme"
    case confident = "Confiant"
    case relaxed = "Détendu"
    case professional = "Professionnel"
    case creative = "Créatif"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .energetic: return "bolt.fill"
        case .calm: return "leaf.fill"
        case .confident: return "star.fill"
        case .relaxed: return "cloud.fill"
        case .professional: return "briefcase.fill"
        case .creative: return "paintbrush.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .energetic: return .orange
        case .calm: return .mint
        case .confident: return .yellow
        case .relaxed: return .blue
        case .professional: return .purple
        case .creative: return .pink
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .energetic: return Color(red: 1.0, green: 0.8, blue: 0.6)
        case .calm: return Color(red: 0.8, green: 1.0, blue: 0.9)
        case .confident: return Color(red: 1.0, green: 1.0, blue: 0.7)
        case .relaxed: return Color(red: 0.7, green: 0.9, blue: 1.0)
        case .professional: return Color(red: 0.9, green: 0.8, blue: 1.0)
        case .creative: return Color(red: 1.0, green: 0.8, blue: 0.9)
        }
    }
}

// Enum pour le type d'outfit
enum OutfitType: String, CaseIterable {
    case casual = "Décontracté"
    case business = "Business"
    case smartCasual = "Smart Casual"
    case formal = "Formel"
    case weekend = "Weekend"
}

// Enum pour la météo
enum WeatherType: String, CaseIterable {
    case sunny = "Ensoleillé"
    case cloudy = "Nuageux"
    case rainy = "Pluvieux"
    case cold = "Froid"
    case warm = "Chaud"
    
    var icon: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .cloudy: return "cloud.fill"
        case .rainy: return "cloud.rain.fill"
        case .cold: return "snowflake"
        case .warm: return "thermometer.sun.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .sunny: return .yellow
        case .cloudy: return .gray
        case .rainy: return .blue
        case .cold: return .cyan
        case .warm: return .orange
        }
    }
}

// Modèle d'outfit
struct Outfit: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let description: String
    let type: OutfitType
    let top: String
    let bottom: String
    let shoes: String
    let accessories: [String]
    let suitableMoods: [Mood]
    let suitableWeather: [WeatherType]
    let imageName: String
    let comfortLevel: Int // 1-5
    let styleLevel: Int // 1-5
    
    var isFavorite: Bool = false
}

// Service pour générer des outfits selon l'humeur et la météo
class OutfitService: ObservableObject {
    @Published var outfits: [Outfit] = []
    
    init() {
        loadDefaultOutfits()
    }
    
    func loadDefaultOutfits() {
        outfits = [
            // Outfits énergiques
            Outfit(
                name: "Look Dynamique",
                description: "Parfait pour une journée active et productive",
                type: .casual,
                top: "T-shirt coloré",
                bottom: "Jeans slim",
                shoes: "Sneakers confortables",
                accessories: ["Montre sport", "Casquette"],
                suitableMoods: [.energetic, .confident],
                suitableWeather: [.sunny, .warm],
                imageName: "outfit_energetic",
                comfortLevel: 5,
                styleLevel: 4
            ),
            // Outfits calmes
            Outfit(
                name: "Style Détendu",
                description: "Confortable et élégant pour une journée sereine",
                type: .smartCasual,
                top: "Polo doux",
                bottom: "Chinos beige",
                shoes: "Mocassins",
                accessories: ["Lunettes de soleil"],
                suitableMoods: [.calm, .relaxed],
                suitableWeather: [.sunny, .cloudy],
                imageName: "outfit_calm",
                comfortLevel: 5,
                styleLevel: 3
            ),
            // Outfits professionnels
            Outfit(
                name: "Ensemble Business",
                description: "Élégant et professionnel pour le bureau",
                type: .business,
                top: "Chemise blanche",
                bottom: "Pantalon de costume",
                shoes: "Chaussures de ville",
                accessories: ["Cravate", "Montre classique", "Ceinture"],
                suitableMoods: [.professional, .confident],
                suitableWeather: [.sunny, .cloudy, .cold],
                imageName: "outfit_professional",
                comfortLevel: 3,
                styleLevel: 5
            ),
            // Outfits créatifs
            Outfit(
                name: "Look Original",
                description: "Expressif et unique pour exprimer votre créativité",
                type: .casual,
                top: "T-shirt imprimé",
                bottom: "Jeans délavés",
                shoes: "Baskets vintage",
                accessories: ["Bracelets", "Sac à dos coloré"],
                suitableMoods: [.creative, .energetic],
                suitableWeather: [.sunny, .warm],
                imageName: "outfit_creative",
                comfortLevel: 4,
                styleLevel: 5
            ),
            // Outfits confiants
            Outfit(
                name: "Style Assertif",
                description: "Affirmez votre présence avec ce look impactant",
                type: .smartCasual,
                top: "Chemise boutonnée",
                bottom: "Pantalon chino",
                shoes: "Derbies",
                accessories: ["Montre élégante", "Ceinture cuir"],
                suitableMoods: [.confident, .professional],
                suitableWeather: [.sunny, .cloudy],
                imageName: "outfit_confident",
                comfortLevel: 4,
                styleLevel: 5
            ),
            // Outfits détendus
            Outfit(
                name: "Comfort Premium",
                description: "Le confort avant tout pour une journée zen",
                type: .weekend,
                top: "Sweat-shirt doux",
                bottom: "Jogging premium",
                shoes: "Sneakers confortables",
                accessories: ["Bonnet doux"],
                suitableMoods: [.relaxed, .calm],
                suitableWeather: [.cloudy, .cold],
                imageName: "outfit_relaxed",
                comfortLevel: 5,
                styleLevel: 3
            ),
            // Outfits pluvieux
            Outfit(
                name: "Protection Pluie",
                description: "Restez au sec et stylé même sous la pluie",
                type: .casual,
                top: "Veste imperméable",
                bottom: "Pantalon résistant à l'eau",
                shoes: "Bottines imperméables",
                accessories: ["Parapluie", "Sac étanche"],
                suitableMoods: [.energetic, .confident],
                suitableWeather: [.rainy, .cloudy],
                imageName: "outfit_rainy",
                comfortLevel: 4,
                styleLevel: 3
            ),
            // Outfits froids
            Outfit(
                name: "Cocooning Hiver",
                description: "Restez bien au chaud avec ce look hivernal",
                type: .casual,
                top: "Pull en laine",
                bottom: "Jean",
                shoes: "Bottes",
                accessories: ["Écharpe", "Gants", "Bonnet"],
                suitableMoods: [.calm, .relaxed],
                suitableWeather: [.cold, .cloudy],
                imageName: "outfit_cold",
                comfortLevel: 5,
                styleLevel: 4
            )
        ]
    }
    
    func getOutfitsFor(mood: Mood, weather: WeatherType) -> [Outfit] {
        return outfits.filter { outfit in
            outfit.suitableMoods.contains(mood) && outfit.suitableWeather.contains(weather)
        }
    }
    
    func getAllOutfitsFor(mood: Mood) -> [Outfit] {
        return outfits.filter { outfit in
            outfit.suitableMoods.contains(mood)
        }
    }
}

