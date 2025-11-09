//
//  WishlistScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct WishlistScreen: View {
    @StateObject private var wishlistService = WishlistService.shared
    @StateObject private var wardrobeService = WardrobeService()
    @State private var showingAddItem = false
    @State private var filter: WishlistFilter = .all
    
    enum WishlistFilter: String, CaseIterable {
        case all = "Tous"
        case unpurchased = "Non achetés"
        case purchased = "Achetés"
        case highPriority = "Priorité haute"
    }
    
    var filteredItems: [WishlistItem] {
        switch filter {
        case .all:
            return wishlistService.items
        case .unpurchased:
            return wishlistService.getUnpurchasedItems()
        case .purchased:
            return wishlistService.items.filter { $0.isPurchased }
        case .highPriority:
            return wishlistService.getItemsByPriority(.high) + wishlistService.getItemsByPriority(.urgent)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Filtres
                    Picker("Filtre", selection: $filter) {
                        ForEach(WishlistFilter.allCases, id: \.self) { filter in
                            Text(filter.rawValue.localized).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.top, DesignSystem.Spacing.md)
                    
                    // Liste
                    if filteredItems.isEmpty {
                        VStack(spacing: DesignSystem.Spacing.lg) {
                            Image(systemName: "heart.circle")
                                .font(.system(size: 60, weight: .light))
                                .foregroundColor(AppColors.secondaryText)
                            
                            Text("Votre wishlist est vide".localized)
                                .font(DesignSystem.Typography.title2())
                                .foregroundColor(AppColors.primaryText)
                            
                            Text("Ajoutez des vêtements que vous souhaitez acheter".localized)
                                .font(DesignSystem.Typography.body())
                                .foregroundColor(AppColors.secondaryText)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: DesignSystem.Spacing.md) {
                                ForEach(filteredItems) { item in
                                    WishlistItemCard(item: item)
                                        .padding(.horizontal, DesignSystem.Spacing.md)
                                }
                            }
                            .padding(.vertical, DesignSystem.Spacing.md)
                        }
                    }
                }
            }
            .navigationTitle("Wishlist".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Wishlist".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.primaryText)
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddWishlistItemScreen()
            }
        }
    }
}

struct WishlistItemCard: View {
    let item: WishlistItem
    @StateObject private var wishlistService = WishlistService.shared
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            HStack(spacing: DesignSystem.Spacing.md) {
                // Icône catégorie
                ZStack {
                    Circle()
                        .fill(AppColors.buttonPrimary.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: item.category.icon)
                        .font(.system(size: 22, weight: .medium))
                        .foregroundColor(AppColors.buttonPrimary)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(item.name)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.primaryText)
                        .strikethrough(item.isPurchased)
                    
                    if let description = item.description {
                        Text(description)
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(AppColors.secondaryText)
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: DesignSystem.Spacing.sm) {
                        if let price = item.price {
                            Text("\(String(format: "%.2f", price)) \(item.currency)")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(AppColors.secondaryText)
                        }
                        
                        Spacer()
                        
                        // Badge priorité
                        Text(item.priority.rawValue.localized)
                            .font(DesignSystem.Typography.caption())
                            .padding(.horizontal, DesignSystem.Spacing.sm)
                            .padding(.vertical, DesignSystem.Spacing.xs)
                            .background(item.priority.color.opacity(0.2))
                            .foregroundColor(item.priority.color)
                            .cornerRadius(DesignSystem.Radius.sm)
                    }
                }
                
                Spacer()
                
                HStack(spacing: DesignSystem.Spacing.sm) {
                    if !item.isPurchased {
                        Button {
                            wishlistService.markAsPurchased(item)
                        } label: {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 20, weight: .medium))
                                .foregroundColor(AppColors.buttonPrimary)
                        }
                    } else {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.green)
                    }
                    
                    Button {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.red)
                    }
                }
            }
            .padding(DesignSystem.Spacing.sm)
        }
        .alert("Supprimer".localized, isPresented: $showingDeleteAlert) {
            Button("Annuler".localized, role: .cancel) { }
            Button("Supprimer".localized, role: .destructive) {
                wishlistService.deleteItem(item)
            }
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer cet élément ?".localized)
        }
    }
}

struct AddWishlistItemScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var wishlistService = WishlistService.shared
    @State private var name = ""
    @State private var description = ""
    @State private var category: ClothingCategory = .top
    @State private var price: String = ""
    @State private var currency = "EUR"
    @State private var storeURL: String = ""
    @State private var priority: Priority = .medium
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("Nom".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                TextField("Nom du vêtement".localized, text: $name)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.primaryText)
                                    .padding(DesignSystem.Spacing.md)
                                    .background(AppColors.cardBackground)
                                    .cornerRadius(DesignSystem.Radius.sm)
                            }
                            .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("Description".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                TextField("Description (optionnel)".localized, text: $description, axis: .vertical)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.primaryText)
                                    .padding(DesignSystem.Spacing.md)
                                    .background(AppColors.cardBackground)
                                    .cornerRadius(DesignSystem.Radius.sm)
                                    .frame(minHeight: 80)
                            }
                            .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("Catégorie".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                Picker("Catégorie", selection: $category) {
                                    ForEach(ClothingCategory.allCases) { category in
                                        Text(category.rawValue.localized).tag(category)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("Prix".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                HStack(spacing: DesignSystem.Spacing.md) {
                                    TextField("Prix", text: $price)
                                        .keyboardType(.decimalPad)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(AppColors.primaryText)
                                        .padding(DesignSystem.Spacing.md)
                                        .background(AppColors.cardBackground)
                                        .cornerRadius(DesignSystem.Radius.sm)
                                    
                                    Picker("", selection: $currency) {
                                        Text("EUR").tag("EUR")
                                        Text("USD").tag("USD")
                                        Text("GBP").tag("GBP")
                                    }
                                    .pickerStyle(.menu)
                                }
                                
                                TextField("URL boutique (optionnel)".localized, text: $storeURL)
                                    .keyboardType(.URL)
                                    .autocapitalization(.none)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.primaryText)
                                    .padding(DesignSystem.Spacing.md)
                                    .background(AppColors.cardBackground)
                                    .cornerRadius(DesignSystem.Radius.sm)
                            }
                            .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("Priorité".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                Picker("Priorité", selection: $priority) {
                                    ForEach(Priority.allCases, id: \.self) { priority in
                                        Text(priority.rawValue.localized).tag(priority)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                    .padding(.vertical, DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Ajouter à la wishlist".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Ajouter à la wishlist".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler".localized) { dismiss() }
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter".localized) {
                        let item = WishlistItem(
                            name: name,
                            description: description.isEmpty ? nil : description,
                            category: category,
                            price: Double(price),
                            currency: currency,
                            storeURL: storeURL.isEmpty ? nil : storeURL,
                            priority: priority
                        )
                        wishlistService.addItem(item)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .foregroundColor(name.isEmpty ? AppColors.secondaryText : AppColors.buttonPrimary)
                }
            }
        }
    }
}
