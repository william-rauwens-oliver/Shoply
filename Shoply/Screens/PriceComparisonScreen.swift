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
                    ModernEmptyPriceComparisonView {
                        showingAddComparison = true
                    }
                } else {
                    VStack(spacing: 0) {
                        // Barre de recherche moderne
                        PriceComparisonSearchBar(text: $searchQuery)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                        
                    ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 16) {
                            ForEach(filteredComparisons) { comparison in
                                NavigationLink(destination: PriceComparisonDetailScreen(comparison: comparison)) {
                                        ModernPriceComparisonCard(comparison: comparison)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                            .padding(20)
                        }
                    }
                }
            }
            .navigationTitle("Comparateur de Prix".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Comparateur de Prix".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButtonWithLongPress()
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
            .sheet(isPresented: $showingAddComparison) {
                AddPriceComparisonScreen(comparisons: $comparisons)
            }
        }
    }
}

// MARK: - Composants Modernes

struct PriceComparisonSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppColors.secondaryText)
            
            TextField("Rechercher un produit...".localized, text: $text)
                .font(DesignSystem.Typography.body())
                .foregroundColor(AppColors.primaryText)
                .focused($isFocused)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.secondaryText)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .liquidGlassCard(cornerRadius: DesignSystem.Radius.lg)
    }
}

struct ModernEmptyPriceComparisonView: View {
    let onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
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
                            .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 2)
                    }
                
                Image(systemName: "dollarsign.circle.fill")
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(AppColors.secondaryText)
            }
            .shadow(color: AppColors.shadow.opacity(0.15), radius: 16, x: 0, y: 6)
            
            VStack(spacing: 12) {
                Text("Aucune comparaison".localized)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(AppColors.primaryText)
                
                Text("Comparez les prix entre différents magasins".localized)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: onCreate) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                    Text("Créer une comparaison".localized)
                        .font(DesignSystem.Typography.headline())
                }
                .foregroundColor(AppColors.buttonPrimaryText)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(AppColors.buttonPrimary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
            }
        }
    }
}

struct ModernPriceComparisonCard: View {
    let comparison: PriceComparison
    @State private var isPressed = false
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.buttonPrimary.opacity(0.2),
                                        AppColors.buttonPrimary.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                        
                        Image(systemName: "dollarsign.circle.fill")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(AppColors.buttonPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                Text(comparison.itemName)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(AppColors.primaryText)
                
                if let bestPrice = comparison.bestPrice {
                            HStack(spacing: 8) {
                        Text("Meilleur prix: \(String(format: "%.2f", bestPrice.price)) \(bestPrice.currency)".localized)
                                    .font(DesignSystem.Typography.footnote())
                            .foregroundColor(.green)
                                    .fontWeight(.semibold)
                            }
                        }
                    }
                        
                        Spacer()
                        
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(comparison.prices.count) magasins".localized)
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(AppColors.secondaryText)
                        
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
            .padding(20)
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
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
                    VStack(spacing: 20) {
                        ModernPriceComparisonHeader(comparison: comparison)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        if let bestPrice = comparison.bestPrice {
                            ModernBestPriceCard(bestPrice: bestPrice)
                                .padding(.horizontal, 20)
                        }
                        
                        ModernAllPricesSection(comparison: comparison)
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
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

struct ModernPriceComparisonHeader: View {
    let comparison: PriceComparison
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppColors.buttonPrimary.opacity(0.2),
                                    AppColors.buttonPrimary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: "dollarsign.circle.fill")
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(AppColors.buttonPrimary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(comparison.itemName)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                        .fontWeight(.bold)
                    
                    Text("\(comparison.prices.count) magasins comparés".localized)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
            }
            .padding(20)
        }
    }
}

struct ModernBestPriceCard: View {
    let bestPrice: StorePrice
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.15))
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "star.fill")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Meilleur prix".localized)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("\(String(format: "%.2f", bestPrice.price)) \(bestPrice.currency) chez \(bestPrice.storeName)")
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(.green)
                        .fontWeight(.semibold)
                }
                
                Spacer()
            }
            .padding(20)
        }
    }
}

struct ModernAllPricesSection: View {
    let comparison: PriceComparison
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(alignment: .leading, spacing: 16) {
                Text("Tous les prix".localized)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(AppColors.primaryText)
                
                ForEach(comparison.prices.sorted { $0.price < $1.price }) { price in
                    ModernStorePriceRow(
                        price: price,
                        isBest: price.id == comparison.bestPrice?.id
                    )
                }
            }
            .padding(20)
        }
    }
}

struct ModernStorePriceRow: View {
    let price: StorePrice
    let isBest: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(price.storeName)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(AppColors.primaryText)
                
                Text("\(String(format: "%.2f", price.price)) \(price.currency)")
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(isBest ? .green : AppColors.primaryText)
                    .fontWeight(isBest ? .semibold : .regular)
            }
            
            Spacer()
            
            if isBest {
                HStack(spacing: 6) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 14, weight: .medium))
                    Text("Meilleur".localized)
                    .font(DesignSystem.Typography.caption())
                }
                    .foregroundColor(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.green.opacity(0.15))
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.sm))
            }
        }
        .padding(16)
        .background(isBest ? Color.green.opacity(0.05) : AppColors.buttonSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
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
                    VStack(spacing: 20) {
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Nom du produit".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                TextField("Nom du produit".localized, text: $itemName)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.primaryText)
                                    .padding(16)
                                    .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                                
                                Picker("Catégorie", selection: $category) {
                                    ForEach(ClothingCategory.allCases) { cat in
                                        Text(cat.rawValue.localized).tag(cat)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                        
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Prix".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                HStack(spacing: 12) {
                                    TextField("Nom du magasin".localized, text: $storeName)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(AppColors.primaryText)
                                        .padding(16)
                                        .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                                    
                                    TextField("Prix", text: $price)
                                        .keyboardType(.decimalPad)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(AppColors.primaryText)
                                        .padding(16)
                                        .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
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
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background((storeName.isEmpty || price.isEmpty) ? AppColors.cardBackground : AppColors.buttonPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
                                
                                if !prices.isEmpty {
                                    ForEach(prices) { storePrice in
                                        ModernStorePriceRow(price: storePrice, isBest: false)
                                    }
                                }
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
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
