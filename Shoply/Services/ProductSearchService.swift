//
//  ProductSearchService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation

/// Service de recherche de produits depuis les boutiques en ligne
class ProductSearchService {
    static let shared = ProductSearchService()
    
    private init() {}
    
    /// Recherche un produit par code-barres ou nom sur plusieurs boutiques
    func searchProduct(barcode: String? = nil, name: String? = nil) async throws -> [ProductResult] {
        var results: [ProductResult] = []
        
        // Utiliser plusieurs APIs de recherche de produits
        // 1. Open Product Data (barcode)
        if let barcode = barcode {
            if let openProductData = try? await searchOpenProductData(barcode: barcode) {
                results.append(openProductData)
            }
        }
        
        // 2. Recherche par nom sur plusieurs boutiques
        if let name = name {
            let searchResults = try await searchMultipleStores(query: name)
            results.append(contentsOf: searchResults)
        }
        
        return results
    }
    
    /// Recherche sur Open Product Data (gratuit, basé sur les codes-barres)
    private func searchOpenProductData(barcode: String) async throws -> ProductResult {
        let urlString = "https://world.openfoodfacts.org/api/v0/product/\(barcode).json"
        guard let url = URL(string: urlString) else {
            throw ProductSearchError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        
        if let product = json?["product"] as? [String: Any] {
            let productName = product["product_name"] as? String ?? "Produit inconnu"
            let brand = product["brands"] as? String
            let imageURL = product["image_url"] as? String
            
            return ProductResult(
                name: productName,
                brand: brand,
                barcode: barcode,
                price: nil,
                currency: "EUR",
                imageURL: imageURL,
                storeURL: nil,
                storeName: "Open Product Data"
            )
        }
        
        throw ProductSearchError.productNotFound
    }
    
    /// Recherche sur plusieurs boutiques françaises (simulation avec APIs publiques)
    private func searchMultipleStores(query: String) async throws -> [ProductResult] {
        var results: [ProductResult] = []
        
        // Liste complète des magasins et boutiques français
        let stores = [
            // Fast fashion
            "Zara", "H&M", "Uniqlo", "Mango", "COS", "Bershka", "Pull & Bear", "Stradivarius",
            // Mode française
            "Sandro", "Maje", "Claudie Pierlot", "Ba&sh", "Sézane", "Rouje", "Musier Paris",
            // Grandes enseignes
            "Galeries Lafayette", "Printemps", "Le Bon Marché", "Monoprix", "Carrefour", "Auchan",
            // Mode accessible
            "Kiabi", "C&A", "La Redoute", "Zalando", "Asos", "Vinted", "Vestiaire Collective",
            // Luxe
            "Louis Vuitton", "Hermès", "Chanel", "Dior", "Yves Saint Laurent", "Givenchy",
            // Sport
            "Decathlon", "Go Sport", "Intersport", "Nike", "Adidas", "Puma",
            // Chaussures
            "André", "Bata", "Eram", "Minelli", "Jonak",
            // Accessoires
            "Longchamp", "Lancel", "Furla", "Michael Kors", "Coach"
        ]
        
        for store in stores {
            // Simuler une recherche (en production, utiliser l'API de chaque boutique)
            let storeNameLower = store.lowercased()
                .replacingOccurrences(of: " ", with: "-")
                .replacingOccurrences(of: "&", with: "and")
                .replacingOccurrences(of: "é", with: "e")
                .replacingOccurrences(of: "è", with: "e")
                .replacingOccurrences(of: "à", with: "a")
            
            let result = ProductResult(
                name: query,
                brand: store,
                barcode: nil,
                price: Double.random(in: 20...500),
                currency: "EUR",
                imageURL: nil,
                storeURL: "https://www.\(storeNameLower).com/fr/search?q=\(query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")",
                storeName: store
            )
            results.append(result)
        }
        
        return results
    }
}

struct ProductResult: Codable, Identifiable {
    let id: UUID
    let name: String
    let brand: String?
    let barcode: String?
    let price: Double?
    let currency: String
    let imageURL: String?
    let storeURL: String?
    let storeName: String
    
    init(id: UUID = UUID(), name: String, brand: String? = nil, barcode: String? = nil, price: Double? = nil, currency: String = "EUR", imageURL: String? = nil, storeURL: String? = nil, storeName: String) {
        self.id = id
        self.name = name
        self.brand = brand
        self.barcode = barcode
        self.price = price
        self.currency = currency
        self.imageURL = imageURL
        self.storeURL = storeURL
        self.storeName = storeName
    }
}

enum ProductSearchError: LocalizedError {
    case invalidURL
    case productNotFound
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "URL invalide"
        case .productNotFound:
            return "Produit non trouvé"
        case .networkError:
            return "Erreur réseau"
        }
    }
}

