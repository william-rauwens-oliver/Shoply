//
//  OpenAIService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import Combine
import UIKit

/// Service d'intégration OpenAI pour suggestions intelligentes
/// OPTIONNEL - Peut être désactivé si pas de clé API
class OpenAIService: ObservableObject {
    static let shared = OpenAIService()
    
    // Plus de clé API intégrée - uniquement OAuth
    private var apiKey: String? {
        // Uniquement OAuth - l'utilisateur doit se connecter à son compte
        if let oauthToken = OpenAIOAuthService.shared.accessToken,
           !oauthToken.isEmpty,
           oauthToken != "oauth_session_active",
           oauthToken != "authenticated_session" {
            // Si c'est un token OAuth valide, l'utiliser
            return oauthToken
        }
        
        // Si l'utilisateur est authentifié mais n'a pas encore de token API,
        // on peut utiliser une clé API stockée de sa session précédente
        if OpenAIOAuthService.shared.isAuthenticated {
            return UserDefaults.standard.string(forKey: "openai_api_key")
        }
        
        return nil
    }
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    @Published var isEnabled = false
    
    private init() {
        // Charger et activer la clé API au démarrage
        reloadAPIKey()
        
        // Vérifier aussi si OAuth est disponible
        checkOAuthStatus()
    }
    
    private func checkOAuthStatus() {
        // Vérifier si l'utilisateur est authentifié via OAuth
        if OpenAIOAuthService.shared.isAuthenticated,
           let token = OpenAIOAuthService.shared.accessToken,
           !token.isEmpty,
           token != "oauth_session_active",
           token != "authenticated_session" {
            // Si un token OAuth valide existe, activer le service
            DispatchQueue.main.async {
                self.isEnabled = true
            }
        } else if OpenAIOAuthService.shared.isAuthenticated {
            // Si authentifié mais pas de token valide, vérifier si une clé API est stockée
            if UserDefaults.standard.string(forKey: "openai_api_key") != nil {
                DispatchQueue.main.async {
                    self.isEnabled = true
                }
            }
        }
    }
    
    // MARK: - Suggestions intelligentes
    
