//
//  BarcodeScannerScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import AVFoundation

struct BarcodeScannerScreen: View {
    @StateObject private var wardrobeService = WardrobeService()
    @State private var scannedProducts: [ScannedProduct] = []
    @State private var showingScanner = false
    @State private var showingAddToWardrobe = false
    @State private var selectedProduct: ScannedProduct?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if scannedProducts.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text("Aucun produit scanné".localized)
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("Scannez un code-barres pour ajouter un vêtement à votre garde-robe".localized)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        Button {
                            showingScanner = true
                        } label: {
                            HStack {
                                Image(systemName: "barcode.viewfinder")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Scanner un code-barres".localized)
                                    .font(DesignSystem.Typography.headline())
                            }
                            .foregroundColor(AppColors.buttonPrimaryText)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                            .padding(.vertical, DesignSystem.Spacing.md)
                            .background(AppColors.buttonPrimary)
                            .cornerRadius(DesignSystem.Radius.md)
                        }
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: DesignSystem.Spacing.md) {
                            ForEach(scannedProducts) { product in
                                ScannedProductCard(product: product) {
                                    selectedProduct = product
                                    showingAddToWardrobe = true
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)
                            }
                        }
                        .padding(.vertical, DesignSystem.Spacing.md)
                    }
                }
            }
            .navigationTitle("Scanner".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Scanner".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingScanner = true
                    } label: {
                        Image(systemName: "barcode.viewfinder")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.primaryText)
                    }
                }
            }
            .sheet(isPresented: $showingScanner) {
                BarcodeScannerView { barcode in
                    let product = ScannedProduct(barcode: barcode)
                    scannedProducts.append(product)
                    showingScanner = false
                }
            }
            .sheet(isPresented: $showingAddToWardrobe) {
                if let product = selectedProduct {
                    AddScannedProductToWardrobeScreen(product: product)
                }
            }
        }
    }
}

struct ScannedProductCard: View {
    let product: ScannedProduct
    let onAdd: () -> Void
    @State private var showingDeleteAlert = false
    @State private var scannedProducts: [ScannedProduct] = []
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            HStack(spacing: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(product.name ?? "Produit scanné".localized)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Code: \(product.barcode)")
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.secondaryText)
                    
                    if let price = product.price {
                        Text("\(String(format: "%.2f", price)) \(product.currency)")
                            .font(DesignSystem.Typography.subheadline())
                            .foregroundColor(AppColors.buttonPrimary)
                    }
                }
                
                Spacer()
                
                Button {
                    onAdd()
                } label: {
                    Text("Ajouter".localized)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.buttonPrimaryText)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                        .background(AppColors.buttonPrimary)
                        .cornerRadius(DesignSystem.Radius.sm)
                }
            }
            .padding(DesignSystem.Spacing.sm)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Supprimer".localized, systemImage: "trash")
            }
        }
        .alert("Supprimer".localized, isPresented: $showingDeleteAlert) {
            Button("Annuler".localized, role: .cancel) { }
            Button("Supprimer".localized, role: .destructive) {
                // Supprimer le produit
            }
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer ce produit ?".localized)
        }
    }
}

struct BarcodeScannerView: View {
    @Environment(\.dismiss) var dismiss
    let onScan: (String) -> Void
    @State private var scannedCode: String?
    @State private var isSearching = false
    @State private var searchResults: [ProductResult] = []
    @State private var showingResults = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                    Text("Pointez la caméra vers un code-barres".localized)
                        .foregroundColor(.white)
                        .font(DesignSystem.Typography.headline())
                        .padding(DesignSystem.Spacing.md)
                    
