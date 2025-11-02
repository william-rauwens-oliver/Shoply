//
//  FoodModels.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//
//  Modèles pour la reconnaissance d'aliments et génération de recettes

import Foundation

/// Modèle représentant un aliment détecté
struct FoodItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let confidence: Double // 0.0 à 1.0
    let category: FoodCategory
    let quantity: String? // Quantité estimée (optionnel)
    
    init(id: UUID = UUID(), name: String, confidence: Double, category: FoodCategory, quantity: String? = nil) {
        self.id = id
        self.name = name
        self.confidence = confidence
        self.category = category
        self.quantity = quantity
    }
}

/// Catégorie d'aliment
enum FoodCategory: String, Codable, CaseIterable {
    case vegetable = "Légume"
    case fruit = "Fruit"
    case meat = "Viande"
    case dairy = "Produit laitier"
    case grain = "Céréale/Farine"
    case spice = "Épice/Assaisonnement"
    case other = "Autre"
    
    var icon: String {
        switch self {
        case .vegetable: return "🥬"
        case .fruit: return "🍎"
        case .meat: return "🥩"
        case .dairy: return "🥛"
        case .grain: return "🌾"
        case .spice: return "🧂"
        case .other: return "🍽️"
        }
    }
}

/// Modèle représentant une recette générée
struct Recipe: Identifiable, Codable {
    let id: UUID
    let name: String
    let description: String
    let ingredients: [String]
    let instructions: [String]
    let prepTime: String? // Temps de préparation (ex: "15 min")
    let cookTime: String? // Temps de cuisson (ex: "30 min")
    let servings: Int?
    let difficulty: RecipeDifficulty
    let createdAt: Date
    
    init(id: UUID = UUID(), name: String, description: String, ingredients: [String], instructions: [String], prepTime: String? = nil, cookTime: String? = nil, servings: Int? = nil, difficulty: RecipeDifficulty = .medium) {
        self.id = id
        self.name = name
        self.description = description
        self.ingredients = ingredients
        self.instructions = instructions
        self.prepTime = prepTime
        self.cookTime = cookTime
        self.servings = servings
        self.difficulty = difficulty
        self.createdAt = Date()
    }
}

/// Niveau de difficulté d'une recette
enum RecipeDifficulty: String, Codable, CaseIterable {
    case easy = "Facile"
    case medium = "Moyen"
    case hard = "Difficile"
    
    var icon: String {
        switch self {
        case .easy: return "⭐"
        case .medium: return "⭐⭐"
        case .hard: return "⭐⭐⭐"
        }
    }
}

