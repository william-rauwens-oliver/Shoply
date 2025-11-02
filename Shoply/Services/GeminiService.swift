//
//  GeminiService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import Combine
import UIKit

/// Service d'intégration Google Gemini pour suggestions intelligentes
class GeminiService: ObservableObject {
    static let shared = GeminiService()
    
    // Clé API Gemini intégrée par défaut
    private var embeddedAPIKey = "AIzaSyBJToCQ-5iBa7-mTpkTXGjqY_ZbOeSUEaI"
    
    private var apiKey: String? {
        // Utiliser directement la clé API intégrée (plus de OAuth)
        // L'utilisateur peut toujours remplacer par sa propre clé
        if let storedKey = UserDefaults.standard.string(forKey: "gemini_api_key"),
           !storedKey.isEmpty {
            return storedKey
        }
        
        // Clé API intégrée par défaut
        return embeddedAPIKey
    }
    
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    @Published var isEnabled = false
    
    private init() {
        // Toujours activé car on a une clé API intégrée
        isEnabled = true
        reloadAPIKey()
    }
    
    // MARK: - Outfit Suggestions
    
    /// Génère des suggestions d'outfits intelligentes via Gemini avec analyse des photos
    func generateOutfitSuggestions(
        wardrobeItems: [WardrobeItem],
        weather: WeatherData,
        userProfile: UserProfile,
        progressCallback: ((Double) async -> Void)? = nil
    ) async throws -> [String] {
        guard !wardrobeItems.isEmpty else {
            throw GeminiError.noItems
        }
        
        guard let apiKey = apiKey, isEnabled else {
            throw GeminiError.apiKeyMissing
        }
        
        // Préparer les descriptions et images
        var itemsDescriptions: [String] = []
        var imageParts: [[String: Any]] = []
        
        await progressCallback?(0.1) // 10% - Début de préparation
        
        for (index, item) in wardrobeItems.enumerated() {
            var itemDesc = "- \(item.name) | Catégorie: \(item.category.rawValue) | Couleur: \(item.color)"
            
            if let material = item.material, !material.isEmpty {
                itemDesc += " | Matière: \(material)"
            }
            if !item.season.isEmpty {
                itemDesc += " | Saisons: \(item.season.map { $0.rawValue }.joined(separator: ", "))"
            }
            if item.isFavorite {
                itemDesc += " | ⭐ Favori"
            }
            
            itemsDescriptions.append(itemDesc)
            
            // Ajouter l'image si disponible
            if let photoURL = item.photoURL,
               let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                if let base64Image = imageToBase64(image) {
                    imageParts.append([
                        "inline_data": [
                            "mime_type": "image/jpeg",
                            "data": base64Image
                        ]
                    ])
                }
            }
            
            // Mettre à jour la progression
            if (index + 1) % max(1, wardrobeItems.count / 5) == 0 {
                let progress = 0.1 + (Double(index + 1) / Double(wardrobeItems.count)) * 0.3
                await progressCallback?(progress)
            }
        }
        
        await progressCallback?(0.4) // 40% - Préparation terminée
        
        let prompt = buildPrompt(
            itemsDescriptions: itemsDescriptions,
            weather: weather,
            userProfile: userProfile,
            hasImages: !imageParts.isEmpty,
            numberOfItems: wardrobeItems.count
        )
        
        // Construire le contenu pour Gemini (texte + images)
        var parts: [[String: Any]] = [
            ["text": prompt]
        ]
        
        // Ajouter les images
        parts.append(contentsOf: imageParts)
        
        // Utiliser gemini-2.5-flash (modèle actuel selon la documentation officielle)
        // Pour les images, gemini-2.5-flash supporte également les images
        let model = "gemini-2.5-flash"
        
        // Construire l'URL - utiliser la clé API intégrée ou stockée
        let urlString: String
        let useOAuth: Bool
        
        // Vérifier si une clé API est stockée par l'utilisateur, sinon utiliser la clé intégrée
        let apiKeyToUse: String
        if let storedAPIKey = UserDefaults.standard.string(forKey: "gemini_api_key"),
           !storedAPIKey.isEmpty {
            apiKeyToUse = storedAPIKey
        } else {
            // Utiliser la clé API intégrée par défaut
            apiKeyToUse = embeddedAPIKey
        }
        
