//
//  Outfit.swift
//  ShoplyCore - Android Compatible
//
//  Created by William on 02/11/2025.
//

import Foundation

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
}

// Modèle d'outfit
struct Outfit: Identifiable, Hashable, Codable {
    let id: UUID
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
    
    init(
        id: UUID = UUID(),
        name: String,
        description: String,
        type: OutfitType,
        top: String,
        bottom: String,
        shoes: String,
        accessories: [String] = [],
        suitableMoods: [Mood],
        suitableWeather: [WeatherType],
        imageName: String,
        comfortLevel: Int,
        styleLevel: Int,
        isFavorite: Bool = false
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.type = type
        self.top = top
        self.bottom = bottom
        self.shoes = shoes
        self.accessories = accessories
        self.suitableMoods = suitableMoods
        self.suitableWeather = suitableWeather
        self.imageName = imageName
        self.comfortLevel = comfortLevel
        self.styleLevel = styleLevel
        self.isFavorite = isFavorite
    }
}

