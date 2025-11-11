//
//  ContentView.swift
//  ShoplyWatchApp
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    @EnvironmentObject var watchOutfitService: WatchOutfitService
    @State private var selectedTab = 0
    
    var body: some View {
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
        }
        .tabViewStyle(.verticalPage)
    }
}

#Preview {
    ContentView()
        .environmentObject(WatchDataManager.shared)
        .environmentObject(WatchOutfitService.shared)
        .environmentObject(WatchWeatherService.shared)
}

