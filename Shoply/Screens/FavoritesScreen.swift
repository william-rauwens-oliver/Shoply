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
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            ForEach(favoriteOutfits) { historicalOutfit in
                                FavoriteOutfitCard(
                                    historicalOutfit: historicalOutfit,
                                    onToggleFavorite: {
                                        historyStore.toggleFavorite(outfit: historicalOutfit)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
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
            // Header épuré
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(historicalOutfit.outfit.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(verbatim: "\(LocalizedString.localized("Porté le")) \(historicalOutfit.dateWorn.formatted(date: .long, time: .omitted))")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                Button(action: onToggleFavorite) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.red)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(AppColors.buttonSecondary))
                }
            }
            .padding(20)
            
            Divider()
                .background(AppColors.separator.opacity(0.5))
            
            // Items de l'outfit
            VStack(spacing: 14) {
                ForEach(historicalOutfit.outfit.items) { item in
                    FavoriteOutfitItemRow(item: item)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 0.5)
        }
        .roundedCorner(18)
        .shadow(color: AppColors.shadow.opacity(0.08), radius: 12, x: 0, y: 4)
    }
}

struct FavoriteOutfitItemRow: View {
    let item: WardrobeItem
    
    var body: some View {
        HStack(spacing: 14) {
            // Photo
            if let photoURL = item.photoURL,
               let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.buttonSecondary)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: item.category.icon)
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.secondaryText)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                
                Text(item.category.rawValue)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
        }
    }
}

struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppColors.buttonSecondary)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "heart.slash")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            VStack(spacing: 8) {
                Text("Aucun favori".localized)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.primaryText)
                
                Text("Ajoutez des outfits de l'historique à vos favoris".localized)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
            }
        }
    }
}

#Preview {
    FavoritesScreen()
}

