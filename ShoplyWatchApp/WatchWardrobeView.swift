//
//  WatchWardrobeView.swift
//  ShoplyWatchApp
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct WatchWardrobeView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    @State private var items: [WatchWardrobeItem] = []
    @State private var selectedCategory: WardrobeCategory = .all
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Filtre par catégorie
                CategoryFilter(selectedCategory: $selectedCategory)
                
                // Liste des vêtements
                if items.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tshirt")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Aucun vêtement")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Ajoutez des vêtements depuis l'app iPhone")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ForEach(filteredItems) { item in
                        WardrobeItemCard(item: item)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .navigationTitle("Garde-robe")
        .onAppear {
            loadWardrobe()
        }
    }
    
    private var filteredItems: [WatchWardrobeItem] {
        if selectedCategory == .all {
            return items
        }
        return items.filter { $0.category == selectedCategory }
    }
    
    private func loadWardrobe() {
        items = watchDataManager.getWardrobeItems()
    }
}

struct CategoryFilter: View {
    @Binding var selectedCategory: WardrobeCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(WardrobeCategory.allCases, id: \.self) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        Text(category.displayName)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 4)
                    }
                    .buttonStyle(selectedCategory == category ? .borderedProminent : .bordered)
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct WardrobeItemCard: View {
    let item: WatchWardrobeItem
    
    var body: some View {
        HStack(spacing: 8) {
            // Icône de catégorie
            Image(systemName: categoryIcon)
                .font(.title3)
                .foregroundColor(.blue)
                .frame(width: 30)
            
            // Informations
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let color = item.color {
                    Text(color)
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
    
    private var categoryIcon: String {
        switch item.category {
        case .top:
            return "tshirt.fill"
        case .bottom:
            return "figure.walk"
        case .shoes:
            return "shoe.fill"
        case .accessories:
            return "bag.fill"
        case .all:
            return "tshirt"
        }
    }
}

enum WardrobeCategory: String, CaseIterable {
    case all = "Tous"
    case top = "Hauts"
    case bottom = "Bas"
    case shoes = "Chaussures"
    case accessories = "Accessoires"
    
    var displayName: String {
        return self.rawValue
    }
}

