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
    @State private var showingDeleteAllAlert = false
    
    var favoriteOutfits: [HistoricalOutfit] {
        historyStore.outfits.filter { $0.isFavorite }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond opaque simple
                AppColors.background
                    .ignoresSafeArea()
                
                if favoriteOutfits.isEmpty {
                    EmptyFavoritesView()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 20) {
                            ForEach(favoriteOutfits) { historicalOutfit in
                                FavoriteOutfitCard(
                                    historicalOutfit: historicalOutfit,
                                    onToggleFavorite: {
                                        historyStore.toggleFavorite(outfit: historicalOutfit)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                    }
                }
            }
            .navigationTitle("Favoris")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !favoriteOutfits.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingDeleteAllAlert = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .alert("Supprimer tous les favoris ?", isPresented: $showingDeleteAllAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Supprimer tout", role: .destructive) {
                    historyStore.removeAllFavorites()
                }
            } message: {
                Text("Cette action est irréversible")
            }
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
                        .font(.playfairDisplayBold(size: 20))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(verbatim: "\(LocalizedString.localized("Porté le")) \(historicalOutfit.dateWorn.formatted(date: .long, time: .omitted))")
                        .font(.system(size: 14, weight: .regular))
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
            .padding(24)
            
            Rectangle()
                .fill(AppColors.separator.opacity(0.6))
                .frame(height: 0.5)
                .padding(.horizontal, 24)
            
            // Items de l'outfit
            VStack(spacing: 16) {
                ForEach(historicalOutfit.outfit.items) { item in
                    FavoriteOutfitItemRow(item: item)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Material.regularMaterial)
        .overlay {
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppColors.cardBorder.opacity(0.4),
                                    AppColors.cardBorder.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
        }
        )
        .roundedCorner(22)
        .shadow(color: AppColors.shadow.opacity(0.2), radius: 14, x: 0, y: 6)
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
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.buttonSecondary,
                                AppColors.buttonSecondary.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppColors.cardBorder.opacity(0.3),
                                        AppColors.cardBorder.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                
                Image(systemName: "heart.slash")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(AppColors.secondaryText)
            }
            .shadow(color: AppColors.shadow.opacity(0.15), radius: 12, x: 0, y: 4)
            
            VStack(spacing: 16) {
                Text("Aucun favori".localized)
                    .font(.playfairDisplayBold(size: 30))
                    .foregroundColor(AppColors.primaryText)
                
                Text("Ajoutez vos tenues préférées depuis l'historique en appuyant sur le cœur".localized)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineLimit(3)
            }
        }
    }
}

#Preview {
    FavoritesScreen()
}

