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
    private(set) var session: WCSession? // Exposé en lecture seule pour ContentView
    
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
    
    private var lastSyncTime: Date?
    private let minSyncInterval: TimeInterval = 2.0 // Minimum 2 secondes entre deux syncs
    
    func startSync() {
        // Éviter les appels trop fréquents pour éviter les boucles
        if let lastSync = lastSyncTime, Date().timeIntervalSince(lastSync) < minSyncInterval {
            print("⏸️ Watch: Synchronisation ignorée (trop récente)")
            return
        }
        
        lastSyncTime = Date()
        print("🔄 Watch: Démarrage de la synchronisation")
        
        // Synchroniser avec l'app iOS via App Groups
        syncFromAppGroup()
        
        // Attendre que WCSession soit activé avant d'utiliser WatchConnectivity
        if let session = session {
            if session.activationState == .activated && session.isReachable {
                print("✅ Watch: WCSession activé et reachable, demande de configuration")
                // Demander aussi la configuration via WatchConnectivity si disponible
                requestConfigurationStatus()
            } else {
                print("⚠️ Watch: WCSession non activé ou non reachable (état: \(session.activationState.rawValue), reachable: \(session.isReachable))")
                // Réessayer d'activer la session si elle n'est pas en cours d'activation
                if session.activationState == .notActivated {
                    session.activate()
                }
            }
        } else {
            print("⚠️ Watch: WCSession non initialisé")
        }
        
        // Notifier que les données ont été synchronisées
        DispatchQueue.main.async {
            self.lastSyncDate = Date()
            self.objectWillChange.send()
        }
    }
    
    // MARK: - App Group Synchronization
    private func syncFromAppGroup() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("Impossible d'accéder à l'App Group")
            return
        }
        
        // Forcer la synchronisation plusieurs fois pour s'assurer que les données sont à jour
        sharedDefaults.synchronize()
        
        // Attendre un court instant pour laisser le temps à la synchronisation
        Thread.sleep(forTimeInterval: 0.1)
        
        // Synchroniser à nouveau
        sharedDefaults.synchronize()
        
        // Synchroniser les données depuis l'App Group
        DispatchQueue.main.async {
            self.lastSyncDate = Date()
        }
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
        print("🔍 Watch: ========== VÉRIFICATION CONFIGURATION ==========")
        
        // Vérifier d'abord si l'App Group est accessible
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("❌ Watch: CRITIQUE - App Group non accessible: \(appGroupIdentifier)")
            print("   → ACTION REQUISE: Vérifiez dans Xcode:")
            print("      1. Sélectionnez le target Watch App")
            print("      2. Allez dans 'Signing & Capabilities'")
            print("      3. Ajoutez la capability 'App Groups' si elle n'existe pas")
            print("      4. Cochez 'group.com.william.shoply'")
            return false
        }
        
        print("✅ Watch: App Group accessible")
        
        // Forcer la synchronisation plusieurs fois
        sharedDefaults.synchronize()
        Thread.sleep(forTimeInterval: 0.1)
        sharedDefaults.synchronize()
        
        // Vérifier si le profil existe dans l'App Group
        guard let data = sharedDefaults.data(forKey: "user_profile") else {
            print("⚠️ Watch: Aucune donnée 'user_profile' dans l'App Group")
            print("   → Les données n'ont peut-être pas été synchronisées depuis iOS")
            print("   → Vérifiez les logs iOS pour voir si la synchronisation a réussi")
            return false
        }
        
        print("✅ Watch: Données 'user_profile' trouvées - Taille: \(data.count) bytes")
        
        guard let profile = try? JSONDecoder().decode(WatchUserProfile.self, from: data) else {
            print("❌ Watch: Impossible de décoder le profil Watch")
            // Nettoyer les données corrompues
            sharedDefaults.removeObject(forKey: "user_profile")
            sharedDefaults.synchronize()
            return false
        }
        
        // Vérifier que le profil est vraiment configuré (prénom non vide ET isConfigured = true)
        let isConfigured = !profile.firstName.isEmpty && profile.isConfigured
        if isConfigured {
            print("✅ Watch: App configurée - Prénom: '\(profile.firstName)', isConfigured: \(profile.isConfigured)")
        } else {
            print("⚠️ Watch: App non configurée - Prénom: '\(profile.firstName)', isConfigured: \(profile.isConfigured)")
            // Nettoyer les données si le profil n'est pas vraiment configuré
            print("🗑️ Watch: Nettoyage des données car le profil n'est pas configuré")
            clearAllWatchData()
        }
        
        print("🔍 Watch: ========== FIN VÉRIFICATION ==========")
        return isConfigured
    }
    
    private func checkStandardUserDefaults() -> Bool {
        // Sur watchOS, UserDefaults.standard ne partage pas avec iOS
        // On ne peut pas utiliser cette méthode
        // Retourner false et laisser l'App Group gérer
        return false
    }
    
    // Demander la configuration à l'app iOS via WatchConnectivity
    func requestConfigurationStatus() {
        guard let session = session else {
            print("⚠️ Watch: WCSession non disponible")
            return
        }
        
        // Vérifier l'état de la session
        // Note: isPaired et isWatchAppInstalled ne sont pas disponibles sur watchOS
        print("🔍 Watch: État WCSession - Activation: \(session.activationState.rawValue), Reachable: \(session.isReachable)")
        
        // Essayer d'envoyer un message si la session est reachable
        if session.isReachable {
            print("📡 Watch: Envoi d'une demande de configuration via WatchConnectivity")
            let message: [String: Any] = [
                "type": "check_configuration"
            ]
            
            session.sendMessage(message, replyHandler: { [weak self] response in
                guard let self = self else { return }
                print("✅ Watch: Réponse reçue de iOS: \(response)")
                if let isConfigured = response["isConfigured"] as? Bool {
                    DispatchQueue.main.async {
                        if isConfigured {
                            // Profil configuré - sauvegarder
                            if let firstName = response["firstName"] as? String, !firstName.isEmpty {
                                print("💾 Watch: Sauvegarde du profil reçu depuis iOS - Prénom: \(firstName)")
                                self.saveUserProfileToAppGroup(firstName: firstName, isConfigured: true)
                                // Notifier que la configuration est détectée
                                NotificationCenter.default.post(name: NSNotification.Name("ConfigurationDetected"), object: nil)
                            }
                        } else {
                            // Profil non configuré - nettoyer toutes les données (une seule fois)
                            print("🗑️ Watch: iOS confirme que le profil n'est pas configuré")
                            self.clearAllWatchData()
                            // Notifier que le profil n'est pas configuré (pour arrêter les vérifications)
                            NotificationCenter.default.post(name: NSNotification.Name("ProfileNotConfigured"), object: nil)
                        }
                    }
                } else if let profileData = response["profile"] as? Data {
                    // Si le profil est envoyé directement en JSON
                    DispatchQueue.main.async {
                        self.saveProfileDataToAppGroup(profileData)
                        NotificationCenter.default.post(name: NSNotification.Name("ConfigurationDetected"), object: nil)
                    }
                } else {
                    // Réponse invalide - considérer comme non configuré
                    DispatchQueue.main.async {
                        print("⚠️ Watch: Réponse invalide d'iOS - considéré comme non configuré")
                        NotificationCenter.default.post(name: NSNotification.Name("ProfileNotConfigured"), object: nil)
                    }
                }
            }, errorHandler: { error in
                print("❌ Watch: Erreur lors de la vérification de configuration: \(error.localizedDescription)")
                // En cas d'erreur, considérer comme non configuré
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("ProfileNotConfigured"), object: nil)
                }
            })
        } else {
            // Si la session n'est pas reachable, utiliser updateApplicationContext
            print("📡 Watch: Session non reachable, utilisation de updateApplicationContext")
            if session.activationState == .activated {
                let context: [String: Any] = [
                    "type": "request_profile"
                ]
                do {
                    try session.updateApplicationContext(context)
                    print("✅ Watch: Application context envoyé")
                } catch {
                    print("❌ Watch: Erreur lors de l'envoi du context: \(error.localizedDescription)")
                }
            }
        }
    }
    
    private func saveProfileDataToAppGroup(_ data: Data) {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return
        }
        
        sharedDefaults.set(data, forKey: "user_profile")
        sharedDefaults.synchronize()
        print("✅ Watch: Profil sauvegardé dans App Group depuis WatchConnectivity")
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
        print("📱 Watch: Message reçu de iOS: \(message)")
        if let type = message["type"] as? String {
            switch type {
            case "wardrobe_update":
                // Mettre à jour la garde-robe
                syncFromAppGroup()
            case "outfit_suggestion":
                // Recevoir une suggestion d'outfit
                break
            case "user_profile":
                // Recevoir le profil utilisateur
                if let profileBase64 = message["profile"] as? String,
                   let profileData = Data(base64Encoded: profileBase64) {
                    print("✅ Watch: Profil reçu via message (base64)")
                    saveProfileDataToAppGroup(profileData)
                    // Vérifier si le profil est configuré et notifier
                    DispatchQueue.main.async {
                        self.lastSyncDate = Date()
                        if self.isAppConfigured() {
                            print("✅ Watch: Profil configuré détecté via message - notification envoyée")
                            NotificationCenter.default.post(name: NSNotification.Name("ConfigurationDetected"), object: nil)
                        } else {
                            NotificationCenter.default.post(name: NSNotification.Name("ProfileNotConfigured"), object: nil)
                        }
                    }
                } else if let firstName = message["firstName"] as? String,
                          let isConfigured = message["isConfigured"] as? Bool {
                    print("✅ Watch: Profil reçu via message - Prénom: '\(firstName)', isConfigured: \(isConfigured)")
                    saveUserProfileToAppGroup(firstName: firstName, isConfigured: isConfigured)
                    DispatchQueue.main.async {
                        self.lastSyncDate = Date()
                        if isConfigured {
                            print("✅ Watch: Profil configuré détecté via message - notification envoyée")
                            NotificationCenter.default.post(name: NSNotification.Name("ConfigurationDetected"), object: nil)
                        } else {
                            NotificationCenter.default.post(name: NSNotification.Name("ProfileNotConfigured"), object: nil)
                        }
                    }
                }
            case "user_profile_deleted":
                // Le profil a été supprimé sur iOS
                print("🗑️ Watch: Profil supprimé sur iOS via message - nettoyage des données")
                clearAllWatchData()
            default:
                break
            }
        }
    }
    
    // Recevoir l'application context de l'iOS
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("📱 Watch: Application context reçu de iOS: \(applicationContext)")
        
        if let type = applicationContext["type"] as? String {
            switch type {
            case "user_profile":
                // Recevoir le profil utilisateur via application context
                if let profileBase64 = applicationContext["profile"] as? String,
                   let profileData = Data(base64Encoded: profileBase64) {
                    print("✅ Watch: Profil reçu via application context (base64)")
                    saveProfileDataToAppGroup(profileData)
                    // Vérifier si le profil est configuré et notifier
                    DispatchQueue.main.async {
                        self.lastSyncDate = Date()
                        if self.isAppConfigured() {
                            print("✅ Watch: Profil configuré détecté - notification envoyée")
                            NotificationCenter.default.post(name: NSNotification.Name("ConfigurationDetected"), object: nil)
                        } else {
                            NotificationCenter.default.post(name: NSNotification.Name("ProfileNotConfigured"), object: nil)
                        }
                    }
                } else if let firstName = applicationContext["firstName"] as? String,
                          let isConfigured = applicationContext["isConfigured"] as? Bool {
                    print("✅ Watch: Profil reçu via application context (champs séparés) - Prénom: '\(firstName)', isConfigured: \(isConfigured)")
                    saveUserProfileToAppGroup(firstName: firstName, isConfigured: isConfigured)
                    DispatchQueue.main.async {
                        self.lastSyncDate = Date()
                        if isConfigured {
                            print("✅ Watch: Profil configuré détecté - notification envoyée")
                            NotificationCenter.default.post(name: NSNotification.Name("ConfigurationDetected"), object: nil)
                        } else {
                            NotificationCenter.default.post(name: NSNotification.Name("ProfileNotConfigured"), object: nil)
                        }
                    }
                }
                
            case "user_profile_deleted":
                // Le profil a été supprimé sur iOS - nettoyer toutes les données
                print("🗑️ Watch: Profil supprimé sur iOS via application context - nettoyage des données")
                clearAllWatchData()
                // La notification ProfileNotConfigured est déjà envoyée dans clearAllWatchData()
                
            default:
                break
            }
        }
    }
    
    // Nettoyer toutes les données de la Watch
    func clearAllWatchData() {
        guard let sharedDefaults = UserDefaults(suiteName: appGroupIdentifier) else {
            print("⚠️ Watch: Impossible d'accéder à l'App Group pour nettoyer")
            return
        }
        
        // Supprimer toutes les données
        sharedDefaults.removeObject(forKey: "user_profile")
        sharedDefaults.removeObject(forKey: "outfit_history")
        sharedDefaults.removeObject(forKey: "wardrobe_items")
        sharedDefaults.removeObject(forKey: "wishlist_items")
        sharedDefaults.removeObject(forKey: "chat_conversations")
        
        // Forcer la synchronisation
        sharedDefaults.synchronize()
        
        print("✅ Watch: Toutes les données ont été nettoyées")
        
        // Notifier que la configuration a changé (profil supprimé)
        DispatchQueue.main.async {
            self.objectWillChange.send()
            self.lastSyncDate = Date() // Mettre à jour pour déclencher onChange
            NotificationCenter.default.post(name: NSNotification.Name("ProfileNotConfigured"), object: nil)
        }
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        // Répondre aux messages de l'app iOS
        replyHandler(["status": "received"])
    }
}

