//
//  FavoritesView.swift
//  ShoplyCore - Android Compatible
//
//  Écran des favoris SwiftUI pour Android (identique iOS)

import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

/// Vue des favoris (identique iOS FavoritesScreen)
public struct FavoritesView: View {
    @StateObject private var outfitService = OutfitService.shared
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if outfitService.getFavorites().isEmpty {
                    EmptyFavoritesContent()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(outfitService.getFavorites()) { outfit in
                                NavigationLink(destination: OutfitDetailView(outfit: outfit)) {
                                    OutfitCardView(outfit: outfit)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Favoris")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    // Back button handled by NavigationStack
                }
            }
        }
    }
}

struct EmptyFavoritesContent: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart")
                .font(.system(size: 64))
                .foregroundColor(AppColors.secondaryText)
            
            Text("Aucun favori")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(AppColors.primaryText)
            
            Text("Ajoutez des outfits à vos favoris pour les retrouver facilement")
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct OutfitCardView: View {
    let outfit: Outfit
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(outfit.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(outfit.type.rawValue)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
            }
            
            Text(outfit.description)
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)
                .lineLimit(2)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 0.5)
        }
        .roundedCorner(16)
        .shadow(color: AppColors.shadow.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

struct OutfitDetailView: View {
    let outfit: Outfit
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(outfit.name)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(AppColors.primaryText)
                
                Text(outfit.description)
                    .font(.system(size: 16))
                    .foregroundColor(AppColors.secondaryText)
                
                // Composition
                VStack(alignment: .leading, spacing: 12) {
                    Text("Composition")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Haut: \(outfit.top)")
                    Text("Bas: \(outfit.bottom)")
                    Text("Chaussures: \(outfit.shoes)")
                }
                .font(.system(size: 16))
                .foregroundColor(AppColors.secondaryText)
            }
            .padding()
        }
        .background(AppColors.background)
        .navigationTitle(outfit.name)
    }
}

