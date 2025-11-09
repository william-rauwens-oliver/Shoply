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
import UserNotifications
#endif

@main
struct ShoplyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var appState = AppState()
    @StateObject private var rgpdManager = RGDPManager.shared
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var settingsManager = AppSettingsManager.shared
    @State private var showingTutorial = false
    
    // Apple Sign In disponible - Permet de proposer l'authentification
    // Avec un compte développeur gratuit, l'utilisateur peut choisir de passer cette étape
    // Le bouton "Continuer sans Apple Sign In" permet de contourner le problème
    private var isAppleSignInAvailable: Bool {
        // Toujours proposer l'écran, mais l'utilisateur peut choisir de passer
        // Si Apple Sign In n'est pas configuré (compte gratuit), l'utilisateur verra un bouton pour continuer
        return true
    }
    
    // Vérifier si l'utilisateur a déjà vu l'écran Apple Sign In
    private var hasSeenAppleSignIn: Bool {
        UserDefaults.standard.bool(forKey: "hasSeenAppleSignInScreen")
    }
    
    private func markAppleSignInAsSeen() {
        UserDefaults.standard.set(true, forKey: "hasSeenAppleSignInScreen")
    }
    
    private func resetAppleSignInIfNeeded() {
        // Permettre de réinitialiser si l'utilisateur n'est plus authentifié
        if !AppleSignInService.shared.isAuthenticated {
            UserDefaults.standard.set(false, forKey: "hasSeenAppleSignInScreen")
        }
    }
    
    init() {
        // Configuration initiale de l'app
        setupAppearance()
        configureOrientations()
    }
    
    private func configureOrientations() {
        #if !WIDGET_EXTENSION
        // Forcer les orientations selon le type d'appareil
        // La gestion des orientations est assurée par AppDelegate.supportedInterfaceOrientationsFor
        // Ne pas utiliser de KVC privée pour éviter les crashes au démarrage
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
                    // Afficher l'onboarding si pas encore complété
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
                            
                            // Réinitialiser le badge de notification au démarrage
                            clearApplicationBadge()
                            
                            // Initialiser les notifications motivationnelles
                            initializeMotivationNotifications()
                            
                            // Synchronisation iCloud désactivée au démarrage pour éviter les crashes
                            // La synchronisation peut être faite manuellement depuis SettingsScreen
                            // checkAndSyncWithiCloud()
                        }
                        .sheet(isPresented: $showingTutorial) {
                            TutorialScreen(isPresented: $showingTutorial)
                        }
                        .onOpenURL { url in
                            // Gérer les deep links depuis le widget
                            // Le ContentView gère déjà cela, mais on peut aussi le gérer ici
                            if url.scheme == "shoply" && url.host == "chat" {
                                // Notification pour ouvrir le chat (sera géré par ContentView)
                            }
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
    
    private func clearApplicationBadge() {
        #if !WIDGET_EXTENSION
        // Réinitialiser le badge de notification au démarrage de l'app
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if let error = error {
                    print("⚠️ Erreur lors de la réinitialisation du badge: \(error.localizedDescription)")
                }
            }
        } else {
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
        #endif
    }
    
    private func initializeMotivationNotifications() {
        let notificationService = MotivationNotificationService.shared
        
        // Vérifier l'autorisation et demander si nécessaire
        Task {
            if !notificationService.isAuthorized {
                _ = await notificationService.requestAuthorization()
            }
            
            // Enregistrer l'heure actuelle si c'est le matin (pour détecter l'heure de réveil)
            let calendar = Calendar.current
            let hour = calendar.component(.hour, from: Date())
            
            // Toujours enregistrer l'heure si c'est le matin
            if hour >= 5 && hour < 11 {
                notificationService.recordWakeUpTime()
            }
            
            // Programmer les notifications si elles sont activées
            if notificationService.isEnabled && notificationService.isAuthorized {
                await notificationService.scheduleDailyNotifications()
            }
        }
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

