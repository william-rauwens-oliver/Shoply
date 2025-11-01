//
//  ShoplyApp.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import Combine

@main
struct ShoplyApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var rgpdManager = RGDPManager.shared
    
    init() {
        // Configuration initiale de l'app
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Fond de sécurité pour éviter écran noir
                Color.white
                
                if !rgpdManager.hasConsentedToDataCollection {
                    // Afficher la vue de consentement RGPD en premier
                    PrivacyConsentView()
                        .environmentObject(rgpdManager)
                } else if !DataManager.shared.hasCompletedOnboarding() {
                    // Afficher l'onboarding si pas encore complété
                    OnboardingScreen()
                } else {
                    ContentView()
                        .environmentObject(appState)
                        .environmentObject(DataManager.shared)
                        .preferredColorScheme(.light)
                        .onAppear {
                            // S'assurer que l'app est prête dès le démarrage
                            appState.isReady = true
                        }
                }
            }
            // Initialisation non-bloquante
        }
    }
    
    private func setupAppearance() {
        // Configuration de l'apparence si nécessaire
    }
}

class AppState: ObservableObject {
    @Published var isReady = false
    
    init() {
        // Initialisation de l'état de l'app
        DispatchQueue.main.async {
            self.isReady = true
        }
    }
}

