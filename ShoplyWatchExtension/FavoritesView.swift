//
//  FavoritesView.swift
//  ShoplyWatchExtension
//
//  Created by William on 01/11/2025.
//
//  Vue affichant les outfits favoris sur Apple Watch

import SwiftUI

struct FavoritesView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    @State private var favoriteOutfits: [WatchFavoriteOutfit] = []
    
    var body: some View {
        NavigationStack {
            if favoriteOutfits.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "star")
                        .font(.system(size: 40))
                        .foregroundColor(.gray)
                    Text("Aucun favori".localized)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(favoriteOutfits) { outfit in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(outfit.name)
                                .font(.headline)
                                .lineLimit(1)
                            
                            if let description = outfit.description {
                                Text(description)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                            
                            Text("Ajouté le".localized + " \(outfit.createdAt, style: .date)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Favoris".localized)
        .onAppear {
            loadFavorites()
        }
    }
    
    private func loadFavorites() {
        favoriteOutfits = watchDataManager.favoriteOutfits
    }
}

