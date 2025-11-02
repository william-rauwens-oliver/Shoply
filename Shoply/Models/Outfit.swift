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
    let suitableWeather: [WeatherType]
    let imageName: String
    let comfortLevel: Int // 1-5
    let styleLevel: Int // 1-5
    
    var isFavorite: Bool = false
}

// NOTE: OutfitService a été déplacé dans Services/OutfitService.swift
// pour respecter l'architecture multicouche

