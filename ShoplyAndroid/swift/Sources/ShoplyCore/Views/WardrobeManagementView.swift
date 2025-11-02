//
//  WardrobeManagementView.swift
//  ShoplyCore - Android Compatible
//
//  Écran de gestion de garde-robe SwiftUI pour Android (identique iOS)

import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

/// Vue de gestion de la garde-robe (identique iOS)
public struct WardrobeManagementView: View {
    @StateObject private var wardrobeService = WardrobeService.shared
    @State private var selectedCategory: ClothingCategory = .top
    @State private var showingAddItem = false
    @State private var searchText = ""
    
    public init() {}
    
    var filteredItems: [WardrobeItem] {
        if searchText.isEmpty {
            return wardrobeService.getItemsByCategory(selectedCategory)
        } else {
            return wardrobeService.searchItems(query: searchText)
        }
    }
    
    public var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Barre de recherche
                    SearchBarView(text: $searchText)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Sélecteur de catégorie
                    CategoryPickerView(selectedCategory: $selectedCategory)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Liste des vêtements
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 15),
                            GridItem(.flexible(), spacing: 15)
                        ], spacing: 15) {
                            ForEach(filteredItems) { item in
                                WardrobeItemCardView(item: item)
                            }
                        }
                        .padding()
                        
                        if filteredItems.isEmpty {
                            EmptyWardrobeView(category: selectedCategory)
                                .padding(.top, 50)
                        }
                    }
                }
            }
            .navigationTitle("Ma Garde-robe")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddItem = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.primaryText)
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddWardrobeItemView()
            }
        }
    }
}

// MARK: - Sous-composants

struct SearchBarView: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.secondaryText)
            
            TextField("Rechercher...", text: $text)
                .font(.system(size: 16))
                .foregroundColor(AppColors.primaryText)
        }
        .padding()
        .background(AppColors.buttonSecondary)
        .roundedCorner(20)
    }
}

struct CategoryPickerView: View {
    @Binding var selectedCategory: ClothingCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ClothingCategory.allCases) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.system(size: 24))
                                .foregroundColor(selectedCategory == category ? AppColors.buttonPrimaryText : AppColors.primaryText)
                            
                            Text(category.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(selectedCategory == category ? AppColors.buttonPrimaryText : AppColors.primaryText)
                        }
                        .frame(width: 80, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedCategory == category ? AppColors.buttonPrimary : AppColors.buttonSecondary)
                        )
                    }
                }
            }
        }
    }
}

struct WardrobeItemCardView: View {
    let item: WardrobeItem
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Placeholder pour photo (à adapter pour Android)
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.buttonSecondary)
                    .frame(height: 120)
                    .overlay {
                        Image(systemName: item.category.icon)
                            .font(.system(size: 40))
                            .foregroundColor(AppColors.primaryText.opacity(0.5))
                    }
                
                Text(item.name)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(1)
                
                Text(item.color)
                    .font(.system(size: 12))
                    .foregroundColor(AppColors.secondaryText)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(AppColors.cardBackground)
            .roundedCorner(16)
            .shadow(color: AppColors.shadow.opacity(0.06), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            WardrobeItemDetailView(item: item)
        }
    }
}

struct EmptyWardrobeView: View {
    let category: ClothingCategory
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: category.icon)
                .font(.system(size: 64))
                .foregroundColor(AppColors.secondaryText)
            
            Text("Aucun article")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(AppColors.primaryText)
            
            Text("Ajoutez des vêtements à votre garde-robe pour commencer")
                .font(.system(size: 14))
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

struct AddWardrobeItemView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var wardrobeService = WardrobeService.shared
    @State private var name = ""
    @State private var category: ClothingCategory = .top
    @State private var color = ""
    
    var body: some View {
        NavigationStack {
            Form {
                TextField("Nom", text: $name)
                Picker("Catégorie", selection: $category) {
                    ForEach(ClothingCategory.allCases) { cat in
                        Text(cat.rawValue).tag(cat)
                    }
                }
                TextField("Couleur", text: $color)
            }
            .navigationTitle("Ajouter un vêtement")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ajouter") {
                        let item = WardrobeItem(
                            name: name,
                            category: category,
                            color: color,
                            brand: nil,
                            tags: []
                        )
                        wardrobeService.addItem(item)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct WardrobeItemDetailView: View {
    let item: WardrobeItem
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(item.name)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Catégorie: \(item.category.rawValue)")
                    Text("Couleur: \(item.color)")
                    
                    if let brand = item.brand {
                        Text("Marque: \(brand)")
                    }
                }
                .padding()
            }
            .background(AppColors.background)
            .navigationTitle(item.name)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

