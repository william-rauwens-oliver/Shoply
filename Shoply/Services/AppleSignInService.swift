//
//  AppleSignInService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 02/11/2025.
//

import Foundation
import AuthenticationServices
import CloudKit
import Combine

/// Service pour l'authentification Apple Sign In et synchronisation iCloud
class AppleSignInService: NSObject, ObservableObject {
    static let shared = AppleSignInService()
    
    @Published var isAuthenticated = false
    @Published var userIdentifier: String?
    @Published var userEmail: String?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // Services - initialisés de manière lazy pour éviter les problèmes au démarrage
    private var cloudKitService: CloudKitService {
        return CloudKitService.shared
    }
    
    private var dataManager: DataManager {
        return DataManager.shared
    }
    
    private override init() {
        super.init()
        // Vérifier si l'utilisateur est déjà authentifié de manière asynchrone
        // Utiliser un délai pour s'assurer que tous les services sont initialisés
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
            self?.checkAuthenticationStatus()
        }
    }
    
    // MARK: - Vérification du statut
    
    private func checkAuthenticationStatus() {
        // Vérifier si un identifiant Apple est stocké
        guard let storedIdentifier = UserDefaults.standard.string(forKey: "apple_user_identifier"),
              !storedIdentifier.isEmpty else {
            return
        }
        
        self.userIdentifier = storedIdentifier
        self.isAuthenticated = true
        
        // Vérifier le statut iCloud de manière sécurisée avec un délai
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else { return }
            // checkAccountStatus ne lance pas d'erreur, appel direct
            self.cloudKitService.checkAccountStatus()
        }
    }
    
    // MARK: - Authentification
    
    func signInWithApple() {
        print("🔐 Tentative de connexion Apple Sign In...")
        
        DispatchQueue.main.async {
            self.isLoading = true
            self.errorMessage = nil
        }
        
        // Créer la requête d'authentification
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        print("✅ Requête créée avec scopes: fullName, email")
        
        // Créer le contrôleur d'autorisation
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        
        print("✅ Contrôleur créé avec delegate et presentationContextProvider")
        
        // Vérifier que la fenêtre est disponible
        let anchor = presentationAnchor(for: authorizationController)
        print("✅ Fenêtre obtenue: \(anchor)")
        
        // Lancer la demande sur le thread principal immédiatement
        DispatchQueue.main.async {
            guard Thread.isMainThread else {
                print("❌ Pas sur le thread principal")
                self.isLoading = false
                self.errorMessage = "Erreur de thread. Veuillez réessayer.".localized
                return
            }
            
            print("🚀 Lancement de performRequests()...")
            // Lancer la demande d'autorisation
            authorizationController.performRequests()
        }
    }
    
    func signOut() {
        UserDefaults.standard.removeObject(forKey: "apple_user_identifier")
        UserDefaults.standard.removeObject(forKey: "apple_user_email")
        isAuthenticated = false
        userIdentifier = nil
        userEmail = nil
    }
    
    // MARK: - Synchronisation iCloud
    
    func syncUserDataIfNeeded() async {
        guard isAuthenticated, let identifier = userIdentifier else { return }
        
        isLoading = true
        
        do {
            // Vérifier si des données existent dans iCloud pour cet utilisateur
            let hasDataInCloud = try await cloudKitService.checkIfDataExists()
            
            if hasDataInCloud {
                // Récupérer les données depuis iCloud
                try await restoreFromiCloud()
            } else {
                // Sauvegarder les données locales dans iCloud
                try await saveToiCloud()
            }
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                isLoading = false
                errorMessage = "Erreur de synchronisation: \(error.localizedDescription)".localized
            }
        }
    }
    
    private func restoreFromiCloud() async throws {
        // Charger toutes les données depuis iCloud de manière sécurisée
        do {
            if let profile = try await cloudKitService.loadUserProfile() {
                await MainActor.run {
                    dataManager.saveUserProfile(profile)
                }
            }
            
            let wardrobeItems = try await cloudKitService.loadWardrobe()
            await MainActor.run {
                dataManager.saveWardrobeItems(wardrobeItems)
            }
            
            let conversations = try await cloudKitService.loadConversations()
            if let data = try? JSONEncoder().encode(conversations) {
                UserDefaults.standard.set(data, forKey: "chatConversations")
            }
            
            let history = try await cloudKitService.loadOutfitHistory()
            await MainActor.run {
                let historyStore = OutfitHistoryStore()
                for historicalOutfit in history {
                    // addOutfit attend un MatchedOutfit et une Date, pas un HistoricalOutfit
                    historyStore.addOutfit(historicalOutfit.outfit, date: historicalOutfit.dateWorn)
                }
            }
            
            print("✅ Données restaurées depuis iCloud")
        } catch {
            print("⚠️ Erreur lors de la restauration depuis iCloud: \(error)")
            // Ne pas faire crasher l'app si la restauration échoue
        }
    }
    
    private func saveToiCloud() async throws {
        // Sauvegarder toutes les données locales dans iCloud de manière sécurisée
        do {
            try await cloudKitService.syncAllUserData()
            print("✅ Données sauvegardées dans iCloud")
        } catch {
            print("⚠️ Erreur lors de la sauvegarde dans iCloud: \(error)")
            // Ne pas faire crasher l'app si la sauvegarde échoue
            throw error
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInService: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            let userIdentifier = appleIDCredential.user
            let email = appleIDCredential.email
            
            // Sauvegarder l'identifiant
            UserDefaults.standard.set(userIdentifier, forKey: "apple_user_identifier")
            if let email = email {
                UserDefaults.standard.set(email, forKey: "apple_user_email")
            }
            
            DispatchQueue.main.async {
                self.userIdentifier = userIdentifier
                self.userEmail = email
                self.isAuthenticated = true
                self.isLoading = false
                
                // Vérifier le statut iCloud
                self.cloudKitService.checkAccountStatus()
                
                // Synchroniser les données
                Task {
                    await self.syncUserDataIfNeeded()
                }
            }
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        DispatchQueue.main.async {
            self.isLoading = false
            
            // Log détaillé de l'erreur pour le débogage
            let nsError = error as NSError
            print("❌ Erreur Apple Sign In:")
            print("   Code: \(nsError.code)")
            print("   Domain: \(nsError.domain)")
            print("   Description: \(error.localizedDescription)")
            if let userInfo = nsError.userInfo as? [String: Any] {
                print("   UserInfo: \(userInfo)")
            }
            
            if let authError = error as? ASAuthorizationError {
                switch authError.code {
                case .canceled:
                    // L'utilisateur a annulé, pas d'erreur à afficher
                    self.errorMessage = nil
                    print("ℹ️ Utilisateur a annulé la connexion")
                case .failed:
                    self.errorMessage = "Échec de la connexion. Veuillez réessayer.".localized
                case .invalidResponse:
                    self.errorMessage = "Réponse invalide. Vérifiez que 'Sign in with Apple' est activé dans les paramètres Xcode (Capabilities).".localized
                case .notHandled:
                    self.errorMessage = "Connexion non gérée. Vérifiez que 'Sign in with Apple' est activé dans les paramètres Xcode (Capabilities).".localized
                case .unknown:
                    // Erreur 1000 - souvent due à une configuration manquante
                    self.errorMessage = "Apple Sign In n'est pas configuré. Activez la capability 'Sign in with Apple' dans Xcode (Target → Signing & Capabilities → + Capability).".localized
                @unknown default:
                    self.errorMessage = "Erreur inconnue: \(error.localizedDescription). Code: \(nsError.code)".localized
                }
            } else {
                // Erreur 1000 ou autres erreurs
                let errorCode = nsError.code
                if errorCode == 1000 {
                    self.errorMessage = "Configuration manquante. Activez 'Sign in with Apple' dans Xcode (Target → Signing & Capabilities → + Capability → Sign in with Apple).".localized
                } else {
                    self.errorMessage = "Erreur \(errorCode): \(error.localizedDescription)".localized
                }
            }
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Utiliser la scène active pour obtenir la fenêtre
        // Essayer d'abord avec les scènes connectées (iOS 13+)
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first {
            
            // Priorité à la fenêtre clé
            if let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
                print("✅ Fenêtre clé trouvée: \(keyWindow)")
                return keyWindow
            }
            
            // Sinon prendre la première fenêtre
            if let firstWindow = windowScene.windows.first {
                print("✅ Première fenêtre trouvée: \(firstWindow)")
                return firstWindow
            }
        }
        
        // Fallback pour versions iOS plus anciennes ou simulateur
        print("⚠️ Utilisation du fallback pour obtenir la fenêtre")
        if #available(iOS 13.0, *) {
            // Essayer avec UIApplication.shared.windows (deprecated mais peut fonctionner)
            if let window = UIApplication.shared.windows.first(where: { $0.isKeyWindow }) {
                return window
            }
        }
        
        // Dernier recours : créer une nouvelle fenêtre
        print("⚠️ Création d'une nouvelle fenêtre comme dernier recours")
        return UIWindow(frame: UIScreen.main.bounds)
    }
}

