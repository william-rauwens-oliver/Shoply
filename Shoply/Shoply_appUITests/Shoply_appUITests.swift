//
//  Shoply_appUITests.swift
//  Shoply_appUITests
//
//  Created by William on 01/11/2025.
//

import XCTest

/// Tests UI pour Shoply
/// Vérifie le bon fonctionnement de l'interface utilisateur
final class Shoply_appUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments.append("--uitesting")
        app.launch()
    }
    
    // MARK: - Tests de navigation
    func testPrivacyConsentFlow() throws {
        // Vérifier que la vue de consentement s'affiche
        let acceptButton = app.buttons["J'accepte"]
        XCTAssertTrue(acceptButton.waitForExistence(timeout: 5), "Le bouton d'acceptation devrait être présent")
        
        // Accepter le consentement
        acceptButton.tap()
        
        // Vérifier que l'écran principal s'affiche
        let shoplyTitle = app.staticTexts["Shoply"]
        XCTAssertTrue(shoplyTitle.waitForExistence(timeout: 5), "L'écran principal devrait s'afficher")
    }
    
    func testMoodSelection() throws {
        // Accepter le consentement si nécessaire
        if app.buttons["J'accepte"].exists {
            app.buttons["J'accepte"].tap()
        }
        
        // Chercher un bouton de sélection d'humeur
        let moodButtons = app.buttons.matching(identifier: "moodButton")
        if moodButtons.count > 0 {
            moodButtons.firstMatch.tap()
            
            // Vérifier la navigation vers la sélection d'outfits
            let outfitTitle = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'outfit'"))
            XCTAssertTrue(outfitTitle.firstMatch.waitForExistence(timeout: 5), "La page de sélection d'outfits devrait s'afficher")
        }
    }
    
    // MARK: - Tests d'accessibilité
    func testAccessibilityLabels() throws {
        if app.buttons["J'accepte"].exists {
            app.buttons["J'accepte"].tap()
        }
        
        // Vérifier que les éléments ont des labels d'accessibilité
        let buttons = app.buttons
        for i in 0..<min(buttons.count, 5) {
            let button = buttons.element(boundBy: i)
            if button.exists {
                XCTAssertFalse(button.label.isEmpty, "Les boutons devraient avoir des labels d'accessibilité")
            }
        }
    }
    
    // MARK: - Tests de recherche
    func testSearchFunctionality() throws {
        if app.buttons["J'accepte"].exists {
            app.buttons["J'accepte"].tap()
        }
        
        // Chercher un champ de recherche si disponible
        let searchFields = app.searchFields
        if searchFields.count > 0 {
            let searchField = searchFields.firstMatch
            searchField.tap()
            searchField.typeText("Dynamique")
            
            // Vérifier que les résultats apparaissent
            let results = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'Dynamique'"))
            XCTAssertGreaterThan(results.count, 0, "La recherche devrait retourner des résultats")
        }
    }
    
    // MARK: - Test de lancement
    func testAppLaunches() throws {
        // Vérifier que l'app se lance correctement
        XCTAssertTrue(app.state == .runningForeground, "L'application devrait être lancée")
    }
}