        urlString = "https://generativelanguage.googleapis.com/v1beta/models/\(model):generateContent?key=\(apiKeyToUse)"
        useOAuth = false
        
        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": parts
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 800
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        await progressCallback?(0.5) // 50% - Envoi à Gemini...
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        await progressCallback?(0.7) // 70% - Gemini analyse...
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.apiError
        }
        
        guard httpResponse.statusCode == 200 else {
            // Essayer de décoder le message d'erreur de l'API
            var errorMessage = ""
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorInfo = errorData["error"] as? [String: Any],
               let message = errorInfo["message"] as? String {
                errorMessage = message
                print("❌ Gemini API Error (\(httpResponse.statusCode)): \(message)")
            } else if let dataString = String(data: data, encoding: .utf8) {
                errorMessage = "HTTP \(httpResponse.statusCode): \(dataString.prefix(200))"
                print("❌ Gemini API Error (\(httpResponse.statusCode)): \(dataString.prefix(200))")
            } else {
                errorMessage = "HTTP Error \(httpResponse.statusCode)"
                print("❌ Gemini API Error (\(httpResponse.statusCode))")
            }
            
            if !errorMessage.isEmpty {
                throw GeminiError.apiErrorWithMessage(errorMessage)
            } else {
                throw GeminiError.apiError
            }
        }
        
        await progressCallback?(0.8) // 80% - Parsing de la réponse
        
        let apiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let content = apiResponse.candidates.first?.content,
              let text = content.parts.compactMap({ $0.text }).first else {
            throw GeminiError.noResponse
        }
        
        await progressCallback?(0.85) // 85% - Contenu extrait
        
        // Parser les suggestions (format attendu: "Outfit X: ...")
        let suggestions = text.components(separatedBy: "\n")
            .filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return !trimmed.isEmpty && (trimmed.lowercased().contains("outfit") || trimmed.contains("+") || trimmed.first?.isNumber == true)
            }
            .map { line in
                // Nettoyer la ligne
                var cleaned = line.trimmingCharacters(in: .whitespaces)
                if let colonRange = cleaned.range(of: ":") {
                    cleaned = String(cleaned[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                }
                // Enlever les numéros en début de ligne
                while cleaned.first?.isNumber == true || cleaned.first == "." || cleaned.first == "-" {
                    cleaned = String(cleaned.dropFirst()).trimmingCharacters(in: .whitespaces)
                }
                return cleaned
            }
            .filter { !$0.isEmpty }
        
        await progressCallback?(0.95) // 95% - Parsing terminé
        
        let finalSuggestions = suggestions.isEmpty ? [text] : suggestions
        
        await progressCallback?(1.0) // 100% - Terminé
        
        return finalSuggestions
    }
    
    // MARK: - Construction du prompt
    
    private func buildPrompt(
        itemsDescriptions: [String],
        weather: WeatherData,
        userProfile: UserProfile,
        hasImages: Bool,
        numberOfItems: Int
    ) -> String {
        let itemsDescription = itemsDescriptions.joined(separator: "\n")
        
        let numberOfOutfits = min(5, max(1, numberOfItems))
        
        var prompt = """
        Analyse cette garde-robe et génère \(numberOfOutfits) outfit(s) parfaitement adapté(s).
        
        PROFIL UTILISATEUR:
        - Genre: \(userProfile.gender.rawValue) (IMPORTANT: Adapte les outfits à ce genre spécifique)
        - Âge: \(userProfile.age)
        
        CONDITIONS MÉTÉOROLOGIQUES D'AUJOURD'HUI:
        - Température: \(Int(weather.temperature))°C (IMPORTANT: Adapte les vêtements à cette température)
        - Conditions: \(weather.condition.rawValue) (IMPORTANT: Prends en compte cette condition météo)
        
        GARDE-ROBE DISPONIBLE:
        \(itemsDescription)
        """
        
        if hasImages {
            prompt += "\n\nIMPORTANT: Tu as accès aux photos réelles des vêtements ci-dessus. Analyse visuellement chaque vêtement pour mieux comprendre leur style, couleur, matière et coupe."
        }
        
        prompt += """
        
        INSTRUCTIONS CRITIQUES:
        1. Génère EXACTEMENT \(numberOfOutfits) suggestion(s) d'outfit(s) différent(s) et adapté(s)
        2. Chaque outfit doit inclure: un haut (obligatoire), un bas (obligatoire), des chaussures (obligatoire), et éventuellement des accessoires
        3. **ADAPTE CHAQUE OUTFIT AU GENRE** (\(userProfile.gender.rawValue)) - Les vêtements doivent être adaptés à ce genre spécifique
        4. **ADAPTE CHAQUE OUTFIT À LA MÉTÉO** (\(Int(weather.temperature))°C, \(weather.condition.rawValue)) - Les vêtements doivent être adaptés à cette température et condition météo
        5. Utilise UNIQUEMENT les vêtements listés ci-dessus
        6. Si tu as peu d'articles, tu peux réutiliser certains vêtements dans différents outfits mais varie les combinaisons
        7. Réponds UNIQUEMENT avec les \(numberOfOutfits) suggestion(s), une par ligne, format:
           Outfit 1: [nom exact du haut] + [nom exact du bas] + [nom exact des chaussures] + [accessoires optionnels]
           Outfit 2: [nom exact du haut] + [nom exact du bas] + [nom exact des chaussures] + [accessoires optionnels]
           ...
        """
        
        return prompt
    }
    
    // MARK: - Conversion image en base64
    
    private func imageToBase64(_ image: UIImage) -> String? {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            return nil
        }
        return imageData.base64EncodedString()
    }
    
    // MARK: - Chat Conversation
    
    /// Répond à une question de l'utilisateur concernant les vêtements, outfits, météo, etc.
    func askAboutClothing(
        question: String,
        userProfile: UserProfile,
        currentWeather: WeatherData?,
        wardrobeItems: [WardrobeItem]
    ) async throws -> String {
        guard let apiKey = apiKey, isEnabled else {
            throw GeminiError.apiKeyMissing
        }
        
        // Construire le contexte
        var contextPrompt = """
        Tu es un assistant intelligent et utile. Tu peux répondre à toutes sortes de questions sur n'importe quel sujet. Réponds librement et de manière naturelle à ce que l'utilisateur te demande.
        
        PROFIL UTILISATEUR (informations optionnelles si la question concerne la mode):
        - Genre: \(userProfile.gender.rawValue)
        - Âge: \(userProfile.age)
        """
        
        if let weather = currentWeather {
            contextPrompt += """
            
            MÉTÉO ACTUELLE (informations optionnelles si la question concerne la mode ou la météo):
            - Température: \(Int(weather.temperature))°C
            - Conditions: \(weather.condition.rawValue)
            """
        }
        
        if !wardrobeItems.isEmpty {
            let itemsDescription = wardrobeItems.prefix(10).map { item in
                "- \(item.name) (\(item.category.rawValue), \(item.color))"
            }.joined(separator: "\n")
            
            contextPrompt += """
            
            GARDE-ROBE DE L'UTILISATEUR (informations optionnelles, utilise seulement si la question concerne la mode):
            \(itemsDescription)
            """
        }
        
        contextPrompt += """
        
        QUESTION DE L'UTILISATEUR:
        \(question)
        
        INSTRUCTIONS:
        1. Réponds librement à la question de l'utilisateur, quelle qu'elle soit
        2. N'aie aucune restriction de sujet - tu peux parler de tout
        3. Sois naturel, amical et utile dans ta réponse
        4. Si la question concerne la mode/vêtements, utilise les informations du profil et de la météo si pertinentes
        5. Si la question concerne un autre sujet, réponds simplement et librement sans te limiter
        6. Réponds de manière concise mais complète (maximum 300 mots)
        """
        
        // Utiliser gemini-2.5-flash avec v1beta selon la documentation officielle
        // Construire l'URL - utiliser la clé API intégrée ou stockée
        let urlString: String
        let useOAuth: Bool
        
        // Vérifier si une clé API est stockée par l'utilisateur, sinon utiliser la clé intégrée
        let apiKeyToUse: String
        if let storedAPIKey = UserDefaults.standard.string(forKey: "gemini_api_key"),
           !storedAPIKey.isEmpty {
            apiKeyToUse = storedAPIKey
        } else {
            // Utiliser la clé API intégrée par défaut
            apiKeyToUse = embeddedAPIKey
        }
        
        urlString = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=\(apiKeyToUse)"
        useOAuth = false
        
        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": contextPrompt
                        ]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 300
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.apiError
        }
        
        guard httpResponse.statusCode == 200 else {
            // Essayer de décoder le message d'erreur de l'API
            var errorMessage = ""
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorInfo = errorData["error"] as? [String: Any],
               let message = errorInfo["message"] as? String {
                errorMessage = message
                print("❌ Gemini API Error (\(httpResponse.statusCode)): \(message)")
            } else if let dataString = String(data: data, encoding: .utf8) {
                errorMessage = "HTTP \(httpResponse.statusCode): \(dataString.prefix(200))"
                print("❌ Gemini API Error (\(httpResponse.statusCode)): \(dataString.prefix(200))")
            } else {
                errorMessage = "HTTP Error \(httpResponse.statusCode)"
                print("❌ Gemini API Error (\(httpResponse.statusCode))")
            }
            
            if !errorMessage.isEmpty {
                throw GeminiError.apiErrorWithMessage(errorMessage)
            } else {
                throw GeminiError.apiError
            }
        }
        
        let apiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let content = apiResponse.candidates.first?.content,
              let text = content.parts.first?.text else {
            throw GeminiError.noResponse
        }
        
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    // MARK: - Configuration
    
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "gemini_api_key")
        reloadAPIKey()
    }
    
    func reloadAPIKey() {
        // Toujours activé car on a une clé API intégrée par défaut
        self.isEnabled = true
        self.objectWillChange.send()
    }
}

// MARK: - Models API Gemini

struct GeminiResponse: Codable {
    let candidates: [GeminiCandidate]
}

struct GeminiCandidate: Codable {
    let content: GeminiContent
}

struct GeminiContent: Codable {
    let parts: [GeminiPart]
}

struct GeminiPart: Codable {
    let text: String?
    
    enum CodingKeys: String, CodingKey {
        case text
        case inlineData = "inline_data"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        text = try container.decodeIfPresent(String.self, forKey: .text)
        // Ignorer inline_data pour l'instant
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(text, forKey: .text)
    }
}

enum GeminiError: Error {
    case apiKeyMissing
    case invalidURL
    case apiError
    case apiErrorWithMessage(String)
    case noResponse
    case noItems
}

