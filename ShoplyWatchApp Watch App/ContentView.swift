//
//  ContentView.swift
//  ShoplyWatchApp Watch App
//
//  Created by William on 11/11/2025.
//

import SwiftUI
import WatchConnectivity

struct ContentView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    @EnvironmentObject var watchOutfitService: WatchOutfitService
    @EnvironmentObject var watchWeatherService: WatchWeatherService
    @State private var selectedTab = 0
    @State private var isConfigured = false
    @State private var isChecking = true
    @State private var timer: Timer?
    @State private var hasReceivedResponse = false // Pour éviter les vérifications en boucle
    
    var body: some View {
        Group {
            if isChecking {
                // Écran de chargement initial avec timeout
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Chargement...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if isConfigured {
                // 3 écrans en swipe vertical
                TabView(selection: $selectedTab) {
                    // Écran 1: Shoply AI (Chat)
                    WatchChatView()
                        .tag(0)
                    
                    // Écran 2: Historique des outfits portés
                    WatchHistoryView()
                        .tag(1)
                    
                    // Écran 3: Favoris des outfits
                    WatchFavoritesView()
                        .tag(2)
                }
                .tabViewStyle(.verticalPage)
            } else {
                // Écran de configuration si l'app n'est pas configurée sur iPhone
                WatchConfigurationCheckView(onReceive: checkConfiguration)
            }
        }
        .task {
            // Vérifier la configuration une seule fois au démarrage
            // Timeout maximum de 5 secondes pour éviter un chargement infini
            await withTaskGroup(of: Void.self) { group in
                group.addTask {
                    await checkConfigurationWithRetries()
                    await MainActor.run {
                        hasReceivedResponse = true
                    }
                }
                
                group.addTask {
                    // Timeout de sécurité après 5 secondes
                    try? await Task.sleep(nanoseconds: 5_000_000_000)
                    await MainActor.run {
                        // Si toujours en chargement après 5 secondes, arrêter le chargement
                        if isChecking {
                            print("⏱️ Watch: Timeout de vérification - arrêt du chargement")
                            isChecking = false
                            hasReceivedResponse = true
                            // Si pas de réponse, considérer comme non configuré
                            if !isConfigured {
                                stopPeriodicCheck()
                            }
                        }
                    }
                }
                
                await group.next()
                group.cancelAll()
            }
        }
        .onAppear {
            // Démarrer la synchronisation dès l'apparition (une seule fois)
            watchDataManager.startSync()
        }
        .onDisappear {
            stopPeriodicCheck()
        }
        .onChange(of: watchDataManager.lastSyncDate) { oldValue, newValue in
            // Re-vérifier quand la synchronisation se fait pour détecter les changements
            // Vérifier immédiatement si le profil a été supprimé ou ajouté
            if !isChecking {
                Task {
                    // Vérifier rapidement l'état actuel
                    let currentlyConfigured = watchDataManager.isAppConfigured()
                    await MainActor.run {
                        // Si l'état a changé, mettre à jour immédiatement
                        if currentlyConfigured != isConfigured {
                            print("🔄 Watch: État de configuration changé - Mise à jour immédiate")
                            isConfigured = currentlyConfigured
                            isChecking = false
                            if !currentlyConfigured {
                                stopPeriodicCheck()
                            }
                        }
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ConfigurationDetected"))) { _ in
            // Mettre à jour le statut de configuration (même si on a déjà reçu une réponse pour les mises à jour en temps réel)
            print("🔄 Watch: Notification ConfigurationDetected reçue - Vérification de l'état")
            Task {
                // Vérifier rapidement l'état actuel
                let currentlyConfigured = watchDataManager.isAppConfigured()
                await MainActor.run {
                    if currentlyConfigured != isConfigured {
                        print("✅ Watch: Configuration détectée - Mise à jour immédiate (était: \(isConfigured), maintenant: \(currentlyConfigured))")
                        isConfigured = currentlyConfigured
                        isChecking = false
                        if currentlyConfigured {
                            stopPeriodicCheck()
                        }
                    } else {
                        print("ℹ️ Watch: État déjà à jour (configuré: \(currentlyConfigured))")
                    }
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ProfileNotConfigured"))) { _ in
            // Arrêter toutes les vérifications si le profil n'est pas configuré
            // IMPORTANT: Réagir même si hasReceivedResponse est true (pour les mises à jour en temps réel)
            print("🛑 Watch: Arrêt de toutes les vérifications - profil non configuré")
            stopPeriodicCheck()
            Task {
                await MainActor.run {
                    isConfigured = false
                    isChecking = false
                    // Ne pas mettre hasReceivedResponse à true ici pour permettre les mises à jour futures
                }
            }
        }
    }
    
    private func checkConfiguration() {
        Task {
            await checkConfigurationAsync()
        }
    }
    
    private func checkConfigurationWithRetries() async {
        // Marquer qu'on vérifie
        await MainActor.run {
            isChecking = true
        }
        
        // Faire une seule tentative rapide via WatchConnectivity d'abord
        var configured = false
        
        // Essayer d'abord via WatchConnectivity (plus rapide et fiable)
        if let session = watchDataManager.session, session.isReachable {
            print("🔍 Watch: Vérification via WatchConnectivity...")
            let message: [String: Any] = ["type": "check_configuration"]
            
            configured = await withCheckedContinuation { continuation in
                session.sendMessage(message, replyHandler: { response in
                    print("✅ Watch: Réponse reçue (retries): \(response)")
                    if let isConfigured = response["isConfigured"] as? Bool {
                        let result = isConfigured
                        // Si non configuré, notifier immédiatement pour arrêter les vérifications
                        if !result {
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: NSNotification.Name("ProfileNotConfigured"), object: nil)
                            }
                        }
                        continuation.resume(returning: result)
                    } else {
                        // Réponse invalide - considérer comme non configuré
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: NSNotification.Name("ProfileNotConfigured"), object: nil)
                        }
                        continuation.resume(returning: false)
                    }
                }, errorHandler: { error in
                    print("❌ Watch: Erreur (retries): \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name("ProfileNotConfigured"), object: nil)
                    }
                    continuation.resume(returning: false)
                })
            }
        } else {
            // Si pas de réponse via WatchConnectivity, vérifier l'App Group
            configured = watchDataManager.isAppConfigured()
            
            // Si non configuré, notifier
            if !configured {
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("ProfileNotConfigured"), object: nil)
                }
            }
        }
        
        // Mettre à jour sur le thread principal (TOUJOURS mettre isChecking à false)
        await MainActor.run {
            isConfigured = configured
            isChecking = false // IMPORTANT: Toujours arrêter le chargement
            hasReceivedResponse = true // Marquer qu'on a reçu une réponse
            
            // Arrêter toutes les vérifications
            stopPeriodicCheck()
        }
    }
    
    private func checkConfigurationAsync() async {
        // Ne pas vérifier si on a déjà reçu une réponse
        if hasReceivedResponse {
            return
        }
        
        // Marquer qu'on vérifie
        await MainActor.run {
            isChecking = true
        }
        
        var configured = false
        
        // Essayer d'abord via WatchConnectivity si disponible
        if let session = watchDataManager.session, session.isReachable {
            print("🔍 Watch: Vérification asynchrone via WatchConnectivity...")
            let message: [String: Any] = ["type": "check_configuration"]
            
            configured = await withCheckedContinuation { continuation in
                session.sendMessage(message, replyHandler: { response in
                    print("✅ Watch: Réponse reçue (async): \(response)")
                    if let isConfigured = response["isConfigured"] as? Bool {
                        let result = isConfigured
                        // Si non configuré, notifier immédiatement pour arrêter les vérifications
                        if !result {
                            DispatchQueue.main.async {
                                NotificationCenter.default.post(name: NSNotification.Name("ProfileNotConfigured"), object: nil)
                            }
                        }
                        continuation.resume(returning: result)
                    } else {
                        // Réponse invalide - considérer comme non configuré
                        DispatchQueue.main.async {
                            NotificationCenter.default.post(name: NSNotification.Name("ProfileNotConfigured"), object: nil)
                        }
                        continuation.resume(returning: false)
                    }
                }, errorHandler: { error in
                    print("❌ Watch: Erreur (async): \(error.localizedDescription)")
                    DispatchQueue.main.async {
                        NotificationCenter.default.post(name: NSNotification.Name("ProfileNotConfigured"), object: nil)
                    }
                    continuation.resume(returning: false)
                })
            }
        } else {
            // Si WatchConnectivity n'est pas disponible, vérifier l'App Group
            watchDataManager.startSync()
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 seconde seulement
            configured = watchDataManager.isAppConfigured()
            
            // Si non configuré, notifier
            if !configured {
                await MainActor.run {
                    NotificationCenter.default.post(name: NSNotification.Name("ProfileNotConfigured"), object: nil)
                }
            }
        }
        
        // Mettre à jour sur le thread principal (TOUJOURS mettre isChecking à false)
        await MainActor.run {
            isConfigured = configured
            isChecking = false // IMPORTANT: Toujours arrêter le chargement
            hasReceivedResponse = true // Marquer qu'on a reçu une réponse
            
            // Arrêter toutes les vérifications
            stopPeriodicCheck()
        }
    }
    
    private func startPeriodicCheck() {
        // Arrêter le timer existant s'il y en a un
        stopPeriodicCheck()
        
        // Ne pas démarrer la vérification périodique si on est déjà en train de vérifier
        guard !isChecking else {
            return
        }
        
        // Capturer les références nécessaires
        let dataManager = watchDataManager
        
        // Vérifier toutes les 10 secondes si non configuré (moins fréquent pour économiser la batterie)
        // Limiter à 6 tentatives maximum (1 minute) pour éviter les boucles infinies
        var attemptCount = 0
        let maxAttempts = 6
        
        let timerRef = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak dataManager] timer in
            guard let dataManager = dataManager else {
                timer.invalidate()
                return
            }
            
            attemptCount += 1
            
            // Arrêter après un certain nombre de tentatives
            if attemptCount > maxAttempts {
                print("⏱️ Watch: Arrêt de la vérification périodique après \(maxAttempts) tentatives")
                timer.invalidate()
                return
            }
            
            let newStatus = dataManager.isAppConfigured()
            if newStatus {
                // Arrêter le timer si configuré
                timer.invalidate()
                // Notifier que la configuration est détectée
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("ConfigurationDetected"), object: nil)
                }
            } else {
                // Forcer la synchronisation (mais seulement si on n'a pas déjà vérifié récemment)
                if attemptCount % 2 == 0 { // Toutes les 2 tentatives seulement
                    dataManager.startSync()
                }
            }
        }
        timer = timerRef
        
        // Ajouter le timer au RunLoop principal
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }
    
    private func stopPeriodicCheck() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchDataManager.shared)
        .environmentObject(WatchOutfitService.shared)
        .environmentObject(WatchWeatherService.shared)
}
