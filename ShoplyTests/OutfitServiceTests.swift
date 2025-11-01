//
//  OutfitServiceTests.swift
//  ShoplyTests
//
//  Created by William on 01/11/2025.
//

import XCTest
@testable import Shoply

/// Tests unitaires pour OutfitService
/// Couvre la logique métier des outfits
final class OutfitServiceTests: XCTestCase {
    var service: OutfitService!
    
    override func setUp() {
        super.setUp()
        service = OutfitService()
    }
    
    override func tearDown() {
        service = nil
        super.tearDown()
    }
    
    // MARK: - Tests de chargement
    func testLoadOutfits() {
        XCTAssertFalse(service.outfits.isEmpty, "Les outfits devraient être chargés")
        XCTAssertGreaterThan(service.outfits.count, 0, "Il devrait y avoir au moins un outfit")
    }
    
    // MARK: - Tests de filtrage
    func testGetOutfitsForMoodAndWeather() {
        let energeticOutfits = service.getOutfitsFor(mood: .energetic, weather: .sunny)
        XCTAssertFalse(energeticOutfits.isEmpty, "Il devrait y avoir des outfits pour l'humeur énergique")
        
        for outfit in energeticOutfits {
            XCTAssertTrue(outfit.suitableMoods.contains(.energetic), "L'outfit devrait être adapté à l'humeur énergique")
            XCTAssertTrue(outfit.suitableWeather.contains(.sunny), "L'outfit devrait être adapté au temps ensoleillé")
        }
    }
    
    func testSearchOutfits() {
        let results = service.searchOutfits(query: "Dynamique")
        XCTAssertFalse(results.isEmpty, "La recherche devrait retourner des résultats")
        
        let allResults = service.searchOutfits(query: "")
        XCTAssertEqual(allResults.count, service.outfits.count, "Une recherche vide devrait retourner tous les outfits")
    }
    
    // MARK: - Tests de favoris
    func testToggleFavorite() {
        guard let firstOutfit = service.outfits.first else {
            XCTFail("Il devrait y avoir au moins un outfit")
            return
        }
        
        let initialFavoriteState = firstOutfit.isFavorite
        service.toggleFavorite(outfit: firstOutfit)
        
        if let updatedOutfit = service.outfits.first(where: { $0.id == firstOutfit.id }) {
            XCTAssertNotEqual(updatedOutfit.isFavorite, initialFavoriteState, "L'état favori devrait changer")
        }
    }
    
    // MARK: - Tests de statistiques
    func testGetStats() {
        let stats = service.getStats()
        
        XCTAssertGreaterThan(stats.totalOutfits, 0, "Il devrait y avoir au moins un outfit")
        XCTAssertGreaterThanOrEqual(stats.favoritesCount, 0, "Le nombre de favoris ne devrait pas être négatif")
        XCTAssertLessThanOrEqual(stats.favoritesCount, stats.totalOutfits, "Le nombre de favoris ne devrait pas dépasser le total")
    }
    
    // MARK: - Tests de validation des données
    func testOutfitDataIntegrity() {
        for outfit in service.outfits {
            XCTAssertFalse(outfit.name.isEmpty, "Le nom ne devrait pas être vide")
            XCTAssertFalse(outfit.description.isEmpty, "La description ne devrait pas être vide")
            XCTAssertGreaterThanOrEqual(outfit.comfortLevel, 1, "Le niveau de confort devrait être au moins 1")
            XCTAssertLessThanOrEqual(outfit.comfortLevel, 5, "Le niveau de confort devrait être au plus 5")
            XCTAssertGreaterThanOrEqual(outfit.styleLevel, 1, "Le niveau de style devrait être au moins 1")
            XCTAssertLessThanOrEqual(outfit.styleLevel, 5, "Le niveau de style devrait être au plus 5")
            XCTAssertFalse(outfit.suitableMoods.isEmpty, "Il devrait y avoir au moins une humeur adaptée")
            XCTAssertFalse(outfit.suitableWeather.isEmpty, "Il devrait y avoir au moins un type de météo adapté")
        }
    }
}

