//
//  PriceComparisonScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct PriceComparisonScreen: View {
    @State private var comparisons: [PriceComparison] = []
    @State private var showingAddComparison = false
    @State private var searchQuery = ""
    
    var filteredComparisons: [PriceComparison] {
        if searchQuery.isEmpty {
            return comparisons
        }
        return comparisons.filter { $0.itemName.localizedCaseInsensitiveContains(searchQuery) }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if comparisons.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text("Aucune comparaison".localized)
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("Comparez les prix entre différents magasins".localized)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: DesignSystem.Spacing.md) {
                            ForEach(filteredComparisons) { comparison in
                                NavigationLink(destination: PriceComparisonDetailScreen(comparison: comparison)) {
                                    PriceComparisonCard(comparison: comparison)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        comparisons.removeAll { $0.id == comparison.id }
                                    } label: {
                                        Label("Supprimer".localized, systemImage: "trash")
                                    }
                                }
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                    }
                }
            }
            .navigationTitle("Comparateur de Prix".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Comparateur de Prix".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddComparison = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.primaryText)
                    }
                }
            }
            .searchable(text: $searchQuery, prompt: "Rechercher un produit".localized)
            .sheet(isPresented: $showingAddComparison) {
                AddPriceComparisonScreen(comparisons: $comparisons)
            }
        }
    }
}

struct PriceComparisonCard: View {
    let comparison: PriceComparison
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                Text(comparison.itemName)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(AppColors.primaryText)
                
                if let bestPrice = comparison.bestPrice {
                    HStack {
                        Text("Meilleur prix: \(String(format: "%.2f", bestPrice.price)) \(bestPrice.currency)".localized)
                            .font(DesignSystem.Typography.subheadline())
                            .foregroundColor(.green)
                        
                        Spacer()
                        
                        Text("\(comparison.prices.count) magasins".localized)
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
            .padding(DesignSystem.Spacing.sm)
        }
    }
}

struct PriceComparisonDetailScreen: View {
    let comparison: PriceComparison
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text(comparison.itemName)
                                    .font(DesignSystem.Typography.title2())
                                    .foregroundColor(AppColors.primaryText)
                            }
                            .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.top, DesignSystem.Spacing.md)
                        
                        if let bestPrice = comparison.bestPrice {
                            Card(cornerRadius: DesignSystem.Radius.lg) {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                    Text("Meilleur prix".localized)
                                        .font(DesignSystem.Typography.headline())
                                        .foregroundColor(AppColors.primaryText)
                                    
                                    Text("\(String(format: "%.2f", bestPrice.price)) \(bestPrice.currency) chez \(bestPrice.storeName)")
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(.green)
                                }
                                .padding(DesignSystem.Spacing.md)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                        
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("Tous les prix".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                ForEach(comparison.prices.sorted { $0.price < $1.price }) { price in
                                    StorePriceRow(price: price, isBest: price.id == comparison.bestPrice?.id)
                                }
                            }
                            .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                    .padding(.bottom, DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Comparaison".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Comparaison".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
            }
        }
    }
}

struct StorePriceRow: View {
    let price: StorePrice
    let isBest: Bool
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(price.storeName)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(AppColors.primaryText)
                
                Text("\(String(format: "%.2f", price.price)) \(price.currency)")
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(isBest ? .green : AppColors.primaryText)
            }
            
            Spacer()
            
            if isBest {
                Label("Meilleur".localized, systemImage: "star.fill")
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(.green)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(AppColors.cardBackground)
        .cornerRadius(DesignSystem.Radius.sm)
    }
}

struct AddPriceComparisonScreen: View {
    @Environment(\.dismiss) var dismiss
    @Binding var comparisons: [PriceComparison]
    @State private var itemName = ""
    @State private var category: ClothingCategory = .top
    @State private var prices: [StorePrice] = []
    @State private var storeName = ""
    @State private var price = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("Nom du produit".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                TextField("Nom du produit".localized, text: $itemName)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.primaryText)
                                    .padding(DesignSystem.Spacing.md)
                                    .background(AppColors.cardBackground)
                                    .cornerRadius(DesignSystem.Radius.sm)
                                
                                Picker("Catégorie", selection: $category) {
                                    ForEach(ClothingCategory.allCases) { cat in
                                        Text(cat.rawValue.localized).tag(cat)
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
                                    TextField("Nom du magasin".localized, text: $storeName)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(AppColors.primaryText)
                                        .padding(DesignSystem.Spacing.md)
                                        .background(AppColors.cardBackground)
                                        .cornerRadius(DesignSystem.Radius.sm)
                                    
                                    TextField("Prix", text: $price)
                                        .keyboardType(.decimalPad)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(AppColors.primaryText)
                                        .padding(DesignSystem.Spacing.md)
                                        .background(AppColors.cardBackground)
                                        .cornerRadius(DesignSystem.Radius.sm)
                                }
                                
                                Button("Ajouter un prix".localized) {
                                    if let priceValue = Double(price), !storeName.isEmpty {
                                        let storePrice = StorePrice(
                                            storeName: storeName,
                                            price: priceValue,
                                            currency: "EUR"
                                        )
                                        prices.append(storePrice)
                                        storeName = ""
                                        price = ""
                                    }
                                }
                                .disabled(storeName.isEmpty || price.isEmpty)
                                .font(DesignSystem.Typography.headline())
                                .foregroundColor((storeName.isEmpty || price.isEmpty) ? AppColors.secondaryText : AppColors.buttonPrimaryText)
                                .padding(.vertical, DesignSystem.Spacing.sm)
                                .frame(maxWidth: .infinity)
                                .background((storeName.isEmpty || price.isEmpty) ? AppColors.cardBackground : AppColors.buttonPrimary)
                                .cornerRadius(DesignSystem.Radius.sm)
                                
                                if !prices.isEmpty {
                                    ForEach(prices) { storePrice in
                                        HStack {
                                            Text(storePrice.storeName)
                                                .font(DesignSystem.Typography.body())
                                                .foregroundColor(AppColors.primaryText)
                                            
                                            Spacer()
                                            
                                            Text("\(String(format: "%.2f", storePrice.price)) \(storePrice.currency)")
                                                .font(DesignSystem.Typography.body())
                                                .foregroundColor(AppColors.primaryText)
                                        }
                                        .padding(DesignSystem.Spacing.sm)
                                        .background(AppColors.cardBackground)
                                        .cornerRadius(DesignSystem.Radius.sm)
                                    }
                                }
                            }
                            .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                    .padding(.vertical, DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Nouvelle comparaison".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Nouvelle comparaison".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler".localized) { dismiss() }
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer".localized) {
                        if !itemName.isEmpty && !prices.isEmpty {
                            let comparison = PriceComparison(
                                itemName: itemName,
                                category: category,
                                prices: prices
                            )
                            comparisons.append(comparison)
                            dismiss()
                        }
                    }
                    .disabled(itemName.isEmpty || prices.isEmpty)
                    .foregroundColor((itemName.isEmpty || prices.isEmpty) ? AppColors.secondaryText : AppColors.buttonPrimary)
                }
            }
        }
    }
}
