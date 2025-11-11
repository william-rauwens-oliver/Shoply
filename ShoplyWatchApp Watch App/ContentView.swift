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
            // Vérifier la configuration au démarrage
            await checkConfigurationAsync()
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
    
    private func checkConfigurationAsync() async {
        // Marquer qu'on vérifie
        isChecking = true
        
        // Forcer la synchronisation
        watchDataManager.startSync()
        
        // Attendre un court instant pour laisser le temps à la synchronisation
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 secondes
        
        // Vérifier la configuration
        let configured = watchDataManager.isAppConfigured()
        
        // Mettre à jour sur le thread principal
        await MainActor.run {
            isConfigured = configured
            isChecking = false
            
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
        
        // Vérifier toutes les 3 secondes si non configuré
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { timer in
            Task { @MainActor in
                let newStatus = dataManager.isAppConfigured()
                if newStatus {
                    // Arrêter le timer si configuré
                    timer.invalidate()
                    // Notifier que la configuration est détectée
                    NotificationCenter.default.post(name: NSNotification.Name("ConfigurationDetected"), object: nil)
                } else {
                    // Forcer la synchronisation
                    dataManager.startSync()
                }
            }
        }
        
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
