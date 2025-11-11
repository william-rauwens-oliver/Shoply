//
//  WatchConnectivityManager.swift
//  Shoply
//
//  Created by William on 11/11/2025.
//

import Foundation
import Combine
import WatchConnectivity

#if !WIDGET_EXTENSION
class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()
    
    @Published var isConnected = false
    
    private var session: WCSession?
    private let dataManager = DataManager.shared
    
    override init() {
        super.init()
        setupWatchConnectivity()
        
        // Écouter les notifications de suppression de profil
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProfileDeleted),
            name: NSNotification.Name("UserProfileDeleted"),
            object: nil
        )
    }
    
    @objc private func handleProfileDeleted() {
        sendProfileDeletedToWatch()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func setupWatchConnectivity() {
        guard WCSession.isSupported() else {
            print("⚠️ iOS: WatchConnectivity n'est pas supporté")
            return
        }
        
        session = WCSession.default
        session?.delegate = self
        session?.activate()
        
        print("✅ iOS: WatchConnectivity initialisé")
    }
    
    // Envoyer le profil à la Watch
    func sendProfileToWatch() {
        guard let session = session, session.activationState == .activated else {
            print("⚠️ iOS: WCSession non activé, impossible d'envoyer le profil")
            return
        }
        
        guard let profile = dataManager.loadUserProfile() else {
            print("⚠️ iOS: Aucun profil à envoyer à la Watch")
            return
        }
        
        // Créer le profil Watch simplifié
        struct WatchUserProfile: Codable {
            let firstName: String
            let isConfigured: Bool
        }
        
        let isConfigured = !profile.firstName.isEmpty && profile.gender != .notSpecified
        let watchProfile = WatchUserProfile(
            firstName: profile.firstName,
            isConfigured: isConfigured
        )
        
        guard let encoded = try? JSONEncoder().encode(watchProfile) else {
            print("❌ iOS: Impossible d'encoder le profil pour Watch")
            return
        }
        
        // Convertir Data en base64 pour l'envoi via application context
        let base64String = encoded.base64EncodedString()
        
        // Envoyer via application context (fonctionne même si la Watch n'est pas reachable)
        let context: [String: Any] = [
            "type": "user_profile",
            "profile": base64String, // Envoyer en base64
            "firstName": profile.firstName,
            "isConfigured": isConfigured
        ]
        
        do {
            try session.updateApplicationContext(context)
            print("✅ iOS: Profil envoyé à la Watch via application context")
        } catch {
            print("❌ iOS: Erreur lors de l'envoi du profil: \(error.localizedDescription)")
        }
        
        // Aussi synchroniser via App Group
        dataManager.syncUserProfileToWatch(profile: profile)
    }
    
    // Notifier la Watch que le profil a été supprimé
    func sendProfileDeletedToWatch() {
        guard let session = session, session.activationState == .activated else {
            print("⚠️ iOS: WCSession non activé, impossible d'envoyer la notification de suppression")
            return
        }
        
        // Envoyer un profil vide pour indiquer la suppression
        let context: [String: Any] = [
            "type": "user_profile_deleted",
            "firstName": "",
            "isConfigured": false
        ]
        
        do {
            try session.updateApplicationContext(context)
            print("✅ iOS: Notification de suppression du profil envoyée à la Watch")
        } catch {
            print("❌ iOS: Erreur lors de l'envoi de la notification: \(error.localizedDescription)")
        }
    }
}

