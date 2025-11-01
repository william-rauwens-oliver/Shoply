//
//  RGDPManagerTests.swift
//  ShoplyTests
//
//  Created by William on 01/11/2025.
//

import XCTest
@testable import Shoply

/// Tests unitaires pour RGDPManager
/// Vérifie la conformité RGPD
final class RGDPManagerTests: XCTestCase {
    var manager: RGDPManager!
    
    override func setUp() {
        super.setUp()
        // Réinitialiser les préférences pour les tests
        UserDefaults.standard.removeObject(forKey: "rgpd_consent")
        UserDefaults.standard.removeObject(forKey: "privacy_policy_accepted")
        manager = RGDPManager.shared
    }
    
    override func tearDown() {
        // Nettoyer après les tests
        UserDefaults.standard.removeObject(forKey: "rgpd_consent")
        UserDefaults.standard.removeObject(forKey: "privacy_policy_accepted")
        super.tearDown()
    }
    
    // MARK: - Tests de consentement
    func testInitialConsentState() {
        XCTAssertFalse(manager.hasConsentedToDataCollection, "Le consentement initial devrait être false")
    }
    
    func testAcceptConsent() {
        manager.acceptConsent()
        XCTAssertTrue(manager.hasConsentedToDataCollection, "Le consentement devrait être accepté")
        XCTAssertTrue(manager.hasAcceptedPrivacyPolicy, "La politique de confidentialité devrait être acceptée")
    }
    
    func testRejectConsent() {
        manager.acceptConsent()
        manager.rejectConsent()
        XCTAssertFalse(manager.hasConsentedToDataCollection, "Le consentement devrait être refusé")
        XCTAssertFalse(manager.hasAcceptedPrivacyPolicy, "La politique de confidentialité devrait être refusée")
    }
    
    func testRevokeConsent() {
        manager.acceptConsent()
        manager.revokeConsent()
        XCTAssertFalse(manager.hasConsentedToDataCollection, "Le consentement devrait être révoqué")
    }
    
    // MARK: - Tests d'export de données
    func testExportUserData() {
        manager.acceptConsent()
        let data = manager.exportUserData()
        
        XCTAssertNotNil(data, "L'export de données ne devrait pas être nil")
        XCTAssertTrue(data is [String: Any], "L'export devrait être un dictionnaire")
    }
    
    // MARK: - Tests de suppression de données
    func testDeleteUserData() {
        manager.acceptConsent()
        manager.deleteUserData()
        XCTAssertFalse(manager.hasConsentedToDataCollection, "Le consentement devrait être révoqué après suppression")
    }
}

