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
    
    var body: some View {
        ZStack {
            // Fond par défaut visible dès le démarrage pour éviter écrans blancs/noirs
            if #available(iOS 26.0, *) {
                LinearGradient(
                    colors: [
                        Color(red: 0.99, green: 0.98, blue: 1.0),
                        Color(red: 0.97, green: 0.98, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            } else {
                LinearGradient(
                    colors: [
                        Color(red: 0.98, green: 0.97, blue: 0.99),
                        Color(red: 0.95, green: 0.97, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            
            // Contenu principal
            HomeScreen()
        }
        .ignoresSafeArea()
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
        .environmentObject(DataManager.shared)
}
