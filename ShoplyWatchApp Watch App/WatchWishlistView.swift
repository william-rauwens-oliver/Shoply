//
//  WatchWishlistView.swift
//  ShoplyWatchApp
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct WatchWishlistView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    @State private var wishlistItems: [WatchWishlistItem] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if wishlistItems.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "heart")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Wishlist vide")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Ajoutez des articles depuis l'app iPhone")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ForEach(wishlistItems) { item in
                        WishlistItemCard(item: item)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .navigationTitle("Wishlist")
        .onAppear {
            loadWishlist()
        }
    }
    
    private func loadWishlist() {
        wishlistItems = watchDataManager.getWishlistItems()
    }
}

struct WishlistItemCard: View {
    let item: WatchWishlistItem
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "heart.fill")
                .font(.title3)
                .foregroundColor(.red)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let price = item.price {
                    Text("\(price, specifier: "%.2f") €")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if let priority = item.priority {
                    Text("Priorité: \(priority)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

