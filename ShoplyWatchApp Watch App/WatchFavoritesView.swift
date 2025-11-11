//
//  WatchFavoritesView.swift
//  ShoplyWatchApp
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct WatchFavoritesView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    @State private var favoriteOutfits: [WatchOutfitHistoryItem] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Favoris")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            
            // Liste
            ScrollView {
                VStack(spacing: 8) {
                    if favoriteOutfits.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Aucun favori")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("Marquez des outfits en favori depuis l'app iPhone")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else {
                        ForEach(favoriteOutfits) { outfit in
                            FavoriteOutfitCard(outfit: outfit)
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
        }
        .onAppear {
            loadFavorites()
        }
    }
    
    private func loadFavorites() {
        favoriteOutfits = watchDataManager.getFavoriteOutfits()
    }
}

struct FavoriteOutfitCard: View {
    let outfit: WatchOutfitHistoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "heart.fill")
                    .font(.caption)
                    .foregroundColor(.red)
                if !outfit.items.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(outfit.items.prefix(3), id: \.self) { itemName in
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                Text(itemName)
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                        }
                        if outfit.items.count > 3 {
                            Text("+ \(outfit.items.count - 3) autres")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .padding(.leading, 18)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.red.opacity(0.15), Color.red.opacity(0.08)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(10)
    }
}

