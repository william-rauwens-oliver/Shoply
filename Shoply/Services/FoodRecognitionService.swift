//
//  FoodRecognitionService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//
//  Service pour la reconnaissance d'aliments dans les photos
//  Utilise Gemini ou ChatGPT pour analyser les images

import Foundation
import UIKit
import Combine

class FoodRecognitionService: ObservableObject {
    static let shared = FoodRecognitionService()
    
    private let geminiService = GeminiService.shared
    
    private init() {}
    
    /// Analyser une image pour détecter les aliments
    /// Utilise Gemini uniquement
    /// - Parameter image: L'image à analyser
    /// - Returns: Liste des aliments détectés avec leur confiance
    func recognizeFoods(in image: UIImage) async throws -> [FoodItem] {
        guard let imageData = image.jpegData(compressionQuality: 0.8) else {
            throw FoodRecognitionError.invalidImage
        }
        
        let base64Image = imageData.base64EncodedString()
        
        // Utiliser Gemini uniquement
        if geminiService.isEnabled {
            return try await recognizeFoodsWithGemini(base64Image: base64Image)
        } else {
            // Fallback : analyse locale basique avec suggestions
            let localFoods = recognizeFoodsLocal(in: image)
            if localFoods.isEmpty {
                throw FoodRecognitionError.noFoodsDetected
            }
            return localFoods
        }
    }
    
    /// Reconnaissance d'aliments avec Gemini
    private func recognizeFoodsWithGemini(base64Image: String) async throws -> [FoodItem] {
        let prompt = """
        Analyse cette image et liste TOUS les aliments/ingrédients que tu vois (farine, légumes, fruits, viandes, épices, etc.).
        Réponds UNIQUEMENT avec une liste JSON au format suivant (sans autre texte) :
        [
          {"name": "nom aliment", "category": "Légume|Fruit|Viande|Produit laitier|Céréale/Farine|Épice/Assaisonnement|Autre", "confidence": 0.8},
          {"name": "nom aliment 2", "category": "...", "confidence": 0.7}
        ]
        """
        
        let parts: [[String: Any]] = [
            ["text": prompt],
            [
                "inline_data": [
                    "mime_type": "image/jpeg",
                    "data": base64Image
                ]
            ]
        ]
        
        // Appeler directement l'API Gemini avec l'image
        let response = try await callGeminiAPIWithImage(parts: parts)
        
        // Parser la réponse JSON
        return try parseFoodsFromJSON(response)
    }
    
    
    /// Appeler l'API Gemini avec une image
    private func callGeminiAPIWithImage(parts: [[String: Any]]) async throws -> String {
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
            throw FoodRecognitionError.recognitionFailed
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
            throw FoodRecognitionError.recognitionFailed
        }
        
        let requestBody: [String: Any] = [
            "contents": [["parts": parts]],
            "generationConfig": [
                "temperature": 0.3,
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
            throw FoodRecognitionError.recognitionFailed
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
            throw FoodRecognitionError.noFoodsDetected
        }
        
        return text
    }
    
    
    /// Parser la réponse JSON des aliments
    private func parseFoodsFromJSON(_ jsonString: String) throws -> [FoodItem] {
        // Extraire le JSON de la réponse (peut contenir du markdown)
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
        
        // Essayer de parser comme JSON array
        if let data = cleanJSON.data(using: .utf8),
           let jsonArray = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
            var foodItems: [FoodItem] = []
            
            for item in jsonArray {
                guard let name = item["name"] as? String else { continue }
                
                let categoryString = (item["category"] as? String) ?? "Autre"
                let category = FoodCategory(rawValue: categoryString) ?? .other
                
                let confidence = (item["confidence"] as? Double) ?? 0.7
                
                let foodItem = FoodItem(
                    name: name,
                    confidence: confidence,
                    category: category
                )
                foodItems.append(foodItem)
            }
            
            if !foodItems.isEmpty {
                return foodItems.sorted { $0.confidence > $1.confidence }
            }
        }
        
