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
        .navigationTitle("Favoris")
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
            HStack {
                Text(outfit.date, style: .date)
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                Image(systemName: "heart.fill")
                    .font(.caption2)
                    .foregroundColor(.red)
            }
            
            if !outfit.items.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(outfit.items, id: \.self) { itemName in
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            Text(itemName)
                                .font(.caption2)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.red.opacity(0.1))
        .cornerRadius(8)
    }
}