    /// Génère des suggestions d'outfits intelligentes via GPT avec analyse des photos
    /// Envoie TOUTES les images et TOUTES les descriptions à ChatGPT
    func generateOutfitSuggestions(
        wardrobeItems: [WardrobeItem],
        weather: WeatherData,
        userProfile: UserProfile,
        progressCallback: ((Double) async -> Void)? = nil
    ) async throws -> [String] {
        guard !wardrobeItems.isEmpty else {
            throw OpenAIError.noItems
        }
        
        guard let apiKey = apiKey, isEnabled else {
            throw OpenAIError.apiKeyMissing
        }
        
        // Préparer TOUTES les images en base64 pour Vision API + TOUTES les descriptions
        var imageContents: [[String: Any]] = []
        var itemsDescriptions: [String] = []
        
        // Utiliser TOUS les items (pas de limite à 20) - Envoyer tout à ChatGPT
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
                    imageContents.append([
                        "type": "image_url",
                        "image_url": [
                            "url": "data:image/jpeg;base64,\(base64Image)"
                        ]
                    ])
                }
            }
            
            // Mettre à jour la progression pendant la préparation (jusqu'à 40%)
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
            hasImages: !imageContents.isEmpty,
            numberOfItems: wardrobeItems.count
        )
        
        // Construire les messages avec images si disponibles
        var userMessage: [String: Any] = [
            "role": "user",
            "content": []
        ]
        
        // Ajouter le texte du prompt
        var contentArray: [[String: Any]] = [
            [
                "type": "text",
                "text": prompt
            ]
        ]
        
        // Ajouter les images si disponibles (Vision API)
        if !imageContents.isEmpty {
            contentArray.append(contentsOf: imageContents)
            // Utiliser GPT-4 Vision si on a des images
        }
        
        userMessage["content"] = contentArray
        
        let model = !imageContents.isEmpty ? "gpt-4o" : "gpt-4o-mini"
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                [
                    "role": "system",
                    "content": "Tu es un expert en mode et stylisme. Tu dois générer des outfits adaptés au GENRE de l'utilisateur et à la MÉTÉO d'aujourd'hui. Analyse cette garde-robe et génère des outfits parfaitement adaptés."
                ],
                userMessage
            ],
            "temperature": 0.7,
            "max_tokens": 800
        ]
        
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        await progressCallback?(0.5) // 50% - Envoi à ChatGPT...
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        await progressCallback?(0.7) // 70% - ChatGPT analyse...
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw OpenAIError.apiError
        }
        
        await progressCallback?(0.8) // 80% - Parsing de la réponse
        
        let apiResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        // Pour les réponses avec Vision API, le contenu peut être dans un format différent
        guard let choice = apiResponse.choices.first else {
            throw OpenAIError.noResponse
        }
        
        // Extraire le contenu texte
        let content = choice.message.content
        
        await progressCallback?(0.85) // 85% - Contenu extrait
        
        // Parser les suggestions (format attendu: "Outfit X: ...")
        let suggestions = content.components(separatedBy: "\n")
            .filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return !trimmed.isEmpty && (trimmed.lowercased().contains("outfit") || trimmed.contains("+") || trimmed.first?.isNumber == true)
            }
            .map { line in
                // Nettoyer la ligne (enlever "Outfit X:", "1.", etc.)
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
        
        let finalSuggestions = suggestions.isEmpty ? [content] : suggestions
        
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
        
        // Calculer le nombre d'outfits possibles (selon le nombre d'articles)
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
            throw OpenAIError.apiKeyMissing
        }
        
        // Construire le contexte
        var contextPrompt = """
        Tu es un assistant intelligent et utile pour l'application Shoply. Tu peux répondre à toutes sortes de questions, avec une expertise particulière en mode, stylisme et conseils vestimentaires.
        
        PROFIL UTILISATEUR:
        - Genre: \(userProfile.gender.rawValue)
        - Âge: \(userProfile.age)
        """
        
        if let weather = currentWeather {
            contextPrompt += """
            
            MÉTÉO ACTUELLE:
            - Température: \(Int(weather.temperature))°C
            - Conditions: \(weather.condition.rawValue)
            """
        }
        
        if !wardrobeItems.isEmpty {
            let itemsDescription = wardrobeItems.prefix(10).map { item in
                "- \(item.name) (\(item.category.rawValue), \(item.color))"
            }.joined(separator: "\n")
            
            contextPrompt += """
            
            GARDE-ROBE DE L'UTILISATEUR (échantillon):
            \(itemsDescription)
            """
        }
        
        contextPrompt += """
        
        QUESTION DE L'UTILISATEUR:
        \(question)
        
        INSTRUCTIONS:
        1. Réponds de manière concise et amicale (maximum 200 mots)
        2. Réponds à la question de l'utilisateur de manière naturelle et utile
        3. Si la question concerne les vêtements, outfits, mode ou style, utilise les informations du profil utilisateur et de la météo
        4. Sois pratique et donne des conseils actionnables quand c'est pertinent
        5. Si tu peux aider avec la question, réponds directement sans restrictions
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                [
                    "role": "system",
                    "content": contextPrompt
                ],
                [
                    "role": "user",
                    "content": question
                ]
            ],
            "temperature": 0.7,
            "max_tokens": 300
        ]
        
        guard let url = URL(string: baseURL) else {
            throw OpenAIError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.apiError
        }
        
        // Vérifier le code de statut HTTP
        guard httpResponse.statusCode == 200 else {
            // Essayer de parser le message d'erreur de l'API
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorInfo = errorData["error"] as? [String: Any],
               let errorMessage = errorInfo["message"] as? String {
                print("❌ Erreur OpenAI API: \(errorMessage) (Code: \(httpResponse.statusCode))")
                throw OpenAIError.apiErrorWithMessage(errorMessage)
            } else {
                print("❌ Erreur OpenAI API: Code \(httpResponse.statusCode)")
                if httpResponse.statusCode == 401 {
                    throw OpenAIError.apiKeyInvalid
                } else if httpResponse.statusCode == 429 {
                    throw OpenAIError.rateLimitExceeded
                } else {
                    throw OpenAIError.apiError
                }
            }
        }
        
        // Décoder la réponse de l'API
        do {
            let apiResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
            
            guard let choice = apiResponse.choices.first else {
                print("⚠️ Aucune réponse dans les choix de l'API")
                throw OpenAIError.noResponse
            }
            
            let content = choice.message.content.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Vérifier que le contenu n'est pas vide
            guard !content.isEmpty else {
                print("⚠️ Réponse vide de l'API")
                throw OpenAIError.noResponse
            }
            
            print("✅ Réponse ChatGPT reçue: \(content.prefix(50))...")
            return content
        } catch let decodingError {
            // Si le décodage échoue, essayer de voir ce qui a été reçu
            if let jsonString = String(data: data, encoding: .utf8) {
                print("❌ Erreur de décodage JSON. Réponse reçue: \(jsonString.prefix(500))")
            }
            throw decodingError
        }
    }
    
    // MARK: - Configuration
    
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "openai_api_key")
        // Recharger la clé et mettre à jour isEnabled
        reloadAPIKey()
    }
    
    // Recharger la clé depuis OAuth ou UserDefaults
    func reloadAPIKey() {
        // Vérifier si OAuth OpenAI est disponible
        if let oauthToken = OpenAIOAuthService.shared.accessToken,
           !oauthToken.isEmpty,
           oauthToken != "oauth_session_active",
           oauthToken != "authenticated_session" {
            // Accepter les tokens OAuth valides qui commencent par "sk-" ou "sk-proj-"
            self.isEnabled = oauthToken.hasPrefix("sk-") || oauthToken.hasPrefix("sk-proj-")
            self.objectWillChange.send()
            return
        }
        
        // Vérifier si une clé API est stockée (pour compatibilité avec sessions précédentes)
        if OpenAIOAuthService.shared.isAuthenticated,
           let storedKey = UserDefaults.standard.string(forKey: "openai_api_key"),
           !storedKey.isEmpty {
            // Accepter les clés qui commencent par "sk-" ou "sk-proj-"
            self.isEnabled = storedKey.hasPrefix("sk-") || storedKey.hasPrefix("sk-proj-")
            self.objectWillChange.send()
            return
        }
        
        // Sinon, désactiver le service
        self.isEnabled = false
        self.objectWillChange.send()
    }
    
    // Vérifier si une clé API est valide
    func verifyAPIKey(_ key: String) async -> Bool {
        guard !key.isEmpty, key.hasPrefix("sk-") else {
            return false
        }
        
        // Faire une requête de test simple
        let testRequestBody: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                [
                    "role": "user",
                    "content": "test"
                ]
            ],
            "max_tokens": 5
        ]
        
        guard let url = URL(string: baseURL) else {
            return false
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(key)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: testRequestBody)
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                // 200 = valide, 401 = invalide, autres erreurs
                return httpResponse.statusCode == 200
            }
        } catch {
            return false
        }
        
        return false
    }
}

// MARK: - Models API OpenAI

struct OpenAIResponse: Codable {
    let choices: [OpenAIChoice]
}

struct OpenAIChoice: Codable {
    let message: OpenAIMessage
}

struct OpenAIMessage: Codable {
    let content: String
}

enum OpenAIError: Error {
    case apiKeyMissing
    case apiKeyInvalid
    case invalidURL
    case apiError
    case apiErrorWithMessage(String)
    case noResponse
    case rateLimitExceeded
    case noItems
}

