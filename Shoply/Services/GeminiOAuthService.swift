//
//  GeminiOAuthService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import AuthenticationServices
import Combine

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
        // Utiliser Google Sign-In pour obtenir un token OAuth automatiquement
        // On utilise l'API Google OAuth 2.0 avec le flux Authorization Code
        
        // Configuration OAuth Google - utilise le client ID par défaut du bundle
        let clientID = getGoogleClientID()
        let scopes = "https://www.googleapis.com/auth/generative-language"
        let authURLString = "https://accounts.google.com/o/oauth2/v2/auth?" +
            "client_id=\(clientID)&" +
            "redirect_uri=\(redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&" +
            "response_type=code&" +
            "scope=\(scopes.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&" +
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
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let callbackURL = callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
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
        
        // Pour utiliser Google OAuth avec Gemini, on a besoin d'un client secret
        // Pour les apps publiques, on peut utiliser PKCE mais Google nécessite souvent un client secret
        // Pour simplifier, on récupère un access token qui peut être utilisé avec l'API Gemini
        
        // Obtenir le client secret depuis Info.plist si disponible
        let clientSecret = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_CLIENT_SECRET") as? String ?? ""
        
        var body = "client_id=\(clientID)&" +
            "code=\(code)&" +
            "redirect_uri=\(redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&" +
            "grant_type=authorization_code"
        
        if !clientSecret.isEmpty {
            body += "&client_secret=\(clientSecret)"
        }
        
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw OAuthError.authenticationFailed
        }
        
        if httpResponse.statusCode == 200,
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let accessToken = json["access_token"] as? String {
            
            // Sauvegarder le token d'accès OAuth
            await MainActor.run {
                self.accessToken = accessToken
                self.isAuthenticated = true
                UserDefaults.standard.set(accessToken, forKey: self.tokenKey)
            }
            
            // Récupérer l'email de l'utilisateur
            try await fetchUserEmail(token: accessToken)
        } else {
            // Si l'échange échoue, cela peut être dû à l'absence de client secret
            // Dans ce cas, on peut quand même marquer comme authentifié et utiliser
            // une clé API générée par l'utilisateur depuis Google AI Studio
            throw OAuthError.authenticationFailed
        }
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

