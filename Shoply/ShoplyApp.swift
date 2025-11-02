//
//  ShoplyApp.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import Combine
#if !WIDGET_EXTENSION
import Foundation
import UIKit
#endif

@main
struct ShoplyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var rgpdManager = RGDPManager.shared
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var settingsManager = AppSettingsManager.shared
    @State private var showingTutorial = false
    
    init() {
        // Configuration initiale de l'app
        setupAppearance()
        configureOrientations()
    }
    
    private func configureOrientations() {
        #if !WIDGET_EXTENSION
        // Forcer les orientations selon le type d'appareil
        if UIDevice.current.userInterfaceIdiom == .phone {
            // iPhone : uniquement portrait
            UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                // Fond de sécurité pour éviter écran noir
                AppColors.background
                    .ignoresSafeArea()
                
                if !rgpdManager.hasConsentedToDataCollection {
                    // Afficher la vue de consentement RGPD en premier
                    PrivacyConsentView()
                        .environmentObject(rgpdManager)
                } else if !dataManager.onboardingCompleted && !dataManager.hasCompletedOnboarding() {
                    // Afficher l'onboarding si pas encore complété (sans forcer Apple Sign In)
                    OnboardingScreen()
                        .environmentObject(dataManager)
                        .onAppear {
                            // Vérifier après l'onboarding si on doit afficher le tutoriel
                            checkTutorialNeeded()
                        }
                } else {
                    // Afficher l'application principale
                    ContentView()
                        .environmentObject(appState)
                        .environmentObject(dataManager)
                        .environmentObject(settingsManager)
                        .preferredColorScheme(settingsManager.colorScheme)
                        .onAppear {
                            // S'assurer que l'app est prête dès le démarrage
                            appState.isReady = true
                            // Vérifier si on doit afficher le tutoriel au démarrage
                            checkTutorialNeeded()
                            // Synchronisation iCloud désactivée au démarrage pour éviter les crashes
                            // La synchronisation peut être faite manuellement depuis SettingsScreen
                            // checkAndSyncWithiCloud()
                        }
                        .sheet(isPresented: $showingTutorial) {
                            TutorialScreen(isPresented: $showingTutorial)
                        }
                }
            }
            // Initialisation non-bloquante
        }
    }
    
    private func checkTutorialNeeded() {
        // Vérifier si le profil a un genre défini et que le tutoriel n'a pas été complété
        if let profile = dataManager.loadUserProfile(),
           profile.gender != .notSpecified,
           !UserDefaults.hasCompletedTutorial() {
            // Attendre un court instant pour que l'UI se stabilise
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showingTutorial = true
            }
        }
    }
    
    private func setupAppearance() {
        // Configuration de l'apparence si nécessaire
    }
    
    private func checkAndSyncWithiCloud() {
        // Fonction désactivée pour éviter les crashes
        // La synchronisation iCloud peut être faite manuellement depuis SettingsScreen
        #if !WIDGET_EXTENSION
        // Synchronisation automatique désactivée
        #endif
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

