//
//  WatchDataManager.swift
//  ShoplyWatchApp
//
//  Created by William on 01/11/2025.
//

import Foundation
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
        session?.activate()
    }
    
    func startSync() {
        // Synchroniser avec l'app iOS via App Groups
        syncFromAppGroup()
    }
    
    // MARK: - App Group Synchronization
    private func syncFromAppGroup() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("Impossible d'accéder à l'App Group")
            return
        }
        
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
            
            do {
                let response = try await session.sendMessage(messageData, replyHandler: { response in
                    // La réponse sera gérée dans le delegate
                }, errorHandler: { error in
                    print("Erreur lors de l'envoi du message: \(error.localizedDescription)")
                })
                
                if let responseText = response["response"] as? String {
                    return responseText
                }
            } catch {
                print("Erreur: \(error.localizedDescription)")
            }
        }
        
        // Réponse par défaut si la connexion n'est pas disponible
        return "Je suis désolé, je ne peux pas me connecter à l'application iPhone pour le moment. Veuillez ouvrir l'application iPhone pour utiliser le chat complet."
    }
    
    // MARK: - Data Storage
    func saveOutfitSuggestion(_ suggestion: WatchOutfitSuggestion) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier),
              let data = try? JSONEncoder().encode(suggestion) else {
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
}

// MARK: - WCSessionDelegate
extension WatchDataManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = (activationState == .activated)
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