                    VStack(spacing: DesignSystem.Spacing.md) {
                        TextField("Code-barres ou nom du produit".localized, text: Binding(
                            get: { scannedCode ?? "" },
                            set: { scannedCode = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .foregroundColor(.black)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        Button {
                            if let code = scannedCode, !code.isEmpty {
                                searchProduct(code: code)
                            }
                        } label: {
                            if isSearching {
                                ProgressView()
                                    .foregroundColor(.white)
                            } else {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                    Text("Rechercher".localized)
                                }
                                .foregroundColor(.white)
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                        .background(AppColors.buttonPrimary)
                        .cornerRadius(DesignSystem.Radius.md)
                        .disabled(isSearching || scannedCode?.isEmpty ?? true)
                    }
                    .padding(DesignSystem.Spacing.md)
                }
            }
            .navigationTitle("Scanner".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Scanner".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler".localized) { dismiss() }
                        .foregroundColor(.white)
                }
            }
            .sheet(isPresented: $showingResults) {
                ProductSearchResultsScreen(results: searchResults) { product in
                    onScan(product.barcode ?? product.name)
                    dismiss()
                }
            }
        }
    }
    
    private func searchProduct(code: String) {
        isSearching = true
        Task {
            do {
                let results = try await ProductSearchService.shared.searchProduct(barcode: code, name: code)
                await MainActor.run {
                    searchResults = results
                    isSearching = false
                    showingResults = true
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                }
            }
        }
    }
}

struct ProductSearchResultsScreen: View {
    @Environment(\.dismiss) var dismiss
    let results: [ProductResult]
    let onSelect: (ProductResult) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if results.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text("Aucun résultat".localized)
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(AppColors.primaryText)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: DesignSystem.Spacing.md) {
                            ForEach(results) { product in
                                Button {
                                    onSelect(product)
                                } label: {
                                    ProductResultCard(product: product)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                    }
                }
            }
            .navigationTitle("Résultats".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Résultats".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer".localized) { dismiss() }
                        .foregroundColor(AppColors.primaryText)
                }
            }
        }
    }
}

struct ProductResultCard: View {
    let product: ProductResult
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            HStack(spacing: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(product.name)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.primaryText)
                    
                    if let brand = product.brand {
                        Text(brand)
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    if let price = product.price {
                        Text("\(String(format: "%.2f", price)) \(product.currency)")
                            .font(DesignSystem.Typography.subheadline())
                            .foregroundColor(AppColors.buttonPrimary)
                    }
                }
                
                Spacer()
                
                Text(product.storeName)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(AppColors.secondaryText)
            }
            .padding(DesignSystem.Spacing.sm)
        }
    }
}

struct AddScannedProductToWardrobeScreen: View {
    @Environment(\.dismiss) var dismiss
    let product: ScannedProduct
    @StateObject private var wardrobeService = WardrobeService()
    @State private var name = ""
    @State private var category: ClothingCategory = .top
    @State private var color = ""
    @State private var brand = ""
    
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
                                Text("Catégorie".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
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
                                Text("Couleur".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                TextField("Couleur".localized, text: $color)
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
                                Text("Marque".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                TextField("Marque".localized, text: $brand)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.primaryText)
                                    .padding(DesignSystem.Spacing.md)
                                    .background(AppColors.cardBackground)
                                    .cornerRadius(DesignSystem.Radius.sm)
                            }
                            .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        if let price = product.price {
                            Card(cornerRadius: DesignSystem.Radius.lg) {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                    Text("Prix".localized)
                                        .font(DesignSystem.Typography.headline())
                                        .foregroundColor(AppColors.primaryText)
                                    
                                    Text("\(String(format: "%.2f", price)) \(product.currency)")
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(AppColors.primaryText)
                                }
                                .padding(DesignSystem.Spacing.md)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Ajouter à la garde-robe".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Ajouter à la garde-robe".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler".localized) { dismiss() }
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ajouter".localized) {
                        let item = WardrobeItem(
                            name: name.isEmpty ? (product.name ?? "Nouveau vêtement".localized) : name,
                            category: category,
                            color: color.isEmpty ? "Non spécifié".localized : color,
                            brand: brand.isEmpty ? product.brand : brand,
                            tags: product.price != nil ? ["price:\(product.price!)"] : []
                        )
                        wardrobeService.addItem(item)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .foregroundColor(name.isEmpty ? AppColors.secondaryText : AppColors.buttonPrimary)
                }
            }
        }
    }
}
