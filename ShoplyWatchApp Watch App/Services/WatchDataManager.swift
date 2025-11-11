//
//  WatchDataManager.swift
//  ShoplyWatchApp
//
//  Created by William on 01/11/2025.
//

import Foundation
import Combine
import WatchConnectivity

class WatchDataManager: NSObject, ObservableObject {
    static let shared = WatchDataManager()
    
    @Published var isConnected = false
    @Published var lastSyncDate: Date?
    
    private let appGroupIdentifier = "group.com.william.shoply"
    private var session: WCSession?
    
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            print("WatchConnectivity n'est pas supporté")
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        
        // Activer la session de manière asynchrone
        if session?.activationState != .activated {
            session?.activate()
        }
    }
    
    func startSync() {
        // Synchroniser avec l'app iOS via App Groups
        syncFromAppGroup()
        
        // Attendre que WCSession soit activé avant d'utiliser WatchConnectivity
        if let session = session, session.activationState == .activated {
            // Demander aussi la configuration via WatchConnectivity si disponible
            requestConfigurationStatus()
        }
        
        // Notifier que les données ont été synchronisées
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // MARK: - App Group Synchronization
    private func syncFromAppGroup() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("Impossible d'accéder à l'App Group")
            return
        }
        
        // Forcer la synchronisation
        sharedDefaults.synchronize()
        
        // Synchroniser les données depuis l'App Group
        lastSyncDate = Date()
    }
    
    // MARK: - Wardrobe
    func getWardrobeItems() -> [WatchWardrobeItem] {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = sharedDefaults.data(forKey: "wardrobe_items"),
              let items = try? JSONDecoder().decode([WatchWardrobeItem].self, from: data) else {
            return []
        }
        return items
    }
    
    // MARK: - Chat
    func sendChatMessage(_ message: String) async -> String {
        // Envoyer le message à l'app iOS et recevoir la réponse
        if let session = session, session.isReachable {
            let messageData: [String: Any] = [
                "type": "chat_message",
                "text": message
            ]
            
            return await withCheckedContinuation { continuation in
                session.sendMessage(messageData, replyHandler: { response in
                    if let responseText = response["response"] as? String {
                        continuation.resume(returning: responseText)
                    } else {
                        continuation.resume(returning: "Réponse reçue de l'application iPhone.")
                    }
                }, errorHandler: { error in
                    print("Erreur lors de l'envoi du message: \(error.localizedDescription)")
                    continuation.resume(returning: "Je suis désolé, une erreur s'est produite lors de la communication avec l'application iPhone.")
                })
            }
        }
        
        // Réponse par défaut si la connexion n'est pas disponible
        return "Je suis désolé, je ne peux pas me connecter à l'application iPhone pour le moment. Veuillez ouvrir l'application iPhone pour utiliser le chat complet."
    }
    
    // MARK: - Data Storage
    func saveOutfitSuggestion(_ suggestion: WatchOutfitSuggestion) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return
        }
        
        var suggestions = getSavedSuggestions()
        suggestions.append(suggestion)
        
        if let encoded = try? JSONEncoder().encode(suggestions) {
            sharedDefaults.set(encoded, forKey: "watch_outfit_suggestions")
            sharedDefaults.synchronize()
        }
    }
    
    func getSavedSuggestions() -> [WatchOutfitSuggestion] {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = sharedDefaults.data(forKey: "watch_outfit_suggestions"),
              let suggestions = try? JSONDecoder().decode([WatchOutfitSuggestion].self, from: data) else {
            return []
        }
        return suggestions
    }
    
    // MARK: - User Profile
    func getUserProfile() -> WatchUserProfile {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = sharedDefaults.data(forKey: "user_profile"),
              let profile = try? JSONDecoder().decode(WatchUserProfile.self, from: data) else {
            return WatchUserProfile()
        }
        return profile
    }
    
    func isAppConfigured() -> Bool {
        // Vérifier d'abord si l'App Group est accessible
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            // Essayer aussi de vérifier directement le profil dans UserDefaults standard
            // comme fallback si l'App Group n'est pas encore configuré
            return checkStandardUserDefaults()
        }
        
        // Forcer la synchronisation
        sharedDefaults.synchronize()
        
        // Vérifier si le profil existe dans l'App Group
        if let data = sharedDefaults.data(forKey: "user_profile"),
           let profile = try? JSONDecoder().decode(WatchUserProfile.self, from: data) {
            // Si le prénom existe, l'app est configurée
            if !profile.firstName.isEmpty {
                return true
            }
            return profile.isConfigured
        }
        
        // Si pas de profil dans App Group, vérifier UserDefaults standard
        return checkStandardUserDefaults()
    }
    
    private func checkStandardUserDefaults() -> Bool {
        // Sur watchOS, UserDefaults.standard ne partage pas avec iOS
        // On ne peut pas utiliser cette méthode
        // Retourner false et laisser l'App Group gérer
        return false
    }
    
    // Demander la configuration à l'app iOS via WatchConnectivity
    func requestConfigurationStatus() {
        guard let session = session, session.isReachable else {
            return
        }
        
        let message: [String: Any] = [
            "type": "check_configuration"
        ]
        
        session.sendMessage(message, replyHandler: { response in
            if let isConfigured = response["isConfigured"] as? Bool,
               let firstName = response["firstName"] as? String {
                DispatchQueue.main.async {
                    // Mettre à jour le profil local si reçu
                    if isConfigured {
                        self.saveUserProfileToAppGroup(firstName: firstName, isConfigured: true)
                    }
                }
            }
        }, errorHandler: { error in
            print("Erreur lors de la vérification de configuration: \(error.localizedDescription)")
        })
    }
    
    private func saveUserProfileToAppGroup(firstName: String, isConfigured: Bool) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return
        }
        
        let profile = WatchUserProfile(firstName: firstName, isConfigured: isConfigured)
        if let encoded = try? JSONEncoder().encode(profile) {
            sharedDefaults.set(encoded, forKey: "user_profile")
            sharedDefaults.synchronize()
        }
    }
    
    // MARK: - Outfit History
    func getOutfitHistory() -> [WatchOutfitHistoryItem] {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = sharedDefaults.data(forKey: "outfit_history"),
              let history = try? JSONDecoder().decode([WatchOutfitHistoryItem].self, from: data) else {
            return []
        }
        return history.sorted { $0.date > $1.date }
    }
    
    func getFavoriteOutfits() -> [WatchOutfitHistoryItem] {
        return getOutfitHistory().filter { $0.isFavorite }
    }
    
    // MARK: - Wishlist
    func getWishlistItems() -> [WatchWishlistItem] {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = sharedDefaults.data(forKey: "wishlist_items"),
              let items = try? JSONDecoder().decode([WatchWishlistItem].self, from: data) else {
            return []
        }
        return items.sorted { $0.createdAt > $1.createdAt }
    }
    
    // MARK: - Chat Conversations
    func getChatConversations() -> [WatchChatConversation] {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = sharedDefaults.data(forKey: "chat_conversations"),
              let conversations = try? JSONDecoder().decode([WatchChatConversation].self, from: data) else {
            return []
        }
        return conversations.sorted { $0.lastMessageDate > $1.lastMessageDate }
    }
    
    func getChatConversation(id: UUID) -> WatchChatConversation? {
        return getChatConversations().first { $0.id == id }
    }
}

// MARK: - WCSessionDelegate
extension WatchDataManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = (activationState == .activated)
            
            // Une fois activé, démarrer la synchronisation
            if activationState == .activated {
                self.startSync()
            }
        }
        
        if let error = error {
            print("Erreur d'activation WCSession: \(error.localizedDescription)")
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        // Recevoir des messages de l'app iOS
        if let type = message["type"] as? String {
            switch type {
            case "wardrobe_update":
                // Mettre à jour la garde-robe
                syncFromAppGroup()
            case "outfit_suggestion":
                // Recevoir une suggestion d'outfit
                break
            default:
                break
            }
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // Répondre aux messages de l'app iOS
        replyHandler(["status": "received"])
    }
}

