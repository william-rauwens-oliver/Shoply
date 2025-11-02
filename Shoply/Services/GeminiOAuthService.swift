//
//  GeminiOAuthService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import AuthenticationServices
import Combine

/// Erreurs OAuth
enum OAuthError: LocalizedError {
    case authenticationFailed
    case tokenExchangeFailed
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .authenticationFailed:
            return "L'authentification OAuth a échoué.".localized
        case .tokenExchangeFailed:
            return "L'échange du code d'autorisation contre un token a échoué.".localized
        case .invalidResponse:
            return "La réponse du serveur OAuth est invalide.".localized
        }
    }
}

/// Service d'authentification OAuth pour Google Gemini
class GeminiOAuthService: ObservableObject {
    static let shared = GeminiOAuthService()
    
    @Published var isAuthenticated = false
    @Published var userEmail: String?
    @Published var accessToken: String?
    
    private let tokenKey = "gemini_oauth_token"
    private let emailKey = "gemini_oauth_email"
    
    // Configuration OAuth Google
    // Note: Pour utiliser OAuth, configurez un OAuth client ID dans Google Cloud Console
    // Pour l'instant, on utilise un flux simplifié qui redirige vers la page de connexion
    private let redirectURI = "com.shoply.app://oauth/callback"
    
    private init() {
        loadStoredCredentials()
    }
    
    func authenticate() async throws {
        // Configuration OAuth Google
        let clientID = getGoogleClientID()
        
        // Vérifier que le Client ID est valide
        if clientID == "YOUR_GOOGLE_CLIENT_ID" || clientID.isEmpty {
            struct ConfigurationError: LocalizedError {
                let message: String
                var errorDescription: String? { message }
            }
            throw ConfigurationError(message: "Le Client ID Google n'est pas configuré. Veuillez configurer GOOGLE_CLIENT_ID dans Info.plist ou utilisez une clé API Gemini directement.")
        }
        
        // Scopes nécessaires pour Gemini
        let scopes = "https://www.googleapis.com/auth/generative-language openid email profile"
        
        // Encoder correctement l'URL
        guard let redirectURIEncoded = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let scopeEncoded = scopes.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw OAuthError.authenticationFailed
        }
        
        let authURLString = "https://accounts.google.com/o/oauth2/v2/auth?" +
            "client_id=\(clientID)&" +
            "redirect_uri=\(redirectURIEncoded)&" +
            "response_type=code&" +
            "scope=\(scopeEncoded)&" +
            "access_type=offline&" +
            "prompt=consent"
        
        guard let authURL = URL(string: authURLString) else {
            throw OAuthError.authenticationFailed
        }
        
        // Utiliser une continuation pour attendre le résultat
        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "com.shoply.app"
            ) { callbackURL, error in
                if let error = error {
                    // Analyser l'erreur pour donner un message plus utile
                    if let nsError = error as NSError? {
                        if nsError.domain == "ASWebAuthenticationSessionErrorDomain" {
                            if nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                                // Utilisateur a annulé - on utilise authenticationFailed
                                continuation.resume(throwing: OAuthError.authenticationFailed)
                                return
                            }
                        }
                    }
                    continuation.resume(throwing: OAuthError.authenticationFailed)
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: OAuthError.authenticationFailed)
                    return
                }
                
                // Vérifier s'il y a une erreur dans le callback
                if let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                   let queryItems = components.queryItems,
                   queryItems.contains(where: { $0.name == "error" }) {
                    continuation.resume(throwing: OAuthError.authenticationFailed)
                    return
                }
                
                // Extraire le code d'autorisation
                guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                      let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
                    continuation.resume(throwing: OAuthError.authenticationFailed)
                    return
                }
                
                // Échanger le code contre un token d'accès
                Task {
                    do {
                        try await self.exchangeCodeForToken(code: code, clientID: clientID)
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
    
    private func exchangeCodeForToken(code: String, clientID: String) async throws {
        let tokenURL = URL(string: "https://oauth2.googleapis.com/token")!
        var request = URLRequest(url: tokenURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        // Obtenir le client secret depuis Info.plist
        let clientSecret = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_SECRET") as? String ?? ""
        
        // Pour les apps iOS, Google recommande d'utiliser un client secret
        // Si non disponible, on peut essayer sans mais cela échouera souvent
        guard !clientSecret.isEmpty else {
            struct ConfigurationError: LocalizedError {
                let message: String
                var errorDescription: String? { message }
            }
            throw ConfigurationError(message: "Le Client Secret Google n'est pas configuré. Ajoutez GOOGLE_CLIENT_SECRET dans Info.plist ou utilisez directement une clé API Gemini depuis Google AI Studio (https://aistudio.google.com/app/apikey).")
        }
        
        guard let redirectURIEncoded = redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            throw OAuthError.authenticationFailed
        }
        
        let body = "client_id=\(clientID)&" +
            "client_secret=\(clientSecret)&" +
            "code=\(code)&" +
            "redirect_uri=\(redirectURIEncoded)&" +
            "grant_type=authorization_code"
        
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuthError.authenticationFailed
        }
        
        // Analyser la réponse
        if httpResponse.statusCode != 200 {
            if let errorData = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let errorDescription = errorData["error_description"] as? String {
                struct ConfigurationError: LocalizedError {
                    let message: String
                    var errorDescription: String? { message }
                }
                throw ConfigurationError(message: "Erreur Google OAuth (\(httpResponse.statusCode)): \(errorDescription)")
            }
            throw OAuthError.authenticationFailed
        }
        
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let accessToken = json["access_token"] as? String else {
            throw OAuthError.authenticationFailed
        }
        
        // Sauvegarder le token d'accès OAuth
        await MainActor.run {
            self.accessToken = accessToken
            self.isAuthenticated = true
            UserDefaults.standard.set(accessToken, forKey: self.tokenKey)
        }
        
        // Récupérer l'email de l'utilisateur
        try await fetchUserEmail(token: accessToken)
    }
    
    private func fetchUserEmail(token: String) async throws {
        let userInfoURL = URL(string: "https://www.googleapis.com/oauth2/v2/userinfo")!
        var request = URLRequest(url: userInfoURL)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let email = json["email"] as? String {
            await MainActor.run {
                self.userEmail = email
                UserDefaults.standard.set(email, forKey: self.emailKey)
            }
        }
    }
    
    private func getGoogleClientID() -> String {
        // Essayer de charger depuis Info.plist, sinon utiliser un client ID par défaut
        // Note: Vous devrez configurer votre propre OAuth client dans Google Cloud Console
        // et ajouter le CLIENT_ID dans Info.plist
        if let clientID = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_ID") as? String {
            return clientID
        }
        // Client ID par défaut pour les tests (vous devrez le remplacer)
        return "YOUR_GOOGLE_CLIENT_ID"
    }
    
    func saveCredentials(token: String, email: String) {
        accessToken = token
        userEmail = email
        isAuthenticated = true
        UserDefaults.standard.set(token, forKey: tokenKey)
        UserDefaults.standard.set(email, forKey: emailKey)
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
}


class OAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = OAuthPresentationContextProvider()
    
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            fatalError("No window available for OAuth")
        }
        return window
    }
}

