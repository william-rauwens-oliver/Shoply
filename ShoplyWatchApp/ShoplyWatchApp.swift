//
//  ShoplyWatchApp.swift
//  ShoplyWatchApp
//
//  Created by William on 01/11/2025.
//

import SwiftUI

// Ancien point d'entrée - maintenant dans ShoplyWatchApp Watch App/ShoplyWatchAppApp.swift
// @main
struct ShoplyWatchApp: App {
    @StateObject private var watchDataManager = WatchDataManager.shared
    @StateObject private var watchOutfitService = WatchOutfitService.shared
    @StateObject private var watchWeatherService = WatchWeatherService.shared
    
    init() {
        // Configuration initiale de l'app Watch
        setupWatchApp()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(watchDataManager)
                .environmentObject(watchOutfitService)
                .environmentObject(watchWeatherService)
        }
    }
    
    private func setupWatchApp() {
        // Initialiser la synchronisation avec l'app iOS
        watchDataManager.startSync()
    }
}

