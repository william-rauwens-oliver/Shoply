//
//  FavoritesScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

/// Écran des favoris - Affiche les outfits favoris depuis l'historique
struct FavoritesScreen: View {
    @StateObject private var historyStore = OutfitHistoryStore()
    
    var favoriteOutfits: [HistoricalOutfit] {
        historyStore.outfits.filter { $0.isFavorite }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if favoriteOutfits.isEmpty {
                    EmptyFavoritesView()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(favoriteOutfits) { historicalOutfit in
                                FavoriteOutfitCard(
                                    historicalOutfit: historicalOutfit,
                                    onToggleFavorite: {
                                        historyStore.toggleFavorite(outfit: historicalOutfit)
                                    }
                                )
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Favoris".localized)
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct FavoriteOutfitCard: View {
    let historicalOutfit: HistoricalOutfit
    let onToggleFavorite: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header avec date et bouton favori
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(historicalOutfit.outfit.displayName)
                        .font(.playfairDisplayBold(size: 18))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(verbatim: "\(LocalizedString.localized("Porté le")) \(historicalOutfit.dateWorn.formatted(date: .long, time: .omitted))")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                Button(action: onToggleFavorite) {
                    Image(systemName: "heart.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                        .padding(8)
                        .background(Circle().fill(AppColors.buttonSecondary))
                }
            }
            .padding()
            
            Divider()
                .background(AppColors.separator)
            
            // Items de l'outfit
            VStack(spacing: 12) {
                ForEach(historicalOutfit.outfit.items) { item in
                    FavoriteOutfitItemRow(item: item)
                }
            }
            .padding()
        }
        .cleanCard(cornerRadius: 16)
    }
}

struct FavoriteOutfitItemRow: View {
    let item: WardrobeItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Photo
            if let photoURL = item.photoURL,
               let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.buttonSecondary)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: item.category.icon)
                            .foregroundColor(AppColors.secondaryText)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                
                Text(item.category.rawValue)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
        }
    }
}

struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(AppColors.tertiaryText)
            
            Text("Aucun favori".localized)
                .font(.playfairDisplayBold(size: 24))
                .foregroundColor(AppColors.primaryText)
            
            Text("Ajoutez des outfits de l'historique à vos favoris".localized)
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    FavoritesScreen()
}

