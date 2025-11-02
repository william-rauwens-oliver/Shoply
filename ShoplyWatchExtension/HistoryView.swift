//
//  HistoryView.swift
//  ShoplyWatchExtension
//
//  Created by William on 01/11/2025.
//
//  Vue affichant l'historique des outfits portés sur Apple Watch

import SwiftUI

struct HistoryView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    @State private var historicalOutfits: [WatchHistoricalOutfit] = []
    
    var body: some View {
        NavigationStack {
            if historicalOutfits.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "clock")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("Aucun historique".localized)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(historicalOutfits) { outfit in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(outfit.outfitName)
                                .font(.headline)
                                .lineLimit(1)
                            
                            if let weather = outfit.weather {
                                Label(weather, systemImage: "cloud.sun")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Text(outfit.dateWorn, style: .date)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Historique".localized)
        .onAppear {
            loadHistory()
        }
    }
    
    private func loadHistory() {
        historicalOutfits = watchDataManager.historicalOutfits
    }
}

