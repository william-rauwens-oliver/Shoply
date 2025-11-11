//
//  ShoplyWatchAppApp.swift
//  ShoplyWatchApp Watch App
//
//  Created by William on 11/11/2025.
//

import SwiftUI

@main
struct ShoplyWatchApp_Watch_AppApp: App {
    // Utiliser directement les singletons sans @StateObject
    private let watchDataManager = WatchDataManager.shared
    private let watchOutfitService = WatchOutfitService.shared
    private let watchWeatherService = WatchWeatherService.shared
    
    init() {
        // Configuration initiale de l'app Watch
        // Ne pas appeler startSync ici car WCSession n'est pas encore activé
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(watchDataManager)
                .environmentObject(watchOutfitService)
                .environmentObject(watchWeatherService)
        }
    }
}
