//
//  SocialShareScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct SocialShareScreen: View {
    @StateObject private var historyStore = OutfitHistoryStore()
    @StateObject private var shareService = OutfitShareService.shared
    @State private var sharedOutfits: [HistoricalOutfit] = []
    @State private var receivedOutfits: [HistoricalOutfit] = []
    @State private var showingExportSheet = false
    @State private var showingImportSheet = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Sélecteur d'onglets moderne
                    SocialShareTabPicker(selectedTab: $selectedTab)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    
                    // Contenu selon l'onglet
                    if selectedTab == 0 {
                        if sharedOutfits.isEmpty {
                            ModernEmptySharedView {
                                showingExportSheet = true
                            }
                        } else {
                            ScrollView(showsIndicators: false) {
                                LazyVStack(spacing: 16) {
                                    ForEach(sharedOutfits) { outfit in
                                        ModernSharedOutfitCard(outfit: outfit)
                                            .padding(.horizontal, 20)
                                    }
                                }
                                .padding(.vertical, 20)
                            }
                        }
                    } else {
                        if receivedOutfits.isEmpty {
                            ModernEmptyReceivedView {
                                showingImportSheet = true
                            }
                        } else {
                            ScrollView(showsIndicators: false) {
                                LazyVStack(spacing: 16) {
                                    ForEach(receivedOutfits) { outfit in
                                        ModernSharedOutfitCard(outfit: outfit)
                                            .padding(.horizontal, 20)
                                    }
                                }
                                .padding(.vertical, 20)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Partage Social".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Partage Social".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                        if selectedTab == 0 {
                            Button {
                                showingExportSheet = true
                            } label: {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppColors.primaryText)
                            }
                        } else {
                            Button {
                                showingImportSheet = true
                            } label: {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppColors.primaryText)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportOutfitsScreen(outfits: historyStore.outfits)
            }
            .sheet(isPresented: $showingImportSheet) {
                ImportOutfitsScreen { importedOutfits in
                    receivedOutfits.append(contentsOf: importedOutfits)
            }
            }
        }
    }
}

// MARK: - Composants Modernes

struct SocialShareTabPicker: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<2) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    Text(index == 0 ? "Outfits partagés".localized : "Outfits reçus".localized)
                        .font(DesignSystem.Typography.footnote())
                        .fontWeight(.semibold)
                        .foregroundColor(selectedTab == index ? AppColors.buttonPrimaryText : AppColors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == index ? AppColors.buttonPrimary : Color.clear)
                }
            }
        }
        .background(AppColors.buttonSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
            }
        }

struct ModernEmptySharedView: View {
    let onExport: () -> Void
    
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
                
                Image(systemName: "square.and.arrow.up")
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(AppColors.secondaryText)
            }
            .shadow(color: AppColors.shadow.opacity(0.15), radius: 16, x: 0, y: 6)
            
            VStack(spacing: 12) {
                Text("Aucun outfit partagé".localized)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(AppColors.primaryText)
                
                Text("Exportez vos outfits portés pour les partager".localized)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: onExport) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .medium))
                    Text("Exporter des outfits".localized)
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

struct ModernEmptyReceivedView: View {
    let onImport: () -> Void
    
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
                
                Image(systemName: "square.and.arrow.down")
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(AppColors.secondaryText)
            }
            .shadow(color: AppColors.shadow.opacity(0.15), radius: 16, x: 0, y: 6)
            
            VStack(spacing: 12) {
                Text("Aucun outfit reçu".localized)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(AppColors.primaryText)
                
                Text("Importez des outfits partagés par d'autres".localized)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: onImport) {
                HStack {
                    Image(systemName: "square.and.arrow.down")
                        .font(.system(size: 18, weight: .medium))
                    Text("Importer des outfits".localized)
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

struct ModernSharedOutfitCard: View {
    let outfit: HistoricalOutfit
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
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(AppColors.buttonPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                Text(outfit.outfit.displayName)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(AppColors.primaryText)
                
                Text(outfit.dateWorn, style: .date)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(AppColors.secondaryText)
                    }
                    
                    Spacer()
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

struct ExportOutfitsScreen: View {
    @Environment(\.dismiss) var dismiss
    let outfits: [HistoricalOutfit]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Exporter \(outfits.count) outfit\(outfits.count > 1 ? "s" : "")".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                    
                    Button {
                        // Logique d'export
                        dismiss()
                    } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18, weight: .medium))
                            Text("Exporter".localized)
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
            .navigationTitle("Export".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler".localized) { dismiss() }
                        .foregroundColor(AppColors.primaryText)
                }
            }
        }
    }
}

struct ImportOutfitsScreen: View {
    @Environment(\.dismiss) var dismiss
    let onImport: ([HistoricalOutfit]) -> Void
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    Text("Importer des outfits".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                    
                    Button {
                        // Logique d'import
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.down")
                                .font(.system(size: 18, weight: .medium))
                            Text("Importer".localized)
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
            .navigationTitle("Import".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler".localized) { dismiss() }
                        .foregroundColor(AppColors.primaryText)
                }
            }
        }
    }
}
