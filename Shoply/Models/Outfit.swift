//
//  Outfit.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import SwiftUI
import Combine
import CoreData

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

// NOTE: OutfitService a été déplacé dans Services/OutfitService.swift
// pour respecter l'architecture multicouche

