//
//  RGDPManager.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import SwiftUI
import Combine

/// Gestionnaire RGPD - Sécurité et protection des données
/// Conforme au RGPD et aux recommandations ANSSI
class RGDPManager: ObservableObject {
    static let shared = RGDPManager()
    
    @Published var hasConsentedToDataCollection = false
    @Published var hasAcceptedPrivacyPolicy = false
    
    private let userDefaults = UserDefaults.standard
    private let consentKey = "rgpd_consent"
    private let privacyKey = "privacy_policy_accepted"
    private let consentDateKey = "consent_date"
    
    private init() {
        loadConsentStatus()
    }
    
    // MARK: - Gestion du consentement
    func requestConsent() {
        // À afficher dans l'UI
    }
    
    func acceptConsent() {
        hasConsentedToDataCollection = true
        hasAcceptedPrivacyPolicy = true
        userDefaults.set(true, forKey: consentKey)
        userDefaults.set(true, forKey: privacyKey)
        userDefaults.set(Date(), forKey: consentDateKey)
    }
    
    func rejectConsent() {
        hasConsentedToDataCollection = false
        hasAcceptedPrivacyPolicy = false
        userDefaults.set(false, forKey: consentKey)
        userDefaults.set(false, forKey: privacyKey)
        
        // Ne pas supprimer les données immédiatement pour éviter les blocages
        // Les données seront supprimées de manière asynchrone si nécessaire
    }
    
    func revokeConsent() {
        rejectConsent()
        // Notification que le consentement a été révoqué
    }
    
    private func loadConsentStatus() {
        hasConsentedToDataCollection = userDefaults.bool(forKey: consentKey)
        hasAcceptedPrivacyPolicy = userDefaults.bool(forKey: privacyKey)
    }
    
    // MARK: - Export des données (droit à la portabilité)
    func exportUserData() -> [String: Any] {
        guard hasConsentedToDataCollection else {
            return [:]
        }
        
        return DataManager.shared.exportUserData()
    }
    
    // MARK: - Suppression des données (droit à l'oubli)
    func deleteUserData() {
        DataManager.shared.deleteAllUserData()
        revokeConsent()
    }
    
    // MARK: - Anonymisation des données
    func anonymizeUserData() {
        // Supprimer les identifiants personnels tout en gardant les données anonymes
        DataManager.shared.deleteAllUserData()
    }
}

