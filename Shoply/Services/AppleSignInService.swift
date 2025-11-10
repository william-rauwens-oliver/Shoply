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
    
    // Conserver une référence au contrôleur pour éviter qu'il soit libéré
    private var authorizationController: ASAuthorizationController?
    
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
        // Récupérer l'email sauvegardé
        if let savedEmail = UserDefaults.standard.string(forKey: "apple_user_email") {
            self.userEmail = savedEmail
        }
        self.isAuthenticated = true
        
        // Mettre à jour le profil avec l'email si disponible
        if let email = self.userEmail, var profile = self.dataManager.loadUserProfile() {
            profile.email = email
            self.dataManager.saveUserProfile(profile)
        }
        
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
        
        // S'assurer qu'on est sur le thread principal
        guard Thread.isMainThread else {
            DispatchQueue.main.async { [weak self] in
                self?.signInWithApple()
            }
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        // Créer la requête d'authentification
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]

        // Créer le contrôleur d'autorisation
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        
        // Conserver une référence pour éviter la libération
        self.authorizationController = controller

        // Lancer la demande immédiatement sur le thread principal
        print("🚀 Lancement de performRequests()...")
        controller.performRequests()
        
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
        guard isAuthenticated, userIdentifier != nil else { return }
        
        isLoading = true
        
        do {
            // Vérifier si des données existent dans iCloud pour cet utilisateur
            let hasDataInCloud = try await cloudKitService.checkIfDataExists()
            
            if hasDataInCloud {
                // Récupérer les données depuis iCloud
                try await restoreFromiCloud()
                
                // Après restauration, vérifier si le profil est complet
                if let profile = dataManager.loadUserProfile(),
                   !profile.firstName.isEmpty {
                    // Profil complet - l'utilisateur ira directement à l'accueil
                    // La logique dans ShoplyApp.swift détectera que onboardingCompleted est true
                    await MainActor.run {
                        isLoading = false
                    }
                    return
                }
            } else {
                // Pas de données dans iCloud, vérifier le profil local
                if let profile = dataManager.loadUserProfile(),
                   !profile.firstName.isEmpty {
                    // Profil local complet, sauvegarder dans iCloud
                try await saveToiCloud()
                    await MainActor.run {
                        isLoading = false
                    }
                    return
                } else {
                    // Pas de profil ou profil incomplet, créer un profil minimal avec l'email
                    if let email = userEmail {
                        let newProfile = UserProfile(email: email)
                        await MainActor.run {
                            dataManager.saveUserProfile(newProfile)
                        }
                    }
                }
            }
            
            // Si on arrive ici, le profil est incomplet - l'onboarding sera affiché par ShoplyApp
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

        } catch {
            
            // Ne pas faire crasher l'app si la restauration échoue
        }
    }
    
    private func saveToiCloud() async throws {
        // Sauvegarder toutes les données locales dans iCloud de manière sécurisée
        do {
            try await cloudKitService.syncAllUserData()
            
        } catch {
            
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
            var email = appleIDCredential.email

            print("✅ Email: \(email ?? "non fourni")")
            
            // Si l'email n'est pas fourni (première connexion uniquement), récupérer depuis UserDefaults
            if email == nil {
                email = UserDefaults.standard.string(forKey: "apple_user_email")
                print("ℹ️ Email récupéré depuis UserDefaults: \(email ?? "aucun")")
            }
            
            // Sauvegarder l'identifiant et l'email
            UserDefaults.standard.set(userIdentifier, forKey: "apple_user_identifier")
            if let email = email {
                UserDefaults.standard.set(email, forKey: "apple_user_email")
            }
            
            DispatchQueue.main.async {
                self.userIdentifier = userIdentifier
                self.userEmail = email
                self.isAuthenticated = true
                self.isLoading = false

                // Mettre à jour le profil avec l'email si disponible
                if let email = email, var profile = self.dataManager.loadUserProfile() {
                    profile.email = email
                    self.dataManager.saveUserProfile(profile)
                    
                } else if let email = email {
                    // Si pas de profil mais email disponible, créer un profil minimal avec l'email
                    let newProfile = UserProfile(email: email)
                    self.dataManager.saveUserProfile(newProfile)
                    
                }
                
                // Vérifier le statut iCloud
                self.cloudKitService.checkAccountStatus()
                
                // Synchroniser les données
                Task {
                    await self.syncUserDataIfNeeded()
                }
            }
        } else {
            
        }
    }
    
    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {

        DispatchQueue.main.async {
            self.isLoading = false
            
            // Log détaillé de l'erreur pour le débogage
            let nsError = error as NSError
            
            print("   Code: \(nsError.code)")
            print("   Domain: \(nsError.domain)")
            print("   Description: \(error.localizedDescription)")
            print("   UserInfo: \(nsError.userInfo)")
            
            if let authError = error as? ASAuthorizationError {
                print("   Type: ASAuthorizationError")
                print("   Code d'erreur: \(authError.code.rawValue)")
                
                switch authError.code {
                case .canceled:
                    // L'utilisateur a annulé, pas d'erreur à afficher
                    self.errorMessage = nil
                    print("ℹ️ Utilisateur a annulé la connexion")
                case .failed:
                    self.errorMessage = "Échec de la connexion. Veuillez réessayer.".localized
                    
                case .invalidResponse:
                    // Message plus doux pour les comptes gratuits
                    self.errorMessage = "Apple Sign In n'est pas disponible avec un compte développeur gratuit. Vous pouvez continuer sans connexion Apple.".localized
                    
                case .notHandled:
                    // Message plus doux pour les comptes gratuits
                    self.errorMessage = "Apple Sign In n'est pas disponible avec un compte développeur gratuit. Vous pouvez continuer sans connexion Apple.".localized
                    
                case .unknown:
                    // Erreur 1000 - souvent due à une configuration manquante (compte gratuit)
                    self.errorMessage = "Apple Sign In nécessite un compte développeur payant. Vous pouvez continuer sans connexion Apple pour utiliser l'application.".localized
                    
                default:
                    // Gérer tous les autres cas (notInteractive, credentialExport, credentialImport, matchedExcludedCredential, etc.)
                    self.errorMessage = "Erreur d'authentification: \(error.localizedDescription)".localized
                    
                }
            } else {
                // Erreur 1000 ou autres erreurs
                let errorCode = nsError.code
                
                if errorCode == 1000 {
                    // Erreur 1000 = compte gratuit - message plus clair
                    self.errorMessage = "Apple Sign In nécessite un compte développeur payant. Continuez sans connexion pour utiliser l'application normalement.".localized
                } else {
                    // Autres erreurs - message générique mais pas trop technique
                    self.errorMessage = "Impossible de se connecter avec Apple Sign In. Vous pouvez continuer sans connexion Apple.".localized
                }
            }
        }
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInService: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        // Méthode simplifiée et plus fiable pour obtenir la fenêtre de présentation
        guard let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) ?? UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first else {
            // Fallback pour versions plus anciennes ou scénarios spéciaux
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first(where: { $0.isKeyWindow }) {
                
                return window
            }
            // Dernier recours : créer une fenêtre
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let window = UIWindow(windowScene: windowScene)
                window.makeKeyAndVisible()
                return window
            }
            // Si vraiment rien ne fonctionne, utiliser UIScreen
            let window = UIWindow(frame: UIScreen.main.bounds)
            window.makeKeyAndVisible()
            return window
        }
        
        // Obtenir la fenêtre clé de la scène
        if let keyWindow = windowScene.windows.first(where: { $0.isKeyWindow }) {
            
            return keyWindow
        }
        
        // Sinon prendre la première fenêtre de la scène
        if let firstWindow = windowScene.windows.first {
            
            return firstWindow
        }
        
        // Dernier recours : créer une fenêtre pour cette scène
        
        let window = UIWindow(windowScene: windowScene)
        window.makeKeyAndVisible()
        return window
    }
}