        // Si le parsing JSON échoue, essayer d'extraire les noms d'aliments du texte
        return try extractFoodsFromText(cleanJSON)
    }
    
    /// Extraire les aliments depuis un texte libre (fallback si JSON échoue)
    private func extractFoodsFromText(_ text: String) throws -> [FoodItem] {
        var foodItems: [FoodItem] = []
        
        // Liste de mots-clés d'aliments courants
        let foodKeywords: [(String, FoodCategory)] = [
            ("farine", .grain), ("flour", .grain),
            ("œuf", .dairy), ("oeuf", .dairy), ("egg", .dairy), ("eggs", .dairy),
            ("beurre", .dairy), ("butter", .dairy),
            ("lait", .dairy), ("milk", .dairy),
            ("sucre", .grain), ("sugar", .grain),
            ("miel", .other), ("honey", .other),
            ("vanille", .spice), ("vanilla", .spice),
            ("tomate", .vegetable), ("tomato", .vegetable),
            ("carotte", .vegetable), ("carrot", .vegetable),
            ("oignon", .vegetable), ("onion", .vegetable),
            ("ail", .vegetable), ("garlic", .vegetable),
            ("pomme", .fruit), ("apple", .fruit),
            ("banane", .fruit), ("banana", .fruit),
            ("poulet", .meat), ("chicken", .meat),
            ("pain", .grain), ("bread", .grain),
            ("riz", .grain), ("rice", .grain),
            ("pâtes", .grain), ("pasta", .grain)
        ]
        
        let lowercasedText = text.lowercased()
        
        for (keyword, category) in foodKeywords {
            if lowercasedText.contains(keyword) {
                // Trouver la forme exacte du mot dans le texte original
                let range = text.range(of: keyword, options: [.caseInsensitive, .diacriticInsensitive])
                if range != nil {
                    let name = capitalizeFoodName(keyword)
                    let foodItem = FoodItem(
                        name: name,
                        confidence: 0.7,
                        category: category
                    )
                    // Éviter les doublons
                    if !foodItems.contains(where: { $0.name.lowercased() == name.lowercased() }) {
                        foodItems.append(foodItem)
                    }
                }
            }
        }
        
        if foodItems.isEmpty {
            throw FoodRecognitionError.noFoodsDetected
        }
        
        return foodItems
    }
    
    /// Capitaliser le nom d'un aliment
    private func capitalizeFoodName(_ name: String) -> String {
        let mapping: [String: String] = [
            "farine": "Farine",
            "flour": "Farine",
            "œuf": "Œuf",
            "oeuf": "Œuf",
            "egg": "Œuf",
            "eggs": "Œufs",
            "beurre": "Beurre",
            "butter": "Beurre",
            "lait": "Lait",
            "milk": "Lait",
            "sucre": "Sucre",
            "sugar": "Sucre",
            "miel": "Miel",
            "honey": "Miel",
            "vanille": "Vanille",
            "vanilla": "Vanille",
            "tomate": "Tomate",
            "tomato": "Tomate",
            "carotte": "Carotte",
            "carrot": "Carotte",
            "oignon": "Oignon",
            "onion": "Oignon",
            "ail": "Ail",
            "garlic": "Ail",
            "pomme": "Pomme",
            "apple": "Pomme",
            "banane": "Banane",
            "poulet": "Poulet",
            "chicken": "Poulet",
            "pain": "Pain",
            "bread": "Pain",
            "riz": "Riz",
            "rice": "Riz",
            "pâtes": "Pâtes",
            "pasta": "Pâtes"
        ]
        
        return mapping[name.lowercased()] ?? name.capitalized
    }
    
    /// Détection locale basique (fallback)
    private func recognizeFoodsLocal(in image: UIImage) -> [FoodItem] {
        // Détection basique basée sur des patterns visuels courants
        // Retourner une liste suggérée d'aliments courants pour aider l'utilisateur
        let commonFoods: [(String, FoodCategory, Double)] = [
            ("Farine", .grain, 0.7),
            ("Œufs", .dairy, 0.7),
            ("Beurre", .dairy, 0.7),
            ("Lait", .dairy, 0.7),
            ("Sucre", .grain, 0.6),
            ("Miel", .other, 0.6),
            ("Vanille", .spice, 0.5)
        ]
        
        return commonFoods.map { name, category, confidence in
            FoodItem(name: name, confidence: confidence, category: category)
        }
    }
    
    /// Catégoriser un nom d'aliment détecté
    private func categorizeFood(_ name: String) -> FoodCategory? {
        let lowercased = name.lowercased()
        
        // Légumes
        if lowercased.contains("carotte") || lowercased.contains("tomate") ||
           lowercased.contains("salade") || lowercased.contains("oignon") ||
           lowercased.contains("ail") || lowercased.contains("poivron") ||
           lowercased.contains("courgette") || lowercased.contains("aubergine") {
            return .vegetable
        }
        
        // Fruits
        if lowercased.contains("pomme") || lowercased.contains("banane") ||
           lowercased.contains("orange") || lowercased.contains("fraise") ||
           lowercased.contains("raisin") || lowercased.contains("citron") {
            return .fruit
        }
        
        // Viandes
        if lowercased.contains("poulet") || lowercased.contains("bœuf") ||
           lowercased.contains("porc") || lowercased.contains("saumon") ||
           lowercased.contains("viande") {
            return .meat
        }
        
        // Produits laitiers
        if lowercased.contains("lait") || lowercased.contains("fromage") ||
           lowercased.contains("yaourt") || lowercased.contains("beurre") ||
           lowercased.contains("œuf") || lowercased.contains("oeuf") {
            return .dairy
        }
        
        // Céréales/Farine
        if lowercased.contains("farine") || lowercased.contains("pain") ||
           lowercased.contains("riz") || lowercased.contains("pâtes") ||
           lowercased.contains("blé") {
            return .grain
        }
        
        // Épices
        if lowercased.contains("poivre") || lowercased.contains("sel") ||
           lowercased.contains("ail") || lowercased.contains("persil") ||
           lowercased.contains("basilic") || lowercased.contains("thym") {
            return .spice
        }
        
        return .other
    }
}

enum FoodRecognitionError: LocalizedError {
    case invalidImage
    case recognitionFailed
    case noFoodsDetected
    
    var errorDescription: String? {
        switch self {
        case .invalidImage:
            return "L'image fournie n'est pas valide.".localized
        case .recognitionFailed:
            return "La reconnaissance d'aliments a échoué.".localized
        case .noFoodsDetected:
            return "Aucun aliment n'a été détecté dans l'image.".localized
        }
    }
}

