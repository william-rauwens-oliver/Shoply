//
//  ContentView.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
#if !WIDGET_EXTENSION
import UserNotifications
import UIKit
#endif

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var dataManager: DataManager
    @StateObject private var settingsManager = AppSettingsManager.shared
    @State private var shouldOpenChat = false
    
    var body: some View {
        ZStack {
            // Fond blanc épuré
            AppColors.background
                .ignoresSafeArea()
            
            // Contenu principal - afficher directement HomeScreen
            HomeScreen()
                .environmentObject(settingsManager)
                .sheet(isPresented: $shouldOpenChat) {
                    NavigationStack {
                        ChatAIScreen()
                    }
                }
        }
        .id(settingsManager.selectedLanguage) // Force le rafraîchissement quand la langue change
        .onAppear {
            // Réinitialiser le badge de notification à chaque fois qu'on arrive sur l'écran principal
            clearApplicationBadge()
        }
        .onOpenURL { url in
            // Gérer les deep links depuis le widget
            if url.scheme == "shoply" && url.host == "chat" {
                shouldOpenChat = true
            }
        }
    }
    
    #if !WIDGET_EXTENSION
    private func clearApplicationBadge() {
        // Réinitialiser le badge de notification
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if error != nil {
                    // Erreur silencieuse
                }
            }
        } else {
            // Fallback pour iOS < 16 uniquement
            DispatchQueue.main.async {
                // Pour iOS < 16, utiliser l'ancienne méthode
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
    #endif
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(DataManager.shared)
}
