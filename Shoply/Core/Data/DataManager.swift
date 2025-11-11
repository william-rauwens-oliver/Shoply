//
//  DataManager.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import CoreData
import SwiftUI
import Combine
#if !WIDGET_EXTENSION
import ObjectiveC
#endif

/// Gestionnaire de données - Couche d'accès aux données (DAL)
/// Implémente la persistance des données avec Core Data
class DataManager: ObservableObject {
    static let shared = DataManager()
    
    // MARK: - État de l'onboarding
    @Published var onboardingCompleted: Bool = false
    
    // MARK: - Core Data Stack
    // Core Data est optionnel - on utilise UserDefaults pour éviter les blocages
    lazy var persistentContainer: NSPersistentContainer? = {
        // Essayer de charger Core Data de manière asynchrone et non-bloquante
        // Si ça échoue, l'app continuera sans Core Data
        let container = NSPersistentContainer(name: "ShoplyDataModel")
        container.loadPersistentStores { description, error in
            if let error = error {
                
                // L'app continuera sans Core Data
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var viewContext: NSManagedObjectContext? {
        return persistentContainer?.viewContext
    }
    
            // MARK: - Initialisation
    private init() {
        // Initialisation privée pour le singleton
        // Charger l'état initial de l'onboarding
        self.onboardingCompleted = hasCompletedOnboarding()
    }
    
    // Initialisation asynchrone pour éviter les blocages au démarrage
    func initializeIfNeeded() async {
        // Précharger le contexte Core Data de manière asynchrone
        // Ne fait rien de bloquant pour éviter les timeouts
        return
    }
    
    // MARK: - Méthodes de persistance
    func saveContext() {
        guard let context = viewContext, context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            // Ne pas crasher l'app, juste logger l'erreur
            _ = error as NSError
        }
    }
    
    // MARK: - Gestion des favoris (RGPD compliant)
    // Utiliser UserDefaults comme fallback si Core Data n'est pas disponible
    private let favoritesKey = "favoriteOutfits"
    
    func addFavorite(outfitId: UUID) {
        var favorites = getFavoriteUUIDs()
        if !favorites.contains(outfitId) {
            favorites.append(outfitId)
            saveFavoriteUUIDs(favorites)
        }
    }
    
    func removeFavorite(outfitId: UUID) {
        var favorites = getFavoriteUUIDs()
        favorites.removeAll { $0 == outfitId }
        saveFavoriteUUIDs(favorites)
    }
    
    func isFavorite(outfitId: UUID) -> Bool {
        return getFavoriteUUIDs().contains(outfitId)
    }
    
    func getAllFavorites() -> [UUID] {
        return getFavoriteUUIDs()
    }
    
    private func getFavoriteUUIDs() -> [UUID] {
        guard let data = UserDefaults.standard.data(forKey: favoritesKey),
              let uuids = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return uuids.compactMap { UUID(uuidString: $0) }
    }
    
    private func saveFavoriteUUIDs(_ uuids: [UUID]) {
        let strings = uuids.map { $0.uuidString }
        if let data = try? JSONEncoder().encode(strings) {
            UserDefaults.standard.set(data, forKey: favoritesKey)
        }
    }
    
    // MARK: - Gestion des préférences utilisateur (RGPD)
    func saveUserPreferences(mood: String?, weather: String?) {
        UserDefaults.standard.set(mood, forKey: "lastSelectedMood")
        UserDefaults.standard.set(weather, forKey: "lastSelectedWeather")
    }
    
    func getUserPreferences() -> (mood: String?, weather: String?) {
        return (
            mood: UserDefaults.standard.string(forKey: "lastSelectedMood"),
            weather: UserDefaults.standard.string(forKey: "lastSelectedWeather")
        )
    }
    
    // MARK: - Gestion du profil utilisateur
    func saveUserProfile(_ profile: UserProfile) {
        if let encoded = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(encoded, forKey: "userProfile")
            // Forcer la synchronisation immédiate
            UserDefaults.standard.synchronize()
            
            // Notifier que l'onboarding est terminé
            DispatchQueue.main.async {
                self.onboardingCompleted = true
                self.objectWillChange.send()
            }
            
            // Synchroniser IMMÉDIATEMENT avec l'Apple Watch (synchrone sur le thread principal)
            // pour garantir que les données sont disponibles
            print("📱 iOS: Sauvegarde du profil - Synchronisation immédiate vers Watch")
            syncUserProfileToWatch(profile: profile)
            
            // Synchroniser à nouveau après un court délai pour être sûr
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("📱 iOS: Deuxième synchronisation du profil vers Watch")
                self.syncUserProfileToWatch(profile: profile)
            }
            
            // Synchroniser une troisième fois après 3 secondes pour garantir
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                print("📱 iOS: Troisième synchronisation du profil vers Watch")
                self.syncUserProfileToWatch(profile: profile)
            }
            
            // Synchroniser avec iCloud
            // La synchronisation est gérée manuellement depuis SettingsScreen
            // pour éviter les erreurs de compilation dans le widget extension
        }
    }
    
    // MARK: - Synchronisation avec Apple Watch
    func syncUserProfileToWatch(profile: UserProfile? = nil) {
        #if !WIDGET_EXTENSION
        // Synchroniser de manière synchrone pour garantir que les données sont écrites
        let profileToSync = profile ?? loadUserProfile()
        guard let profileToSync = profileToSync else {
            print("⚠️ iOS: Aucun profil à synchroniser - loadUserProfile() retourne nil")
            return
        }
        
        print("📱 iOS: ========== DÉBUT SYNCHRONISATION ==========")
        print("📱 iOS: Tentative de synchronisation du profil - Prénom: '\(profileToSync.firstName)', Genre: \(profileToSync.gender)")
        
        // Vérifier d'abord si l'App Group est accessible
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.william.shoply") else {
            print("❌ iOS: CRITIQUE - Impossible d'accéder à l'App Group 'group.com.william.shoply'")
            print("   → ACTION REQUISE: Vérifiez dans Xcode:")
            print("      1. Sélectionnez le target iOS (Shoply)")
            print("      2. Allez dans 'Signing & Capabilities'")
            print("      3. Ajoutez la capability 'App Groups' si elle n'existe pas")
            print("      4. Cochez 'group.com.william.shoply'")
            print("      5. Nettoyez le build (Product > Clean Build Folder)")
            print("      6. Recompilez et réinstallez l'app")
            return
        }
        
        print("✅ iOS: App Group accessible")
        
        // Vérifier que l'App Group est vraiment accessible en testant une écriture/lecture
        let testKey = "__test_app_group_access__"
        sharedDefaults.set("test", forKey: testKey)
        sharedDefaults.synchronize()
        if sharedDefaults.string(forKey: testKey) == "test" {
            print("✅ iOS: App Group fonctionne correctement (test d'écriture/lecture réussi)")
            sharedDefaults.removeObject(forKey: testKey)
        } else {
            print("❌ iOS: CRITIQUE - App Group ne fonctionne pas (test d'écriture/lecture échoué)")
            print("   → L'App Group est peut-être mal configuré dans Xcode")
            return
        }
        
        // Créer le profil Watch simplifié
        struct WatchUserProfile: Codable {
            let firstName: String
            let isConfigured: Bool
        }
        
        let isConfigured = !profileToSync.firstName.isEmpty && profileToSync.gender != .notSpecified
        let watchProfile = WatchUserProfile(
            firstName: profileToSync.firstName,
            isConfigured: isConfigured
        )
        
        guard let encoded = try? JSONEncoder().encode(watchProfile) else {
            print("❌ iOS: Impossible d'encoder le profil Watch")
            return
        }
        
        print("📦 iOS: Données encodées - Taille: \(encoded.count) bytes")
        print("📦 iOS: Contenu JSON: \(String(data: encoded, encoding: .utf8) ?? "N/A")")
        
        // Écrire dans l'App Group de manière synchrone
        sharedDefaults.set(encoded, forKey: "user_profile")
        print("💾 iOS: Données écrites dans UserDefaults avec la clé 'user_profile'")
        
        // Forcer l'écriture immédiate avec synchronize()
        let syncResult1 = sharedDefaults.synchronize()
        print("🔄 iOS: Premier synchronize() - Résultat: \(syncResult1)")
        
        // Attendre un peu pour laisser le temps à l'écriture
        Thread.sleep(forTimeInterval: 0.5)
        
        // Synchroniser à nouveau pour être sûr
        let syncResult2 = sharedDefaults.synchronize()
        print("🔄 iOS: Deuxième synchronize() - Résultat: \(syncResult2)")
        
        // Attendre encore un peu
        Thread.sleep(forTimeInterval: 0.3)
        
        // Vérifier immédiatement que les données sont bien écrites
        if let immediateCheck = sharedDefaults.data(forKey: "user_profile") {
            print("✅ iOS: Vérification immédiate - Données trouvées (Taille: \(immediateCheck.count) bytes)")
        } else {
            print("❌ iOS: CRITIQUE - Les données ne sont pas trouvées immédiatement après écriture!")
        }
        
        // Vérifier immédiatement que les données ont bien été écrites
        // Essayer plusieurs fois pour être sûr
        var verificationSuccess = false
        for attempt in 1...3 {
            if let savedData = sharedDefaults.data(forKey: "user_profile") {
                print("✅ iOS: Données retrouvées dans App Group (tentative \(attempt)) - Taille: \(savedData.count) bytes")
                if let savedProfile = try? JSONDecoder().decode(WatchUserProfile.self, from: savedData) {
                    print("✅ iOS: Profil décodé avec succès - Prénom: '\(savedProfile.firstName)', isConfigured: \(savedProfile.isConfigured)")
                    verificationSuccess = true
                    break
                } else {
                    print("❌ iOS: Impossible de décoder le profil sauvegardé (tentative \(attempt))")
                }
            } else {
                print("⚠️ iOS: Données non retrouvées (tentative \(attempt))")
            }
            
            if attempt < 3 {
                Thread.sleep(forTimeInterval: 0.2)
            }
        }
        
        if !verificationSuccess {
            print("❌ iOS: CRITIQUE - Les données ne sont pas retrouvées après écriture!")
            print("   → L'App Group ne fonctionne peut-être pas correctement")
            print("   → Vérifiez que l'App Group est bien activé dans Xcode")
        }
        
        // Lister toutes les clés dans l'App Group pour diagnostic
        let allKeys = Array(sharedDefaults.dictionaryRepresentation().keys)
        let relevantKeys = allKeys.filter { $0.contains("user") || $0.contains("profile") }
        print("🔍 iOS: Clés présentes dans App Group: \(relevantKeys)")
        
        print("📱 iOS: ========== FIN SYNCHRONISATION ==========")
        #endif
    }
    
    // MARK: - Créer des données d'exemple pour la Watch
    func createExampleOutfitHistory() {
        #if !WIDGET_EXTENSION
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.william.shoply") else {
            print("⚠️ iOS: Impossible d'accéder à l'App Group pour créer les exemples")
            return
        }
        
        // Créer des exemples d'outfits directement dans l'App Group
        // Structure identique à WatchOutfitHistoryItem pour compatibilité
        struct ExampleOutfitHistoryItem: Codable {
            let id: UUID
            let date: Date
            let items: [String]
            let isFavorite: Bool
            let style: String?
        }
        
        let calendar = Calendar.current
        let now = Date()
        
        let exampleHistory: [ExampleOutfitHistoryItem] = [
            ExampleOutfitHistoryItem(
                id: UUID(),
                date: calendar.date(byAdding: .day, value: -1, to: now) ?? now,
                items: ["T-shirt blanc", "Jeans bleu", "Baskets blanches"],
                isFavorite: true,
                style: "Décontracté"
            ),
            ExampleOutfitHistoryItem(
                id: UUID(),
                date: calendar.date(byAdding: .day, value: -2, to: now) ?? now,
                items: ["Chemise bleue", "Pantalon noir", "Chaussures de ville"],
                isFavorite: false,
                style: "Formel"
            ),
            ExampleOutfitHistoryItem(
                id: UUID(),
                date: calendar.date(byAdding: .day, value: -3, to: now) ?? now,
                items: ["Pull gris", "Jeans noir", "Baskets noires"],
                isFavorite: true,
                style: "Casual"
            ),
            ExampleOutfitHistoryItem(
                id: UUID(),
                date: calendar.date(byAdding: .day, value: -5, to: now) ?? now,
                items: ["T-shirt noir", "Short beige", "Sandales"],
                isFavorite: false,
                style: "Été"
            ),
            ExampleOutfitHistoryItem(
                id: UUID(),
                date: calendar.date(byAdding: .day, value: -7, to: now) ?? now,
                items: ["Veste en cuir", "Jeans bleu", "Bottes noires"],
                isFavorite: true,
                style: "Rock"
            )
        ]
        
        // Encoder en JSON avec JSONEncoder (gère UUID et Date correctement)
        if let encoded = try? JSONEncoder().encode(exampleHistory) {
            sharedDefaults.set(encoded, forKey: "outfit_history")
            sharedDefaults.synchronize()
            print("✅ iOS: Données d'exemple créées pour la Watch (\(exampleHistory.count) outfits)")
        } else {
            print("❌ iOS: Erreur lors de l'encodage des exemples")
        }
        #endif
    }
    
    func loadUserProfile() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: "userProfile"),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data) else {
            return nil
        }
        return profile
    }
    
    func hasCompletedOnboarding() -> Bool {
        let profile = loadUserProfile()
        let completed = profile != nil && !profile!.firstName.isEmpty
        // Synchroniser avec la propriété published
        if completed != onboardingCompleted {
            DispatchQueue.main.async {
                self.onboardingCompleted = completed
            }
        }
        // Synchroniser avec Watch si l'onboarding est complété (immédiatement et de manière synchrone)
        if completed, let profile = profile {
            // Synchroniser immédiatement pour que l'App Watch détecte la configuration
            syncUserProfileToWatch(profile: profile)
            
            // Vérifier que les données sont bien dans l'App Group après synchronisation
            #if !WIDGET_EXTENSION
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.verifyAndResyncIfNeeded()
            }
            #endif
        }
        return completed
    }
    
    // Vérifier et resynchroniser si nécessaire
    private func verifyAndResyncIfNeeded() {
        #if !WIDGET_EXTENSION
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.william.shoply") else {
            print("⚠️ iOS: Impossible de vérifier l'App Group")
            return
        }
        
        // Vérifier si les données existent
        if sharedDefaults.data(forKey: "user_profile") == nil {
            print("⚠️ iOS: Données manquantes dans l'App Group - resynchronisation...")
            if let profile = loadUserProfile() {
                syncUserProfileToWatch(profile: profile)
            }
        } else {
            print("✅ iOS: Données présentes dans l'App Group")
        }
        #endif
    }
    
    // MARK: - Gestion de la garde-robe
    func saveWardrobeItems(_ items: [WardrobeItem]) {
        if let encoded = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(encoded, forKey: "wardrobeItems")
        }
    }
    
    func loadWardrobeItems() -> [WardrobeItem] {
        guard let data = UserDefaults.standard.data(forKey: "wardrobeItems"),
              let items = try? JSONDecoder().decode([WardrobeItem].self, from: data) else {
            return []
        }
        return items
    }
    
    // MARK: - Export des données utilisateur (RGPD)
    func exportUserData() -> [String: Any] {
        var data: [String: Any] = [:]
        
        // Version du format d'export pour compatibilité future
        data["exportVersion"] = "1.0"
        data["exportDate"] = ISO8601DateFormatter().string(from: Date())
        
        // Favoris
        data["favorites"] = getAllFavorites().map { $0.uuidString }
        
        // Préférences
        let prefs = getUserPreferences()
        data["preferences"] = [
            "weather": prefs.weather ?? ""
        ]
        
        // Profil utilisateur complet
        if let profile = loadUserProfile() {
            if let profileDict = try? encodeProfileToDict(profile) {
                data["profile"] = profileDict
            }
        }
        
        // Garde-robe complète
        let wardrobe = loadWardrobeItems()
        if let wardrobeData = try? JSONEncoder().encode(wardrobe),
           let wardrobeArray = try? JSONSerialization.jsonObject(with: wardrobeData) as? [[String: Any]] {
            data["wardrobe"] = wardrobeArray
        }
        data["wardrobeCount"] = wardrobe.count
        
        #if !WIDGET_EXTENSION
        // Conversations de chat
        if let conversationsData = UserDefaults.standard.data(forKey: "chatConversations") {
            // Utiliser AnyCodable pour éviter les problèmes de type dans le widget extension
            if let conversationsArray = try? JSONSerialization.jsonObject(with: conversationsData) as? [[String: Any]] {
                data["chatConversations"] = conversationsArray
            }
        }
        
        // Historique des outfits
        if let historyData = UserDefaults.standard.data(forKey: "historicalOutfits") {
            // Utiliser AnyCodable pour éviter les problèmes de type dans le widget extension
            if let historyArray = try? JSONSerialization.jsonObject(with: historyData) as? [[String: Any]] {
                data["historicalOutfits"] = historyArray
            }
        }
        #endif
        
        return data
    }
    
    // Helper pour encoder le profil en dictionnaire
    private func encodeProfileToDict(_ profile: UserProfile) throws -> [String: Any] {
        var dict: [String: Any] = [:]
        dict["firstName"] = profile.firstName
        dict["age"] = profile.age
        dict["gender"] = profile.gender.rawValue
        if let email = profile.email {
            dict["email"] = email
        }
        dict["createdAt"] = ISO8601DateFormatter().string(from: profile.createdAt)
        if let lastWeatherUpdate = profile.lastWeatherUpdate {
            dict["lastWeatherUpdate"] = ISO8601DateFormatter().string(from: lastWeatherUpdate)
        }
        
        // Encoder les préférences
        if let prefsData = try? JSONEncoder().encode(profile.preferences),
           let prefsDict = try? JSONSerialization.jsonObject(with: prefsData) as? [String: Any] {
            dict["preferences"] = prefsDict
        }
        
        return dict
    }
    
    // MARK: - Import des données utilisateur
    func importUserData(from jsonData: Data) throws {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] else {
            throw NSError(domain: "DataManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Format JSON invalide"])
        }
        
        // Importer le profil
        if let profileDict = jsonObject["profile"] as? [String: Any] {
            if let profile = try? decodeProfileFromDict(profileDict) {
                saveUserProfile(profile)
            }
        }
        
        // Importer la garde-robe
        if let wardrobeArray = jsonObject["wardrobe"] as? [[String: Any]] {
            if let wardrobeData = try? JSONSerialization.data(withJSONObject: wardrobeArray),
               let wardrobe = try? JSONDecoder().decode([WardrobeItem].self, from: wardrobeData) {
                saveWardrobeItems(wardrobe)
            }
        }
        
        #if !WIDGET_EXTENSION
        // Importer les conversations
        if let conversationsArray = jsonObject["chatConversations"] as? [[String: Any]] {
            if let conversationsData = try? JSONSerialization.data(withJSONObject: conversationsArray) {
                UserDefaults.standard.set(conversationsData, forKey: "chatConversations")
            }
        }
        
        // Importer l'historique des outfits
        if let historyArray = jsonObject["historicalOutfits"] as? [[String: Any]] {
            if let historyData = try? JSONSerialization.data(withJSONObject: historyArray) {
                UserDefaults.standard.set(historyData, forKey: "historicalOutfits")
            }
        }
        #endif
        
        // Importer les favoris
        if let favoritesArray = jsonObject["favorites"] as? [String] {
            let favoriteUUIDs = favoritesArray.compactMap { UUID(uuidString: $0) }
            saveFavoriteUUIDs(favoriteUUIDs)
        }
        
        // Importer les préférences
        if let prefsDict = jsonObject["preferences"] as? [String: Any] {
            let mood = prefsDict["mood"] as? String
            let weather = prefsDict["weather"] as? String
            saveUserPreferences(mood: mood, weather: weather)
        }
        
        // Notifier le changement
        DispatchQueue.main.async {
            self.objectWillChange.send()
        }
    }
    
    // Helper pour décoder le profil depuis un dictionnaire
    private func decodeProfileFromDict(_ dict: [String: Any]) throws -> UserProfile {
        let firstName = dict["firstName"] as? String ?? ""
        let age = dict["age"] as? Int ?? 0
        let genderString = dict["gender"] as? String ?? "Non spécifié"
        let gender = Gender(rawValue: genderString) ?? .notSpecified
        let email = dict["email"] as? String
        
        let dateFormatter = ISO8601DateFormatter()
        let createdAt = (dict["createdAt"] as? String).flatMap { dateFormatter.date(from: $0) } ?? Date()
        _ = (dict["lastWeatherUpdate"] as? String).flatMap { dateFormatter.date(from: $0) } // Non utilisé actuellement
        
        var preferences = UserPreferences()
        if let prefsDict = dict["preferences"] as? [String: Any],
           let prefsData = try? JSONSerialization.data(withJSONObject: prefsDict),
           let decodedPrefs = try? JSONDecoder().decode(UserPreferences.self, from: prefsData) {
            preferences = decodedPrefs
        }
        
        return UserProfile(
            firstName: firstName,
            age: age,
            gender: gender,
            email: email,
            createdAt: createdAt,
            preferences: preferences
        )
    }
    
    // MARK: - Suppression des données utilisateur (RGPD)
    func deleteAllUserData() {
        // Supprimer tous les favoris
        UserDefaults.standard.removeObject(forKey: favoritesKey)
        
        // Supprimer les préférences
        UserDefaults.standard.removeObject(forKey: "lastSelectedMood")
        UserDefaults.standard.removeObject(forKey: "lastSelectedWeather")
        UserDefaults.standard.removeObject(forKey: "userProfile")
        UserDefaults.standard.removeObject(forKey: "wardrobeItems")
        
        // Supprimer les conversations de chat
        UserDefaults.standard.removeObject(forKey: "chatConversations")
        
        // Supprimer l'historique des outfits
        UserDefaults.standard.removeObject(forKey: "historicalOutfits")
        
        // Nettoyer l'App Group pour la Watch
        #if !WIDGET_EXTENSION
        clearWatchAppGroup()
        #endif
        
        // Réinitialiser l'onboarding
        DispatchQueue.main.async {
            self.onboardingCompleted = false
            self.objectWillChange.send()
        }
    }
    
    // MARK: - Nettoyer l'App Group pour la Watch
    func clearWatchAppGroup() {
        #if !WIDGET_EXTENSION
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.william.shoply") else {
            print("⚠️ iOS: Impossible d'accéder à l'App Group pour nettoyer")
            return
        }
        
        // Supprimer le profil utilisateur
        sharedDefaults.removeObject(forKey: "user_profile")
        
        // Supprimer l'historique des outfits
        sharedDefaults.removeObject(forKey: "outfit_history")
        
        // Supprimer la garde-robe
        sharedDefaults.removeObject(forKey: "wardrobe_items")
        
        // Supprimer la wishlist
        sharedDefaults.removeObject(forKey: "wishlist_items")
        
        // Forcer la synchronisation
        sharedDefaults.synchronize()
        
        print("✅ iOS: App Group nettoyé - toutes les données Watch supprimées")
        
        // Notifier via NotificationCenter pour que WatchConnectivityManager puisse réagir
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: NSNotification.Name("UserProfileDeleted"), object: nil)
        }
        #endif
    }
}

