//
//  OutfitService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import Combine

/// Service métier - Couche métier (BLL)
/// Gère la logique métier des outfits
class OutfitService: ObservableObject {
    @Published var outfits: [Outfit] = []
    @Published var isLoading = false
    @Published var error: Error?
    
    private let dataManager = DataManager.shared
    
    init() {
        loadOutfits()
    }
    
    // MARK: - Chargement des données
    func loadOutfits() {
        isLoading = true
        defer { isLoading = false }
        
        // Charger depuis les données par défaut
        outfits = OutfitFactory.createDefaultOutfits()
        
        // Synchroniser avec les favoris sauvegardés
        syncFavorites()
    }
    
    // MARK: - Gestion des favoris
    func toggleFavorite(outfit: Outfit) {
        if let index = outfits.firstIndex(where: { $0.id == outfit.id }) {
            let wasFavorite = outfits[index].isFavorite
            
            if wasFavorite {
                dataManager.removeFavorite(outfitId: outfit.id)
            } else {
                dataManager.addFavorite(outfitId: outfit.id)
            }
            
            outfits[index].isFavorite.toggle()
        }
    }
    
    private func syncFavorites() {
        let favoriteIds = dataManager.getAllFavorites()
        for (index, outfit) in outfits.enumerated() {
            outfits[index].isFavorite = favoriteIds.contains(outfit.id)
        }
    }
    
    // MARK: - Filtrage et recherche
    func getOutfitsFor(weather: WeatherType) -> [Outfit] {
        return outfits.filter { outfit in
            outfit.suitableWeather.contains(weather)
        }
    }
    
    func getFavorites() -> [Outfit] {
        return outfits.filter { $0.isFavorite }
    }
    
    func searchOutfits(query: String) -> [Outfit] {
        guard !query.isEmpty else { return outfits }
        
        return outfits.filter { outfit in
            outfit.name.localizedCaseInsensitiveContains(query) ||
            outfit.description.localizedCaseInsensitiveContains(query) ||
            outfit.type.rawValue.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - Statistiques
    func getStats() -> OutfitStats {
        let total = outfits.count
        let favorites = outfits.filter { $0.isFavorite }.count
        
        return OutfitStats(
            totalOutfits: total,
            favoritesCount: favorites
        )
    }
}

/// Structure pour les statistiques
struct OutfitStats {
    let totalOutfits: Int
    let favoritesCount: Int
}

/// Factory pour créer les outfits par défaut
struct OutfitFactory {
    static func createDefaultOutfits() -> [Outfit] {
        return [
            // Outfits énergiques
            Outfit(
                name: "Look Dynamique",
                description: "Parfait pour une journée active et productive",
                type: .casual,
                top: "T-shirt coloré",
                bottom: "Jeans slim",
                shoes: "Baskets blanches",
                accessories: ["Montre connectée"],
                suitableWeather: [.sunny, .warm],
                imageName: "outfit_energetic_1",
                comfortLevel: 5,
                styleLevel: 4
            ),
            Outfit(
                name: "Sportif Chic",
                description: "Confort et style pour une journée pleine d'énergie",
                type: .smartCasual,
                top: "Sweat à capuche léger",
                bottom: "Pantalon de jogging ajusté",
                shoes: "Baskets de running",
                accessories: ["Casquette", "Sac à dos"],
                suitableWeather: [.cloudy, .warm],
                imageName: "outfit_energetic_2",
                comfortLevel: 5,
                styleLevel: 3
            ),
            // Outfits calmes
            Outfit(
                name: "Sérénité Urbaine",
                description: "Idéal pour une journée de détente ou de travail paisible",
                type: .casual,
                top: "Pull en cachemire doux",
                bottom: "Pantalon chino",
                shoes: "Mocassins",
                accessories: ["Écharpe légère"],
                suitableWeather: [.cloudy, .cold],
                imageName: "outfit_calm_1",
                comfortLevel: 4,
                styleLevel: 4
            ),
            Outfit(
                name: "Zen au Bureau",
                description: "Confortable et professionnel pour une journée calme",
                type: .business,
                top: "Chemise en lin",
                bottom: "Pantalon large",
                shoes: "Ballerines",
                accessories: ["Collier discret"],
                suitableWeather: [.sunny, .warm],
                imageName: "outfit_calm_2",
                comfortLevel: 4,
                styleLevel: 3
            ),
            // Outfits confiants
            Outfit(
                name: "Power Look",
                description: "Pour affirmer votre présence et votre détermination",
                type: .formal,
                top: "Blazer ajusté",
                bottom: "Pantalon de costume",
                shoes: "Escarpins",
                accessories: ["Montre élégante", "Sac à main structuré"],
                suitableWeather: [.sunny, .cloudy],
                imageName: "outfit_confident_1",
                comfortLevel: 3,
                styleLevel: 5
            ),
            Outfit(
                name: "Charisme Décontracté",
                description: "Un style qui inspire confiance sans effort",
                type: .smartCasual,
                top: "Chemise en jean",
                bottom: "Jupe crayon",
                shoes: "Bottes",
                accessories: ["Ceinture en cuir"],
                suitableWeather: [.cold, .cloudy],
                imageName: "outfit_confident_2",
                comfortLevel: 3,
                styleLevel: 4
            ),
            // Outfits détendus
            Outfit(
                name: "Week-end Cocooning",
                description: "Parfait pour se détendre à la maison ou en balade",
                type: .weekend,
                top: "Hoodie oversize",
                bottom: "Legging confortable",
                shoes: "Chaussons",
                accessories: ["Chaussettes douillettes"],
                suitableWeather: [.cold, .rainy],
                imageName: "outfit_relaxed_1",
                comfortLevel: 5,
                styleLevel: 2
            ),
            Outfit(
                name: "Flânerie Estivale",
                description: "Léger et aéré pour les journées ensoleillées",
                type: .casual,
                top: "Débardeur en coton",
                bottom: "Short en jean",
                shoes: "Sandales",
                accessories: ["Lunettes de soleil", "Chapeau de paille"],
                suitableWeather: [.sunny, .warm],
                imageName: "outfit_relaxed_2",
                comfortLevel: 5,
                styleLevel: 3
            ),
            // Outfits professionnels
            Outfit(
                name: "Élégance Corporate",
                description: "Look professionnel pour les rendez-vous importants",
                type: .business,
                top: "Veste de costume",
                bottom: "Pantalon droit",
                shoes: "Escarpins noirs",
                accessories: ["Porte-documents", "Montre classique"],
                suitableWeather: [.cloudy, .cold],
                imageName: "outfit_professional_1",
                comfortLevel: 3,
                styleLevel: 5
            ),
            // Outfits créatifs
            Outfit(
                name: "Expression Artistique",
                description: "Libérez votre créativité avec ce look unique",
                type: .casual,
                top: "Veste colorée",
                bottom: "Pantalon original",
                shoes: "Chaussures design",
                accessories: ["Bijoux originaux"],
                suitableWeather: [.sunny, .warm],
                imageName: "outfit_creative_1",
                comfortLevel: 4,
                styleLevel: 5
            )
        ]
    }
}

