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
        
        let prompt = """
        Je prépare un \(occasion.rawValue) et j'ai besoin de recommandations vestimentaires professionnelles.
        
        PROFIL:
        - Genre: \(userProfile.gender.rawValue)
        - Âge: \(userProfile.age)
        
        OCCASION: \(occasion.rawValue)
        
        GARDE-ROBE DISPONIBLE:
        \(wardrobeItems.map { "- \($0.name) (\($0.category.rawValue), \($0.color))" }.joined(separator: "\n"))
        
        Donne-moi des recommandations détaillées pour cette occasion :
        1. Quels vêtements de ma garde-robe dois-je porter ?
        2. Quelles couleurs sont les plus appropriées ?
        3. Des conseils sur les accessoires
        4. Des conseils généraux pour cette occasion
        
        Réponds de manière professionnelle et détaillée.
        """
        
        return try await sendGeminiRequest(prompt: prompt)
    }
    
    // MARK: - Analyse de Tendances
    
    /// Analyse les tendances selon le pays, la ville et l'âge
    func analyzeTrends(
        country: String,
        city: String?,
        age: Int,
        userProfile: UserProfile
    ) async throws -> String {
        guard isEnabled else {
            throw GeminiError.apiKeyMissing
        }
        
        let locationInfo = city != nil ? "\(city!), \(country)" : country
        
        let prompt = """
        Analyse les tendances de mode actuelles pour :
        - Localisation: \(locationInfo)
        - Âge: \(age) ans
        - Genre: \(userProfile.gender.rawValue)
        
        Donne-moi les tendances d'outfits actuelles de manière concise et claire :
        - Les styles les plus portés
        - Les couleurs tendances
        - Les pièces essentielles
        - Des recommandations personnalisées
        
        Réponds de manière concise et à jour.
        """
        
        return try await sendGeminiRequest(prompt: prompt)
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
            Tu es Shoply AI, un assistant intelligent et conversationnel. Tu peux discuter de TOUS les sujets sans restriction : mode, technologie, science, histoire, cuisine, sport, culture, actualités, etc.
            
            Tu es amical, naturel, et tu adaptes ton style de réponse au contexte. Tu peux avoir des conversations longues et détaillées.
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
                "parts": [["text": "Bonjour ! Je suis Shoply AI, votre assistant conversationnel. Je peux discuter de tout avec vous. Comment puis-je vous aider aujourd'hui ?"]]
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

