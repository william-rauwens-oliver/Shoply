//
//  ContentView.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

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
        .onOpenURL { url in
            // Gérer les deep links depuis le widget
            if url.scheme == "shoply" && url.host == "chat" {
                shouldOpenChat = true
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(DataManager.shared)
}
