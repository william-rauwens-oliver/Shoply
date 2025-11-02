//
//  RecipeGenerationService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//
//  Service pour générer des recettes à partir d'ingrédients

import Foundation
import Combine

class RecipeGenerationService: ObservableObject {
    static let shared = RecipeGenerationService()
    
    private let geminiService = GeminiService.shared
    private let intelligentLocalAI = IntelligentLocalAI.shared
    
    private init() {}
    
    /// Générer une recette à partir d'une liste d'ingrédients
    func generateRecipe(from ingredients: [FoodItem]) async throws -> Recipe {
        let ingredientsList = ingredients.map { $0.name }.joined(separator: ", ")
        
        let prompt = """
        Génère une recette rapide et délicieuse avec les ingrédients suivants :
        \(ingredientsList)
        
        Réponds UNIQUEMENT avec un JSON au format suivant (sans autre texte) :
        {
          "name": "Nom de la recette",
          "description": "Courte description",
          "ingredients": ["ingrédient 1", "ingrédient 2", ...],
          "instructions": ["Étape 1", "Étape 2", ...],
          "prepTime": "15 min",
          "cookTime": "30 min",
          "servings": 4,
          "difficulty": "Facile|Moyen|Difficile"
        }
        """
        
        // Utiliser Gemini, puis Shoply AI en fallback
        if geminiService.isEnabled {
            return try await generateRecipeWithGemini(prompt: prompt)
        } else {
            return try await generateRecipeWithLocalAI(prompt: prompt, ingredients: ingredients)
        }
    }
    
    /// Générer une recette avec Gemini
    private func generateRecipeWithGemini(prompt: String) async throws -> Recipe {
        // Clé API Gemini intégrée par défaut
        let embeddedAPIKey = "AIzaSyBJToCQ-5iBa7-mTpkTXGjqY_ZbOeSUEaI"
        
        var token: String?
        
        // Essayer OAuth d'abord
        if GeminiOAuthService.shared.isAuthenticated,
           let oauthToken = GeminiOAuthService.shared.accessToken,
           !oauthToken.isEmpty {
            token = oauthToken
        } else if let storedKey = UserDefaults.standard.string(forKey: "gemini_api_key"),
                   !storedKey.isEmpty {
            token = storedKey
        } else {
            // Utiliser la clé API intégrée par défaut
            token = embeddedAPIKey
        }
        
        guard let token = token else {
            throw RecipeGenerationError.generationFailed
        }
        
        let model = "gemini-2.5-flash-latest"
        var urlString: String
        var useOAuth = false
        
        if GeminiOAuthService.shared.isAuthenticated,
           let oauthToken = GeminiOAuthService.shared.accessToken,
           !oauthToken.isEmpty {
            urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent"
            useOAuth = true
        } else {
            urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(token)"
        }
        
        guard let url = URL(string: urlString) else {
            throw RecipeGenerationError.generationFailed
        }
        
        let requestBody: [String: Any] = [
            "contents": [["parts": [["text": prompt]]]],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 2000
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if useOAuth {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw RecipeGenerationError.generationFailed
        }
        
        struct GeminiResponse: Codable {
            let candidates: [Candidate]
            struct Candidate: Codable {
                let content: Content
                struct Content: Codable {
                    let parts: [Part]
                    struct Part: Codable {
                        let text: String?
                    }
                }
            }
        }
        
        let apiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        guard let text = apiResponse.candidates.first?.content.parts.compactMap({ $0.text }).first else {
            throw RecipeGenerationError.invalidResponse
        }
        
        return try parseRecipeFromJSON(text)
    }
    
    
    /// Générer une recette avec Shoply AI (fallback)
    private func generateRecipeWithLocalAI(prompt: String, ingredients: [FoodItem]) async throws -> Recipe {
        // Générer une recette basique avec Shoply AI
        let ingredientsList = ingredients.map { $0.name }.joined(separator: ", ")
        
        let recipeName = generateBasicRecipeName(from: ingredients)
        let description = "Recette rapide avec \(ingredientsList)"
        let instructions = generateBasicInstructions(from: ingredients)
        
        return Recipe(
            name: recipeName,
            description: description,
            ingredients: ingredients.map { $0.name },
            instructions: instructions,
            prepTime: "10 min",
            cookTime: "20 min",
            servings: 2,
            difficulty: .easy
        )
    }
    
    /// Parser la réponse JSON d'une recette
    private func parseRecipeFromJSON(_ jsonString: String) throws -> Recipe {
        // Nettoyer la réponse
        var cleanJSON = jsonString.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Supprimer les blocs de code markdown si présents
        if cleanJSON.hasPrefix("```json") {
            cleanJSON = String(cleanJSON.dropFirst(7))
        }
        if cleanJSON.hasPrefix("```") {
            cleanJSON = String(cleanJSON.dropFirst(3))
        }
        if cleanJSON.hasSuffix("```") {
            cleanJSON = String(cleanJSON.dropLast(3))
        }
        cleanJSON = cleanJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let data = cleanJSON.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let name = json["name"] as? String,
              let description = json["description"] as? String,
              let ingredients = json["ingredients"] as? [String],
              let instructions = json["instructions"] as? [String] else {
            throw RecipeGenerationError.invalidResponse
        }
        
        let prepTime = json["prepTime"] as? String
        let cookTime = json["cookTime"] as? String
        let servings = json["servings"] as? Int
        let difficultyString = (json["difficulty"] as? String) ?? "Moyen"
        let difficulty = RecipeDifficulty(rawValue: difficultyString) ?? .medium
        
        return Recipe(
            name: name,
            description: description,
            ingredients: ingredients,
            instructions: instructions,
            prepTime: prepTime,
            cookTime: cookTime,
            servings: servings,
            difficulty: difficulty
        )
    }
    
    /// Générer un nom de recette basique
    private func generateBasicRecipeName(from ingredients: [FoodItem]) -> String {
        let mainIngredient = ingredients.first?.name ?? "Ingrédients"
        return "Recette rapide avec \(mainIngredient)"
    }
    
    /// Générer des instructions basiques
    private func generateBasicInstructions(from ingredients: [FoodItem]) -> [String] {
        return [
            "Préparer tous les ingrédients",
            "Mélanger les ingrédients selon vos préférences",
            "Cuire ou assaisonner selon vos goûts",
            "Servir et déguster"
        ]
    }
}

enum RecipeGenerationError: LocalizedError {
    case invalidResponse
    case generationFailed
    case noIngredients
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "La réponse de l'IA n'est pas valide.".localized
        case .generationFailed:
            return "La génération de la recette a échoué.".localized
        case .noIngredients:
            return "Aucun ingrédient fourni.".localized
        }
    }
}

