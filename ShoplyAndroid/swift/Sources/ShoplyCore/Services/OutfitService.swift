//
//  OutfitService.swift
//  ShoplyCore - Android Compatible
//
//  Service métier - Gère la logique métier des outfits

import Foundation

/// Service métier - Gère la logique métier des outfits
public class OutfitService {
    public static let shared = OutfitService()
    
    public var outfits: [Outfit] = []
    public var isLoading = false
    public var error: Error?
    
    private let dataManager = DataManager.shared
    
    private init() {
        loadOutfits()
    }
    
    // MARK: - Chargement des données
    public func loadOutfits() {
        isLoading = true
        defer { isLoading = false }
        
        // Charger depuis les données par défaut
        outfits = OutfitFactory.createDefaultOutfits()
        
        // Synchroniser avec les favoris sauvegardés
        syncFavorites()
    }
    
    // MARK: - Gestion des favoris
    public func toggleFavorite(outfit: Outfit) {
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
    public func getOutfitsFor(mood: Mood, weather: WeatherType) -> [Outfit] {
        return outfits.filter { outfit in
            outfit.suitableMoods.contains(mood) && outfit.suitableWeather.contains(weather)
        }
    }
    
    public func getFavorites() -> [Outfit] {
        return outfits.filter { $0.isFavorite }
    }
    
    public func searchOutfits(query: String) -> [Outfit] {
        guard !query.isEmpty else { return outfits }
        
        return outfits.filter { outfit in
            outfit.name.localizedCaseInsensitiveContains(query) ||
            outfit.description.localizedCaseInsensitiveContains(query) ||
            outfit.type.rawValue.localizedCaseInsensitiveContains(query)
        }
    }
    
    // MARK: - Statistiques
    public func getStats() -> OutfitStats {
        let total = outfits.count
        let favorites = outfits.filter { $0.isFavorite }.count
        let mostPopularMood = getMostPopularMood()
        
        return OutfitStats(
            totalOutfits: total,
            favoritesCount: favorites,
            mostPopularMood: mostPopularMood
        )
    }
    
    private func getMostPopularMood() -> Mood {
        var moodCounts: [Mood: Int] = [:]
        
        for outfit in outfits {
            for mood in outfit.suitableMoods {
                moodCounts[mood, default: 0] += 1
            }
        }
        
        return moodCounts.max(by: { $0.value < $1.value })?.key ?? .energetic
    }
}

/// Structure pour les statistiques
public struct OutfitStats {
    public let totalOutfits: Int
    public let favoritesCount: Int
    public let mostPopularMood: Mood
    
    public init(totalOutfits: Int, favoritesCount: Int, mostPopularMood: Mood) {
        self.totalOutfits = totalOutfits
        self.favoritesCount = favoritesCount
        self.mostPopularMood = mostPopularMood
    }
}

/// Factory pour créer les outfits par défaut (identique iOS)
public struct OutfitFactory {
    public static func createDefaultOutfits() -> [Outfit] {
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
                suitableMoods: [.energetic, .creative],
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
                suitableMoods: [.energetic, .relaxed],
                suitableWeather: [.cloudy, .warm],
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
                suitableMoods: [.calm, .relaxed],
                suitableWeather: [.cloudy, .cold],
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
                suitableMoods: [.calm, .professional],
                suitableWeather: [.sunny, .warm],
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
                suitableMoods: [.confident, .professional],
                suitableWeather: [.sunny, .cloudy],
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
                suitableMoods: [.confident, .creative],
                suitableWeather: [.cold, .cloudy],
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
                suitableMoods: [.relaxed, .calm],
                suitableWeather: [.cold, .rainy],
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
                suitableMoods: [.relaxed, .energetic],
                suitableWeather: [.sunny, .warm],
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
                suitableMoods: [.professional, .confident],
                suitableWeather: [.cloudy, .cold],
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
                suitableMoods: [.creative, .confident],
                suitableWeather: [.sunny, .warm],
                comfortLevel: 4,
                styleLevel: 5
            )
        ]
    }
}

