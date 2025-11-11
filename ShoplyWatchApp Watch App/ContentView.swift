//
//  ContentView.swift
//  ShoplyWatchApp Watch App
//
//  Created by William on 11/11/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    @EnvironmentObject var watchOutfitService: WatchOutfitService
    @EnvironmentObject var watchWeatherService: WatchWeatherService
    @State private var selectedTab = 0
    @State private var isConfigured = false
    @State private var isChecking = true
    @State private var timer: Timer?
    
    var body: some View {
        Group {
            if isChecking {
                // Écran de chargement initial
                VStack(spacing: 16) {
                    ProgressView()
                    Text("Chargement...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if isConfigured {
                TabView(selection: $selectedTab) {
                    // Onglet 1: Accueil avec suggestions
                    WatchHomeView()
                        .tag(0)
                    
                    // Onglet 2: Suggestions d'outfits
                    WatchOutfitSuggestionsView()
                        .tag(1)
                    
                    // Onglet 3: Chat IA
                    WatchChatView()
                        .tag(2)
                    
                    // Onglet 4: Garde-robe
                    WatchWardrobeView()
                        .tag(3)
                    
                    // Onglet 5: Historique
                    WatchHistoryView()
                        .tag(4)
                    
                    // Onglet 6: Wishlist
                    WatchWishlistView()
                        .tag(5)
                    
                    // Onglet 7: Favoris
                    WatchFavoritesView()
                        .tag(6)
                }
                .tabViewStyle(.verticalPage)
            } else {
                WatchConfigurationCheckView(onReceive: checkConfiguration)
            }
        }
        .task {
            // Démarrer la synchronisation plusieurs fois pour s'assurer que ça fonctionne
            watchDataManager.startSync()
            
            // Vérifier la configuration avec plusieurs tentatives
            await checkConfigurationWithRetries()
        }
        .onAppear {
            // Démarrer la synchronisation dès l'apparition
            watchDataManager.startSync()
        }
        .onDisappear {
            stopPeriodicCheck()
        }
        .onChange(of: watchDataManager.lastSyncDate) { _, _ in
            // Re-vérifier quand la synchronisation se fait
            if !isConfigured && !isChecking {
                Task {
                    await checkConfigurationAsync()
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("ConfigurationDetected"))) { _ in
            // Mettre à jour le statut de configuration
            Task {
                await checkConfigurationAsync()
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
        
        // Faire plusieurs tentatives avec des délais croissants
        var configured = false
        let maxRetries = 3
        
        for attempt in 1...maxRetries {
            // Forcer la synchronisation à chaque tentative
            watchDataManager.startSync()
            
            // Attendre avec un délai croissant (1s, 2s, 3s)
            try? await Task.sleep(nanoseconds: UInt64(attempt) * 1_000_000_000)
            
            // Vérifier la configuration
            configured = watchDataManager.isAppConfigured()
            
            if configured {
                break
            }
        }
        
        // Mettre à jour sur le thread principal (TOUJOURS mettre isChecking à false)
        await MainActor.run {
            isConfigured = configured
            isChecking = false // IMPORTANT: Toujours arrêter le chargement
            
            // Si non configuré, démarrer la vérification périodique
            if !configured {
                startPeriodicCheck()
            } else {
                stopPeriodicCheck()
            }
        }
    }
    
    private func checkConfigurationAsync() async {
        // Marquer qu'on vérifie
        await MainActor.run {
            isChecking = true
        }
        
        // Forcer la synchronisation
        watchDataManager.startSync()
        
        // Attendre un court instant pour laisser le temps à la synchronisation
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes
        
        // Vérifier la configuration (avec protection contre les blocages)
        let configured = watchDataManager.isAppConfigured()
        
        // Mettre à jour sur le thread principal (TOUJOURS mettre isChecking à false)
        await MainActor.run {
            isConfigured = configured
            isChecking = false // IMPORTANT: Toujours arrêter le chargement
            
            // Si non configuré, démarrer la vérification périodique
            if !configured {
                startPeriodicCheck()
            } else {
                stopPeriodicCheck()
            }
        }
    }
    
    private func startPeriodicCheck() {
        // Arrêter le timer existant s'il y en a un
        stopPeriodicCheck()
        
        // Capturer les références nécessaires
        let dataManager = watchDataManager
        
        // Vérifier toutes les 5 secondes si non configuré (moins fréquent pour économiser la batterie)
        let timerRef = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak dataManager] timer in
            guard let dataManager = dataManager else {
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
                // Forcer la synchronisation
                dataManager.startSync()
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
