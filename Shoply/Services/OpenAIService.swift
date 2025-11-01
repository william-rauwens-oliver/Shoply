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
    
    // Clé API intégrée directement dans le code
    private let embeddedAPIKey: String? = nil
    
    private var apiKey: String? {
        // Priorité à la clé intégrée, puis UserDefaults en fallback
        return embeddedAPIKey ?? UserDefaults.standard.string(forKey: "openai_api_key")
    }
    
    private let baseURL = "https://api.openai.com/v1/chat/completions"
    
    @Published var isEnabled = false
    
    private init() {
        // Charger et activer la clé API au démarrage
        reloadAPIKey()
        
        // Si on a une clé intégrée, l'activer automatiquement
        if embeddedAPIKey != nil {
            DispatchQueue.main.async {
                self.isEnabled = true
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
    
    // MARK: - Configuration
    
    func setAPIKey(_ key: String) {
        UserDefaults.standard.set(key, forKey: "openai_api_key")
        // Recharger la clé et mettre à jour isEnabled
        reloadAPIKey()
    }
    
    // Recharger la clé depuis la clé intégrée ou UserDefaults
    func reloadAPIKey() {
        let keyToCheck = embeddedAPIKey ?? UserDefaults.standard.string(forKey: "openai_api_key")
        self.isEnabled = keyToCheck != nil && !keyToCheck!.isEmpty && keyToCheck!.hasPrefix("sk-")
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
    case invalidURL
    case apiError
    case noResponse
    case rateLimitExceeded
    case noItems
}

