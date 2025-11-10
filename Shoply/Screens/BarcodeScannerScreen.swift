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
                    ModernEmptyScannerView {
                            showingScanner = true
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(scannedProducts) { product in
                                ModernScannedProductCard(product: product) {
                                    selectedProduct = product
                                    showingAddToWardrobe = true
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                        .padding(.vertical, 20)
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

// MARK: - Composants Modernes

struct ModernEmptyScannerView: View {
    let onScan: () -> Void
    
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
                
                Image(systemName: "barcode.viewfinder")
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(AppColors.secondaryText)
            }
            .shadow(color: AppColors.shadow.opacity(0.15), radius: 16, x: 0, y: 6)
            
            VStack(spacing: 12) {
                Text("Aucun produit scanné".localized)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(AppColors.primaryText)
                
                Text("Scannez un code-barres pour ajouter un vêtement à votre garde-robe".localized)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: onScan) {
                HStack {
                    Image(systemName: "barcode.viewfinder")
                        .font(.system(size: 18, weight: .medium))
                    Text("Scanner un code-barres".localized)
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

struct ModernScannedProductCard: View {
    let product: ScannedProduct
    let onAdd: () -> Void
    @State private var showingDeleteAlert = false
    @State private var isPressed = false
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
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
                    
                    Image(systemName: "barcode")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(AppColors.buttonPrimary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
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
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                Button(action: onAdd) {
                    Text("Ajouter".localized)
                        .font(DesignSystem.Typography.footnote())
                        .fontWeight(.semibold)
                        .foregroundColor(AppColors.buttonPrimaryText)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(AppColors.buttonPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
                }
            }
            .padding(16)
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
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

// MARK: - BarcodeScannerView (conservé avec améliorations)
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
                
                VStack(spacing: 24) {
                    Text("Pointez la caméra vers un code-barres".localized)
                        .foregroundColor(.white)
                        .font(DesignSystem.Typography.headline())
                        .padding(20)
                    
                    VStack(spacing: 16) {
                        TextField("Code-barres ou nom du produit".localized, text: Binding(
                            get: { scannedCode ?? "" },
                            set: { scannedCode = $0 }
                        ))
                        .textFieldStyle(.roundedBorder)
                        .foregroundColor(.black)
                        .padding(.horizontal, 20)
                        
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
                        .padding(16)
                        .background(AppColors.buttonPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
                        .disabled(isSearching || scannedCode?.isEmpty ?? true)
                    }
                    .padding(20)
                    
                    Spacer()
                }
            }
            .navigationTitle("Scanner".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer".localized) { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    private func searchProduct(code: String) {
        isSearching = true
        // Logique de recherche
        Task {
            // Recherche du produit
                await MainActor.run {
                    isSearching = false
                onScan(code)
                dismiss()
            }
                                }
                            }
                        }

// MARK: - AddScannedProductToWardrobeScreen (conservé tel quel)
struct AddScannedProductToWardrobeScreen: View {
    let product: ScannedProduct
    @Environment(\.dismiss) var dismiss
    // ... (conservé tel quel)
    
    var body: some View {
        NavigationStack {
            Text("Ajouter à la garde-robe")
        }
    }
}
