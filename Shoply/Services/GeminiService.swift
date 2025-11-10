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
    
    // Accesseur public pour la clé API (pour vérification dans autres services)
    var apiKey: String? {
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
        userRequest: String? = nil,
        progressCallback: ((Double) async -> Void)? = nil
    ) async throws -> [String] {
        guard !wardrobeItems.isEmpty else {
            throw GeminiError.noItems
        }
        
        guard isEnabled else {
            throw GeminiError.apiKeyMissing
        }
        
        // Préparer les descriptions et images
        var itemsDescriptions: [String] = []
        var imageParts: [[String: Any]] = []
        
        await progressCallback?(0.1) // 10% - Début de préparation
        
        for (index, item) in wardrobeItems.enumerated() {
            var itemDesc = "- \(item.name) | Catégorie: \(item.category.rawValue) | Couleur: \(item.color)"
            
            // Ajouter la marque si disponible
            if let brand = item.brand, !brand.isEmpty {
                itemDesc += " | Marque: \(brand)"
            }
            
            if let material = item.material, !material.isEmpty {
                itemDesc += " | Matière: \(material)"
            }
            if !item.season.isEmpty {
                itemDesc += " | Saisons: \(item.season.map { $0.rawValue }.joined(separator: ", "))"
            }
            if !item.tags.isEmpty {
                itemDesc += " | Tags: \(item.tags.joined(separator: ", "))"
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
            numberOfItems: wardrobeItems.count,
            userRequest: userRequest
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
                
            } else if let dataString = String(data: data, encoding: .utf8) {
                errorMessage = "HTTP \(httpResponse.statusCode): \(dataString.prefix(200))"
                
            } else {
                errorMessage = "HTTP Error \(httpResponse.statusCode)"
                
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
    
    // MARK: - Recommandations Professionnelles
    
    /// Génère des recommandations professionnelles pour entretiens, présentations, etc.
    func generateProfessionalRecommendations(
        occasion: ProfessionalOutfit.ProfessionalOccasion,
        userProfile: UserProfile,
        wardrobeItems: [WardrobeItem]
    ) async throws -> String {
        guard isEnabled else {
            throw GeminiError.apiKeyMissing
        }
        
        // Déterminer le style de tenue approprié selon l'occasion, le genre et l'âge
        let gender = userProfile.gender
        let age = userProfile.age
        
        let prompt = """
        Je prépare un \(occasion.rawValue). Genre: \(gender.rawValue), Âge: \(age) ans.
        
        \(wardrobeItems.isEmpty ? "Aucun vêtement dans la garde-robe." : "Garde-robe disponible:\n\(wardrobeItems.map { "- \($0.name) (\($0.category.rawValue), \($0.color), matière: \($0.material ?? "non spécifiée"))" }.joined(separator: "\n"))")
        
        Réponds avec:
        1. La liste des vêtements nécessaires à porter (adaptés au genre \(gender.rawValue) et à l'âge \(age) ans)
        2. Des suggestions de couleurs adaptées à cette occasion
        3. Des suggestions de matières adaptées à cette occasion
        
        Format:
        **Vêtements:**
        - Chemise blanche
        - Pantalon noir
        - Chaussures de ville
        
        **Couleurs recommandées:**
        - Noir, bleu marine, gris
        
        **Matières recommandées:**
        - Coton, laine, lin
        
        Réponse concise et directe.
        """
        
        return try await sendGeminiRequest(prompt: prompt)
    }
    
    // MARK: - Recommandations Romantiques/Sociales
    
    /// Génère des recommandations pour dates amoureuses et occasions sociales
    func generateRomanticRecommendations(
        occasion: RomanticOutfit.RomanticOccasion,
        userProfile: UserProfile,
        wardrobeItems: [WardrobeItem]
    ) async throws -> String {
        guard isEnabled else {
            throw GeminiError.apiKeyMissing
        }
        
        let gender = userProfile.gender
        let age = userProfile.age
        
        let prompt = """
        Je prépare un \(occasion.rawValue). Genre: \(gender.rawValue), Âge: \(age) ans.
        
        \(wardrobeItems.isEmpty ? "Aucun vêtement dans la garde-robe." : "Garde-robe disponible:\n\(wardrobeItems.map { "- \($0.name) (\($0.category.rawValue), \($0.color), matière: \($0.material ?? "non spécifiée"))" }.joined(separator: "\n"))")
        
        Réponds avec:
        1. La liste des vêtements nécessaires à porter (adaptés au genre \(gender.rawValue) et à l'âge \(age) ans)
        2. Des suggestions de couleurs adaptées à cette occasion
        3. Des suggestions de matières adaptées à cette occasion
        
        Format:
        **Vêtements:**
        - Robe noire
        - Escarpins
        - Sac à main
        
        **Couleurs recommandées:**
        - Noir, rouge, blanc
        
        **Matières recommandées:**
        - Soie, satin, coton
        
        Réponse concise et directe.
        """
        
        return try await sendGeminiRequest(prompt: prompt)
    }
    
    // MARK: - Analyse de Tendances
    
    /// Analyse les tendances selon le pays, la ville et l'âge (optimisé pour rapidité)
    func analyzeTrends(
        country: String,
        city: String?,
        age: Int,
        userProfile: UserProfile
    ) async throws -> String {
        // Vérifier que le service est activé et qu'une clé API est disponible
        guard isEnabled else {
            throw GeminiError.apiKeyMissing
        }
        
        // Obtenir la clé API (stockée ou intégrée)
        let apiKeyToUse: String
        if let storedKey = UserDefaults.standard.string(forKey: "gemini_api_key"),
           !storedKey.isEmpty {
            apiKeyToUse = storedKey
        } else {
            // Utiliser la clé API intégrée par défaut
            apiKeyToUse = embeddedAPIKey
        }
        
        guard !apiKeyToUse.isEmpty else {
            throw GeminiError.apiKeyMissing
        }
        
        let locationInfo = city != nil ? "\(city!), \(country)" : country
        
        // Prompt optimisé pour réponse rapide et concise
        let prompt = """
        Tendances mode pour \(locationInfo), \(age) ans, \(userProfile.gender.rawValue).
        
        Liste concise (3-5 points max) :
        - Styles tendances
        - Couleurs à la mode
        - Pièces essentielles
        
        Réponse courte et directe.
        """
        
        let urlString = "\(baseURL)?key=\(apiKeyToUse)"
        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 300, // Réduit pour réponse plus rapide
                "topP": 0.8,
                "topK": 20
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
            } else if let dataString = String(data: data, encoding: .utf8) {
                errorMessage = "HTTP \(httpResponse.statusCode): \(dataString.prefix(200))"
            } else {
                errorMessage = "HTTP Error \(httpResponse.statusCode)"
            }
            
            if !errorMessage.isEmpty {
                throw GeminiError.apiErrorWithMessage(errorMessage)
            } else {
                throw GeminiError.apiError
            }
        }
        
        // Vérifier que les données ne sont pas vides
        guard !data.isEmpty else {
            throw GeminiError.noResponse
        }
        
        // Décoder la réponse avec gestion d'erreur améliorée
        do {
            // Essayer d'abord avec JSONSerialization pour plus de flexibilité
            if let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                // Vérifier s'il y a une erreur dans la réponse
                if let errorInfo = jsonObject["error"] as? [String: Any],
                   let message = errorInfo["message"] as? String {
                    throw GeminiError.apiErrorWithMessage(message)
                }
                
                // Extraire le texte depuis la structure JSON
                if let candidates = jsonObject["candidates"] as? [[String: Any]],
                   let firstCandidate = candidates.first,
                   let content = firstCandidate["content"] as? [String: Any],
                   let parts = content["parts"] as? [[String: Any]] {
                    for part in parts {
                        if let text = part["text"] as? String, !text.isEmpty {
                            return text
                        }
                    }
                }
            }
            
            // Fallback: essayer avec JSONDecoder
            let apiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
            
            guard let content = apiResponse.candidates.first?.content,
                  let text = content.parts.compactMap({ $0.text }).first, !text.isEmpty else {
                throw GeminiError.noResponse
            }
            
            return text
        } catch let error as GeminiError {
            // Si c'est déjà une GeminiError, la relancer
            throw error
        } catch {
            // Dernière tentative: extraire le texte depuis la réponse brute
            if let dataString = String(data: data, encoding: .utf8) {
                // Chercher du texte entre guillemets ou après "text":
                if let textRange = dataString.range(of: #""text"\s*:\s*"([^"]+)""#, options: .regularExpression),
                   let textMatch = dataString[textRange].components(separatedBy: "\"").dropFirst().first,
                   !textMatch.isEmpty {
                    return String(textMatch)
                }
            }
            
            throw GeminiError.apiErrorWithMessage("Erreur de décodage de la réponse")
        }
    }
    
    // MARK: - Conseils Voyage
    
    /// Génère des conseils de voyage avec Gemini
    func generateTravelAdvice(
        destination: String,
        startDate: Date,
        endDate: Date,
        userProfile: UserProfile
    ) async throws -> String {
        guard isEnabled else {
            throw GeminiError.apiKeyMissing
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "fr_FR")
        
        let prompt = """
        Je vais voyager à \(destination) du \(formatter.string(from: startDate)) au \(formatter.string(from: endDate)).
        
        Mon profil :
        - Âge: \(userProfile.age) ans
        - Genre: \(userProfile.gender.rawValue)
        
        Donne-moi des conseils détaillés sur ce qu'il faut prendre pour ce voyage :
        - Les vêtements essentiels à emporter
        - Les accessoires nécessaires
        - Les chaussures adaptées
        - Des conseils selon la météo prévue
        - Des recommandations de style pour cette destination
        
        Réponds de manière détaillée et pratique.
        """
        
        return try await sendGeminiRequest(prompt: prompt)
    }
    
    /// Génère une checklist de voyage personnalisée avec Gemini
    func generateTravelChecklist(
        destination: String,
        startDate: Date,
        endDate: Date,
        duration: Int,
        season: String,
        averageTemperature: Double,
        weatherConditions: String,
        userProfile: UserProfile
    ) async throws -> String {
        guard isEnabled else {
            throw GeminiError.apiKeyMissing
        }
        
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.locale = Locale(identifier: "fr_FR")
        
        let prompt = """
        Je vais voyager à \(destination) du \(formatter.string(from: startDate)) au \(formatter.string(from: endDate)) (\(duration) jours).
        
        INFORMATIONS CRITIQUES À UTILISER:
        - **Destination**: \(destination) (ville/pays/quartier - adapte les vêtements à cette destination spécifique)
        - **Période**: \(formatter.string(from: startDate)) au \(formatter.string(from: endDate)) (\(duration) jours)
        - **Saison**: \(season) (TRÈS IMPORTANT - adapte les vêtements à cette saison)
        - **Météo**: Température moyenne \(Int(averageTemperature))°C, Conditions: \(weatherConditions) (TRÈS IMPORTANT - adapte les vêtements à cette météo)
        - **Genre**: \(userProfile.gender.rawValue) (adapte les vêtements à ce genre)
        - **Âge**: \(userProfile.age) ans (adapte le style à cet âge)
        
        Génère une checklist complète et PERSONNALISÉE pour ce voyage en tenant compte de TOUTES ces informations :
        
        1. **Vêtements** adaptés à :
           - La destination (\(destination) - style local, culture, activités)
           - La saison (\(season) - vêtements de saison appropriés)
           - La météo (\(Int(averageTemperature))°C, \(weatherConditions) - vêtements adaptés à la température et conditions)
           - La durée (\(duration) jours - quantités appropriées)
           - Le genre (\(userProfile.gender.rawValue)) et l'âge (\(userProfile.age) ans)
        
        2. **Accessoires** nécessaires pour cette destination et cette période
        
        3. **Chaussures** adaptées à la destination, la météo et les activités
        
        4. **Articles de toilette** essentiels
        
        5. **Documents** importants (passeport, billets, etc.)
        
        6. **Appareils électroniques** nécessaires
        
        7. **Tout autre article** pertinent pour \(destination) en \(season) avec cette météo
        
        Format ta réponse comme une liste avec des puces (-), une ligne par item.
        Pour les quantités, utilise le format: - Item (quantité)
        Exemple: - T-shirts (5)
        
        Réponds UNIQUEMENT avec la liste, sans introduction ni conclusion.
        """
        
        return try await sendGeminiRequest(prompt: prompt)
    }
    
    // MARK: - Génération Lookbook
    
    /// Génère un lookbook avec Gemini
    func generateLookbook(
        title: String,
        description: String?,
        outfits: [HistoricalOutfit],
        userProfile: UserProfile
    ) async throws -> String {
        guard isEnabled else {
            throw GeminiError.apiKeyMissing
        }
        
        let outfitsDescription = outfits.prefix(10).map { outfit in
            "- \(outfit.outfit.displayName) (porté le \(formatDate(outfit.dateWorn)))"
        }.joined(separator: "\n")
        
        let prompt = """
        Crée un lookbook professionnel avec le titre "\(title)".
        \(description != nil ? "Description: \(description!)\n" : "")
        
        Outfits à inclure :
        \(outfitsDescription)
        
        Crée une description de lookbook professionnelle qui met en valeur ces outfits.
        Inclus des suggestions de thème, de mise en page, et de style visuel.
        
        Réponds de manière créative et professionnelle.
        """
        
        return try await sendGeminiRequest(prompt: prompt)
    }
    
    // MARK: - Suggestions Calendrier
    
    /// Génère des suggestions d'outfits pour un événement du calendrier
    func generateEventOutfitSuggestions(
        event: CalendarEvent,
        userProfile: UserProfile,
        wardrobeItems: [WardrobeItem],
        weather: WeatherData?
    ) async throws -> [String] {
        guard isEnabled else {
            throw GeminiError.apiKeyMissing
        }
        
        var weatherInfo = ""
        if let weather = weather {
            weatherInfo = """
            MÉTÉO:
            - Température: \(Int(weather.temperature))°C
            - Conditions: \(weather.condition.rawValue)
            """
        }
        
        let prompt = """
        Je dois assister à cet événement et j'ai besoin de suggestions d'outfits :
        
        ÉVÉNEMENT:
        - Titre: \(event.title)
        - Type: \(event.eventType.rawValue)
        - Date: \(formatDate(event.startDate))
        \(event.location != nil ? "- Lieu: \(event.location!)" : "")
        \(event.notes != nil ? "- Notes: \(event.notes!)" : "")
        
        \(weatherInfo)
        
        PROFIL:
        - Genre: \(userProfile.gender.rawValue)
        - Âge: \(userProfile.age)
        
        GARDE-ROBE:
        \(wardrobeItems.map { "- \($0.name) (\($0.category.rawValue), \($0.color))" }.joined(separator: "\n"))
        
        Propose-moi 3 styles vestimentaires différents adaptés à cet événement, en tenant compte de la météo et de mon profil.
        Pour chaque style, indique :
        - Les vêtements spécifiques de ma garde-robe à porter
        - Pourquoi ce style est adapté à cet événement
        - Des conseils supplémentaires
        
        Format: "Style 1: ...", "Style 2: ...", "Style 3: ..."
        """
        
        let response = try await sendGeminiRequest(prompt: prompt)
        
        // Parser la réponse en plusieurs suggestions
        let suggestions = response.components(separatedBy: "\n")
            .filter { $0.contains("Style") || $0.contains("style") }
            .map { $0.trimmingCharacters(in: CharacterSet.whitespaces) }
            .filter { !$0.isEmpty }
        
        return suggestions.isEmpty ? [response] : suggestions
    }
    
    // MARK: - Helper pour requêtes Gemini
    
    private func sendGeminiRequest(prompt: String) async throws -> String {
        guard let apiKey = apiKey else {
            throw GeminiError.apiKeyMissing
        }
        
        let urlString = "\(baseURL)?key=\(apiKey)"
        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw GeminiError.apiError
        }
        
        let apiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        
        guard let content = apiResponse.candidates.first?.content,
              let text = content.parts.compactMap({ $0.text }).first else {
            throw GeminiError.noResponse
        }
        
        return text
    }
    
    // MARK: - Helpers
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "fr_FR")
        return formatter.string(from: date)
    }
    
    // MARK: - Construction du prompt
    
    private func buildPrompt(
        itemsDescriptions: [String],
        weather: WeatherData,
        userProfile: UserProfile,
        hasImages: Bool,
        numberOfItems: Int,
        userRequest: String? = nil
    ) -> String {
        let itemsDescription = itemsDescriptions.joined(separator: "\n")
        
        // Calculer le nombre d'outfits : max 3 si beaucoup d'items, 1 seul si peu d'items
        let numberOfOutfits: Int
        if numberOfItems < 10 {
            numberOfOutfits = 1 // Peu d'items = 1 seul outfit
        } else if numberOfItems < 20 {
            numberOfOutfits = 2 // Moyen = 2 outfits
        } else {
            numberOfOutfits = 3 // Beaucoup = 3 outfits max
        }
        
        // Récupérer le style vestimentaire sélectionné
        var styleInfo = ""
        if let preferredStyle = userProfile.preferences.preferredStyle {
            styleInfo = "\n- Style vestimentaire souhaité: \(preferredStyle.rawValue) (TRÈS IMPORTANT: Respecte exactement ce style dans tes suggestions)"
        } else if let customStyle = userProfile.preferences.preferredStyleRawValue, !customStyle.isEmpty {
            styleInfo = "\n- Style vestimentaire personnalisé: \(customStyle) (TRÈS IMPORTANT: Respecte exactement ce style décrit dans tes suggestions)"
        }
        
        // Ajouter la demande spécifique de l'utilisateur si elle existe
        var userRequestSection = ""
        if let request = userRequest, !request.trimmingCharacters(in: .whitespaces).isEmpty {
            userRequestSection = """
            
            ⚠️ DEMANDE SPÉCIFIQUE DE L'UTILISATEUR (PRIORITÉ ABSOLUE):
            "\(request)"
            
            Cette demande est TRÈS IMPORTANTE. Analyse attentivement cette demande et respecte-la EXACTEMENT :
            - Si l'utilisateur demande un vêtement spécifique (ex: "je veux mon short rouge"), trouve UNIQUEMENT ce vêtement exact dans la liste ci-dessus et utilise-le dans TOUS les outfits.
            - Si une couleur est mentionnée (ex: "rouge", "bleu"), utilise UNIQUEMENT les vêtements de cette couleur EXACTE, jamais une autre couleur.
            - Si un type de vêtement est mentionné (ex: "short", "t-shirt", "robe"), utilise UNIQUEMENT ce type de vêtement, pas un autre.
            - Si l'utilisateur dit "mon [vêtement] [couleur]", cela signifie qu'il veut spécifiquement CE vêtement avec CETTE couleur de SA garde-robe listée ci-dessus.
            - Ignore cette demande uniquement si le vêtement demandé n'existe vraiment pas dans la garde-robe listée.
            """
        }
        
        var prompt = """
        Analyse cette garde-robe et génère \(numberOfOutfits) outfit(s) parfaitement adapté(s).\(userRequestSection)
        
        PROFIL UTILISATEUR:
        - Genre: \(userProfile.gender.rawValue) (IMPORTANT: Adapte les outfits à ce genre spécifique)
        - Âge: \(userProfile.age)\(styleInfo)
        
        CONDITIONS MÉTÉOROLOGIQUES D'AUJOURD'HUI:
        - Température: \(Int(weather.temperature))°C (IMPORTANT: Adapte les vêtements à cette température)
        - Conditions: \(weather.condition.rawValue) (IMPORTANT: Prends en compte cette condition météo)
        
        GARDE-ROBE DISPONIBLE (avec toutes les informations):
        \(itemsDescription)
        
        IMPORTANT - INFORMATIONS DES VÊTEMENTS:
        Chaque vêtement ci-dessus contient: son nom exact, sa catégorie, sa couleur PRÉCISE, sa marque (si renseignée), sa matière, et ses tags.
        UTILISE EXACTEMENT ces informations dans tes suggestions. Si l'utilisateur demande un vêtement d'une couleur spécifique, utilise UNIQUEMENT les vêtements de cette couleur exacte.
        """
        
        if hasImages {
            prompt += "\n\nIMPORTANT: Tu as accès aux photos réelles des vêtements ci-dessus. Analyse visuellement chaque vêtement pour mieux comprendre leur style, couleur, matière et coupe."
        }
        
        prompt += """
        
        INSTRUCTIONS CRITIQUES:
        1. Génère EXACTEMENT \(numberOfOutfits) suggestion(s) d'outfit(s) différent(s) et adapté(s)
        2. Chaque outfit doit inclure: un haut (obligatoire), un bas (obligatoire), des chaussures (obligatoire), et éventuellement des accessoires
        3. **ADAPTE CHAQUE OUTFIT AU GENRE** (\(userProfile.gender.rawValue)) - Les vêtements doivent être adaptés à ce genre spécifique
        4. **ADAPTE CHAQUE OUTFIT À LA MÉTÉO** (\(Int(weather.temperature))°C, \(weather.condition.rawValue)) - Les vêtements doivent être adaptés à cette température et condition météo\(styleInfo.isEmpty ? "" : "\n5. **RESPECTE LE STYLE VESTIMENTAIRE** - Si un style a été spécifié, adapte TOUS les outfits à ce style exactement")
        6. **RESPECTE ABSOLUMENT LA DEMANDE SPÉCIFIQUE DE L'UTILISATEUR** - Si une demande spécifique a été fournie (ex: "je veux mon short rouge"), trouve ce vêtement exact dans la liste ci-dessus par son nom ET sa couleur, et utilise-le. Ne substitue JAMAIS un autre vêtement même s'il est similaire.
        7. **UTILISE LES COULEURS EXACTES** - Si un vêtement est décrit comme "rouge", utilise UNIQUEMENT ce vêtement rouge, pas un autre vêtement d'une autre couleur. Si l'utilisateur demande spécifiquement un vêtement d'une couleur précise, respecte EXACTEMENT cette couleur demandée. Ne confonds JAMAIS les couleurs.
        8. Utilise UNIQUEMENT les vêtements listés ci-dessus avec leurs noms EXACTS
        9. Si tu as peu d'articles, tu peux réutiliser certains vêtements dans différents outfits mais varie les combinaisons
        10. Réponds UNIQUEMENT avec les \(numberOfOutfits) suggestion(s), une par ligne, format:
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
    
    /// Répond à une question de l'utilisateur - LLM conversationnel polyvalent
    /// Supporte l'historique de conversation pour un dialogue naturel
    func askAboutClothing(
        question: String,
        userProfile: UserProfile,
        currentWeather: WeatherData?,
        wardrobeItems: [WardrobeItem],
        image: UIImage? = nil,
        conversationHistory: [ChatMessage] = []
    ) async throws -> String {
        guard isEnabled else {
            throw GeminiError.apiKeyMissing
        }
        
        // Construire l'historique de conversation pour un dialogue naturel
        var contents: [[String: Any]] = []
        
        // Ajouter le contexte système uniquement au début de la conversation
        if conversationHistory.isEmpty {
            var systemContext = """
            Tu es Shoply AI, un assistant intelligent et conversationnel. Tu es l'assistant personnel intelligent de l'application Shoply.
            
            TON IDENTITÉ :
            - Ton nom complet est "Shoply AI"
            - Tu as été créé et développé par William RAUWENS OLIVER
            - Tu es l'assistant personnel intelligent de l'application Shoply
            
            IMPORTANT : 
            - Tu t'appelles UNIQUEMENT "Shoply AI", jamais "Gemini", "Google", ou autre chose
            - Si on te demande qui est ton créateur, réponds EXACTEMENT : "Je suis Shoply AI, créé par William RAUWENS OLIVER"
            - Si on te demande comment tu t'appelles, quel est ton nom, ou quel est ton prénom, réponds EXACTEMENT : "Je m'appelle Shoply AI, créé par William RAUWENS OLIVER"
            - Si on te demande "c quoi ton prénom" ou des variantes, réponds : "Je m'appelle Shoply AI, créé par William RAUWENS OLIVER"
            - Tu es intelligent, réfléchi et tu donnes des réponses pertinentes et utiles
            - Tu peux discuter de TOUS les sujets : mode, technologie, science, histoire, cuisine, sport, culture, actualités, etc.
            - Tu es amical, naturel, et tu adaptes ton style de réponse au contexte
            - Tu donnes des réponses claires, concises et intelligentes
            - Ne mentionne JAMAIS Google, Gemini, ou toute autre technologie sous-jacente
            - Tu es Shoply, point final
            """
            
            // Ajouter le contexte utilisateur seulement si pertinent
            if !wardrobeItems.isEmpty || currentWeather != nil {
                systemContext += "\n\nCONTEXTE UTILISATEUR (utilise seulement si pertinent à la conversation):"
                
                if !wardrobeItems.isEmpty {
                    let itemsDescription = wardrobeItems.prefix(10).map { item in
                        "- \(item.name) (\(item.category.rawValue), \(item.color))"
                    }.joined(separator: "\n")
                    systemContext += "\nGarde-robe: \(itemsDescription)"
                }
                
                if let weather = currentWeather {
                    systemContext += "\nMétéo: \(Int(weather.temperature))°C, \(weather.condition.rawValue)"
                }
            }
            
            contents.append([
                "role": "user",
                "parts": [["text": systemContext]]
            ])
            
            contents.append([
                "role": "model",
                "parts": [["text": "Bonjour ! Je suis Shoply AI, votre assistant personnel intelligent. J'ai été créé par William RAUWENS OLIVER. Je peux discuter de tout avec vous et vous aider avec vos questions sur la mode, le style, ou n'importe quel autre sujet. Comment puis-je vous aider aujourd'hui ?"]]
            ])
        }
        
        // Ajouter l'historique de conversation (derniers 10 messages pour garder le contexte)
        let recentHistory = conversationHistory.suffix(10)
        for message in recentHistory {
            let role = message.isUser ? "user" : "model"
            var parts: [[String: Any]] = [["text": message.content]]
            
            // Ajouter l'image si disponible
            if let image = message.image, let base64Image = imageToBase64(image) {
                parts.append([
                    "inline_data": [
                        "mime_type": "image/jpeg",
                        "data": base64Image
                    ]
                ])
            }
            
            contents.append([
                "role": role,
                "parts": parts
            ])
        }
        
        // Ajouter la nouvelle question
        var questionParts: [[String: Any]] = [["text": question]]
        
        // Ajouter l'image si disponible
        if let image = image, let base64Image = imageToBase64(image) {
            questionParts.append([
                "inline_data": [
                    "mime_type": "image/jpeg",
                    "data": base64Image
                ]
            ])
        }
        
        contents.append([
            "role": "user",
            "parts": questionParts
        ])
        
        // Utiliser gemini-2.5-flash avec v1beta selon la documentation officielle
        // Construire l'URL - utiliser la clé API intégrée ou stockée
        let urlString: String
        
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
        
        guard let url = URL(string: urlString) else {
            throw GeminiError.invalidURL
        }
        
        let requestBody: [String: Any] = [
            "contents": contents,
            "generationConfig": [
                "temperature": 0.9, // Plus créatif et conversationnel
                "maxOutputTokens": 2000, // Réponses plus longues et détaillées
                "topP": 0.95,
                "topK": 40
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
                
            } else if let dataString = String(data: data, encoding: .utf8) {
                errorMessage = "HTTP \(httpResponse.statusCode): \(dataString.prefix(200))"
                
            } else {
                errorMessage = "HTTP Error \(httpResponse.statusCode)"
                
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