// MARK: - WCSessionDelegate
extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = (activationState == .activated)
            
            if activationState == .activated {
                print("✅ iOS: WCSession activé")
                // Envoyer le profil dès que la session est activée
                self.sendProfileToWatch()
            } else {
                print("⚠️ iOS: WCSession non activé (état: \(activationState.rawValue))")
            }
            
            if let error = error {
                print("❌ iOS: Erreur d'activation WCSession: \(error.localizedDescription)")
            }
        }
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("⚠️ iOS: WCSession est devenu inactif")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("⚠️ iOS: WCSession est désactivé, réactivation...")
        session.activate()
    }
    
    // Répondre aux messages de la Watch
    func session(_ session: WCSession, didReceiveMessage message: [String : Any], replyHandler: @escaping ([String : Any]) -> Void) {
        print("📱 iOS: Message reçu de la Watch: \(message)")
        
        if let type = message["type"] as? String {
            switch type {
                   case "check_configuration":
                       // La Watch demande la configuration
                       print("📱 iOS: Demande de vérification de configuration depuis Watch")
                       
                       guard let profile = dataManager.loadUserProfile() else {
                           // Pas de profil - nettoyer l'App Group et répondre false
                           print("⚠️ iOS: Aucun profil trouvé - réponse: non configuré")
                           dataManager.clearWatchAppGroup()
                           replyHandler(["isConfigured": false, "firstName": ""])
                           return
                       }
                       
                       let isConfigured = !profile.firstName.isEmpty && profile.gender != .notSpecified
                       
                       print("📱 iOS: Profil trouvé - Prénom: '\(profile.firstName)', Genre: \(profile.gender), isConfigured: \(isConfigured)")
                       
                       if isConfigured {
                           print("✅ iOS: Profil configuré - envoi de la réponse positive à la Watch")
                           replyHandler([
                               "isConfigured": true,
                               "firstName": profile.firstName
                           ])
                           // Aussi envoyer le profil complet via App Group et application context
                           DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                               self.sendProfileToWatch()
                           }
                       } else {
                           // Profil vide ou incomplet - nettoyer l'App Group
                           print("⚠️ iOS: Profil incomplet - réponse: non configuré")
                           dataManager.clearWatchAppGroup()
                           replyHandler([
                               "isConfigured": false,
                               "firstName": ""
                           ])
                       }
                
            case "request_profile":
                // La Watch demande le profil
                sendProfileToWatch()
                replyHandler(["status": "sent"])
                
            case "chat_message":
                // La Watch envoie un message de chat - générer une réponse IA
                if let question = message["text"] as? String {
                    print("📱 iOS: Question reçue de la Watch: \(question)")
                    
                    // Générer la réponse de l'IA de manière asynchrone
                    // replyHandler peut être appelé de manière asynchrone (jusqu'à 30 secondes)
                    Task { [weak self] in
                        guard let self = self else {
                            replyHandler(["response": "Erreur de connexion."])
                            return
                        }
                        
                        let aiResponse = await self.generateAIResponse(for: question)
                        
                        // Appeler replyHandler avec la vraie réponse
                        replyHandler(["response": aiResponse])
                    }
                    // Ne pas appeler replyHandler ici - laisser le Task le faire
                    return
                } else {
                    replyHandler(["response": "Je n'ai pas compris votre question."])
                }
                
            default:
                replyHandler(["status": "unknown"])
            }
        } else {
            replyHandler(["status": "error"])
        }
    }
    
    // Générer une réponse de l'IA pour la Watch avec Google Gemini
    private func generateAIResponse(for question: String) async -> String {
        // Utiliser Google Gemini pour répondre sur la Watch
        let geminiService = GeminiService.shared
        let userProfile = dataManager.loadUserProfile()
        let weatherService = WeatherService.shared
        let wardrobeService = WardrobeService()
        let currentWeather = weatherService.currentWeather
        let wardrobeItems = wardrobeService.items
        
        // Vérifier si Gemini est disponible
        guard geminiService.isEnabled else {
            print("⚠️ iOS: Gemini non disponible, utilisation d'un fallback")
            // Fallback vers IntelligentLocalAI si Gemini n'est pas disponible
            let intelligentAI = IntelligentLocalAI.shared
            return intelligentAI.generateIntelligentResponse(
                question: question,
                userProfile: userProfile ?? UserProfile(),
                currentWeather: currentWeather,
                wardrobeItems: wardrobeItems,
                conversationHistory: [],
                image: nil
            )
        }
        
        do {
            // Utiliser Gemini pour générer la réponse
            print("📱 iOS: Génération de la réponse Gemini pour Watch...")
            let response = try await geminiService.askAboutClothing(
                question: question,
                userProfile: userProfile ?? UserProfile(),
                currentWeather: currentWeather,
                wardrobeItems: wardrobeItems,
                image: nil,
                conversationHistory: [] // Pas d'historique pour la Watch
            )
            
            print("✅ iOS: Réponse Gemini générée pour Watch: \(response.prefix(50))...")
            return response
        } catch {
            print("❌ iOS: Erreur lors de la génération Gemini: \(error.localizedDescription)")
            // Fallback vers IntelligentLocalAI en cas d'erreur
            let intelligentAI = IntelligentLocalAI.shared
            return intelligentAI.generateIntelligentResponse(
                question: question,
                userProfile: userProfile ?? UserProfile(),
                currentWeather: currentWeather,
                wardrobeItems: wardrobeItems,
                conversationHistory: [],
                image: nil
            )
        }
    }
    
    // Recevoir l'application context de la Watch
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("📱 iOS: Application context reçu de la Watch: \(applicationContext)")
        
        if let type = applicationContext["type"] as? String, type == "request_profile" {
            // La Watch demande le profil via application context
            sendProfileToWatch()
        }
    }
}
#endif

