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
    
    var body: some View {
        ZStack {
            // Fond blanc épuré
            AppColors.background
                .ignoresSafeArea()
            
            // Contenu principal
        HomeScreen()
            .environmentObject(settingsManager)
        }
        .id(settingsManager.selectedLanguage) // Force le rafraîchissement quand la langue change
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(DataManager.shared)
}
