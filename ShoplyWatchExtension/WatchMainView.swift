//
//  WatchMainView.swift
//  ShoplyWatchExtension
//
//  Created by William on 01/11/2025.
//
//  Vue principale de l'application Apple Watch avec onglets

import SwiftUI

struct WatchMainView: View {
    @StateObject private var watchDataManager = WatchDataManager.shared
    
    var body: some View {
        TabView {
            HistoryView()
                .tabItem {
                    Label("Historique".localized, systemImage: "clock")
                }
            
            FavoritesView()
                .tabItem {
                    Label("Favoris".localized, systemImage: "star.fill")
                }
        }
        .onAppear {
            watchDataManager.loadData()
        }
    }
}

