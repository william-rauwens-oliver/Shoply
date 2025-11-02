//
//  ShoplyWatchApp.swift
//  ShoplyWatchExtension
//
//  Created by William on 01/11/2025.
//
//  Application Apple Watch pour Shoply
//  Affichage de l'historique des outfits portés et des favoris

import SwiftUI

@main
struct ShoplyWatchApp: App {
    @StateObject private var watchDataManager = WatchDataManager.shared
    
    var body: some Scene {
        WindowGroup {
            WatchMainView()
                .environmentObject(watchDataManager)
        }
    }
}

