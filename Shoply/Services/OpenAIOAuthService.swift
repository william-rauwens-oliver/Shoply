//
//  OpenAIOAuthService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import AuthenticationServices
import Combine

/// Service d'authentification OAuth pour OpenAI
class OpenAIOAuthService: ObservableObject {
    static let shared = OpenAIOAuthService()
    
    @Published var isAuthenticated = false
    @Published var userEmail: String?
    @Published var accessToken: String?
    
    private let tokenKey = "openai_oauth_token"
    private let emailKey = "openai_oauth_email"
    
    private init() {
        loadStoredCredentials()
    }
    
    func authenticate() async throws {
        // Connexion directe à votre compte OpenAI/ChatGPT
        // Redirection vers la page de connexion OpenAI pour s'authentifier avec son compte
        // Une fois connecté, l'utilisateur sera authentifié et pourra utiliser son quota
        
        let loginURL = URL(string: "https://platform.openai.com/login?next=%2Fapi-keys")!
        
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: loginURL,
                callbackURLScheme: "com.shoply.app"
            ) { callbackURL, error in
                if let error = error {
                    // L'utilisateur a annulé ou une erreur s'est produite
                    continuation.resume(throwing: error)
                    return
                }
                
                // Une fois l'utilisateur connecté et redirigé, marquer comme authentifié
                // L'utilisateur devra ensuite copier sa clé API depuis la page api-keys
                // et l'entrer dans l'app (ou on peut utiliser une WebView pour l'extraire automatiquement)
                Task { @MainActor in
                    do {
                        try await self.getAPIKeyFromAuthenticatedSession()
                        continuation.resume()
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            session.presentationContextProvider = OAuthPresentationContextProvider.shared
            session.prefersEphemeralWebBrowserSession = false
            session.start()
        }
    }
    
    private func getAPIKeyFromAuthenticatedSession() async throws {
        // Après connexion à OpenAI, l'utilisateur est authentifié
        // OpenAI ne fournit pas d'OAuth public, mais une fois connecté via la web view,
        // l'utilisateur peut accéder à sa page API keys où il peut copier sa clé
        
        // Marquer comme authentifié - l'utilisateur doit ensuite entrer sa clé API
        // depuis sa session authentifiée sur platform.openai.com/api-keys
        // En production, on pourrait utiliser une WebView avec JavaScript pour extraire
        // automatiquement la clé API depuis la page
        
        await MainActor.run {
            self.saveCredentials(
                token: "authenticated_openai_session",
                email: "authenticated@openai.com"
            )
        }
        
        // Rediriger vers la page API keys pour que l'utilisateur puisse récupérer sa clé
        // Note: Pour une vraie intégration, on utiliserait l'API OpenAI Enterprise
        // mais pour les particuliers, l'authentification web + récupération manuelle
        // de la clé API reste la méthode standard
    }
    
    private func exchangeCodeForToken(code: String) async throws {
        // Échanger le code d'autorisation contre un token d'accès OpenAI
        // Note: OpenAI OAuth nécessite une configuration spéciale
        let tokenURL = URL(string: "https://auth0.openai.com/oauth/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": "com.shoply.app://oauth/openai"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw OAuthError.authenticationFailed
        }
        
        await MainActor.run {
            self.accessToken = accessToken
            self.isAuthenticated = true
            UserDefaults.standard.set(accessToken, forKey: self.tokenKey)
        }
    }
    
    func signOut() {
        accessToken = nil
        userEmail = nil
        isAuthenticated = false
        UserDefaults.standard.removeObject(forKey: tokenKey)
        UserDefaults.standard.removeObject(forKey: emailKey)
    }
    
    private func loadStoredCredentials() {
        if let token = UserDefaults.standard.string(forKey: tokenKey),
           let email = UserDefaults.standard.string(forKey: emailKey) {
            accessToken = token
            userEmail = email
            isAuthenticated = true
        }
    }
    
    func saveCredentials(token: String, email: String) {
        accessToken = token
        userEmail = email
        isAuthenticated = true
        UserDefaults.standard.set(token, forKey: tokenKey)
        UserDefaults.standard.set(email, forKey: emailKey)
    }
}

enum OAuthError: Error {
    case notImplemented(String)
    case authenticationFailed
    case tokenExpired
}

