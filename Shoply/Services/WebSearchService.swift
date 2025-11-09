//
//  WebSearchService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//  Service de recherche web pour Shoply AI
//

import Foundation

/// Service de recherche web pour Shoply AI
/// Utilise Google Custom Search API pour rechercher des informations sur internet
class WebSearchService {
    static let shared = WebSearchService()
    
    // Configuration Google Custom Search API
    // Remplacez par votre propre API Key et Search Engine ID
    private let apiKey = "YOUR_GOOGLE_API_KEY" // À configurer
    private let searchEngineID = "YOUR_SEARCH_ENGINE_ID" // À configurer
    private let baseURL = "https://www.googleapis.com/customsearch/v1"
    
    private init() {}
    
    // MARK: - Recherche Web
    
    /// Recherche des informations sur internet
    /// - Parameters:
    ///   - query: La requête de recherche
    ///   - language: La langue pour la recherche (optionnel)
    ///   - maxResults: Nombre maximum de résultats (défaut: 5)
    /// - Returns: Les résultats de recherche avec snippets
    func search(query: String, language: String? = nil, maxResults: Int = 5) async throws -> [SearchResult] {
        guard !apiKey.contains("YOUR_GOOGLE_API_KEY") && !searchEngineID.contains("YOUR_SEARCH_ENGINE_ID") else {
            throw WebSearchError.apiNotConfigured
        }
        
        // Construire l'URL de recherche
        var components = URLComponents(string: baseURL)!
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "cx", value: searchEngineID),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "num", value: "\(min(maxResults, 10))") // Max 10 par requête
        ]
        
        // Ajouter la langue si spécifiée
        if let language = language {
            queryItems.append(URLQueryItem(name: "lr", value: "lang_\(language)"))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw WebSearchError.invalidURL
        }
        
        // Effectuer la requête
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WebSearchError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 403 {
                throw WebSearchError.apiQuotaExceeded
            } else if httpResponse.statusCode == 429 {
                throw WebSearchError.rateLimitExceeded
            } else {
                throw WebSearchError.httpError(httpResponse.statusCode)
            }
        }
        
        // Parser la réponse JSON
        let jsonResponse = try JSONDecoder().decode(GoogleSearchResponse.self, from: data)
        
        return jsonResponse.items?.map { item in
            SearchResult(
                title: item.title,
                snippet: item.snippet,
                link: item.link,
                displayLink: item.displayLink
            )
        } ?? []
    }
    
    /// Recherche et extrait le contenu textuel des résultats
    /// - Parameter query: La requête de recherche
    /// - Returns: Le texte extrait des résultats de recherche
    func searchAndExtract(query: String, language: String? = nil) async throws -> String {
        let results = try await search(query: query, language: language, maxResults: 5)
        
        // Combiner les snippets et titres
        var extractedText = ""
        for (index, result) in results.enumerated() {
            extractedText += "Résultat \(index + 1):\n"
            extractedText += "Titre: \(result.title)\n"
            extractedText += "Description: \(result.snippet)\n"
            extractedText += "Source: \(result.displayLink)\n\n"
        }
        
        return extractedText
    }
}

// MARK: - Modèles de Données

struct SearchResult {
    let title: String
    let snippet: String
    let link: String
    let displayLink: String
}

struct GoogleSearchResponse: Codable {
    let items: [GoogleSearchItem]?
}

struct GoogleSearchItem: Codable {
    let title: String
    let snippet: String
    let link: String
    let displayLink: String
}

// MARK: - Erreurs

enum WebSearchError: LocalizedError {
    case apiNotConfigured
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiQuotaExceeded
    case rateLimitExceeded
    case noResults
    
    var errorDescription: String? {
        switch self {
        case .apiNotConfigured:
            return "L'API de recherche Google n'est pas configurée. Veuillez configurer votre API Key et Search Engine ID."
        case .invalidURL:
            return "URL de recherche invalide."
        case .invalidResponse:
            return "Réponse invalide du serveur."
        case .httpError(let code):
            return "Erreur HTTP \(code)."
        case .apiQuotaExceeded:
            return "Quota de l'API Google dépassé."
        case .rateLimitExceeded:
            return "Limite de taux dépassée. Veuillez réessayer plus tard."
        case .noResults:
            return "Aucun résultat trouvé pour cette recherche."
        }
    }
}

