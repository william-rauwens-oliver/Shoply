//
//  ShoplyWatchAppApp.swift
//  ShoplyWatchApp Watch App
//
//  Created by William on 11/11/2025.
//

import SwiftUI

@main
struct ShoplyWatchApp_Watch_AppApp: App {
    @StateObject private var watchDataManager = WatchDataManager.shared
    @StateObject private var watchOutfitService = WatchOutfitService.shared
    @StateObject private var watchWeatherService = WatchWeatherService.shared
    
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
