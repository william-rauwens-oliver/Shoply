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
                    // Sélecteur d'onglets
                    Picker("", selection: $selectedTab) {
                        Text("Outfits partagés".localized).tag(0)
                        Text("Outfits reçus".localized).tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.top, DesignSystem.Spacing.md)
                    
                    if selectedTab == 0 {
                        // Outfits partagés
                        if sharedOutfits.isEmpty {
                            VStack(spacing: DesignSystem.Spacing.lg) {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 60, weight: .light))
                                    .foregroundColor(AppColors.secondaryText)
                                
                                Text("Aucun outfit partagé".localized)
                                    .font(DesignSystem.Typography.title2())
                                    .foregroundColor(AppColors.primaryText)
                                
                                Text("Exportez vos outfits portés pour les partager".localized)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, DesignSystem.Spacing.lg)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView(showsIndicators: false) {
                                LazyVStack(spacing: DesignSystem.Spacing.md) {
                                    ForEach(sharedOutfits) { outfit in
                                        SharedOutfitCard(outfit: outfit)
                                            .padding(.horizontal, DesignSystem.Spacing.md)
                                    }
                                }
                                .padding(.vertical, DesignSystem.Spacing.md)
                            }
                        }
                    } else {
                        // Outfits reçus
                        if receivedOutfits.isEmpty {
                            VStack(spacing: DesignSystem.Spacing.lg) {
                                Image(systemName: "square.and.arrow.down")
                                    .font(.system(size: 60, weight: .light))
                                    .foregroundColor(AppColors.secondaryText)
                                
                                Text("Aucun outfit reçu".localized)
                                    .font(DesignSystem.Typography.title2())
                                    .foregroundColor(AppColors.primaryText)
                                
                                Text("Importez des outfits partagés par d'autres".localized)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, DesignSystem.Spacing.lg)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        } else {
                            ScrollView(showsIndicators: false) {
                                LazyVStack(spacing: DesignSystem.Spacing.md) {
                                    ForEach(receivedOutfits) { outfit in
                                        SharedOutfitCard(outfit: outfit)
                                            .padding(.horizontal, DesignSystem.Spacing.md)
                                    }
                                }
                                .padding(.vertical, DesignSystem.Spacing.md)
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
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
            }
            .sheet(isPresented: $showingExportSheet) {
                ExportOutfitsScreen()
            }
            .sheet(isPresented: $showingImportSheet) {
                ImportOutfitsScreen()
            }
            .onAppear {
                loadSharedOutfits()
                loadReceivedOutfits()
            }
        }
    }
    
    private func loadSharedOutfits() {
        // Charger depuis l'historique
        sharedOutfits = historyStore.outfits
    }
    
    private func loadReceivedOutfits() {
        receivedOutfits = shareService.loadReceivedOutfits()
    }
}

struct SharedOutfitCard: View {
    let outfit: HistoricalOutfit
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                Text(outfit.outfit.displayName)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(AppColors.primaryText)
                
                Text(outfit.dateWorn, style: .date)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(AppColors.secondaryText)
                
                if outfit.isFavorite {
                    HStack(spacing: DesignSystem.Spacing.xs) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 12, weight: .medium))
                        Text("Favori".localized)
                            .font(DesignSystem.Typography.caption())
                    }
                    .foregroundColor(AppColors.buttonPrimary)
                }
            }
            .padding(DesignSystem.Spacing.sm)
        }
    }
}

struct ExportOutfitsScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var historyStore = OutfitHistoryStore()
    @State private var isExporting = false
    @State private var exportError: String?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                    Text("Exporter les outfits".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                        .padding(.top, DesignSystem.Spacing.md)
                    
                    Text("\(historyStore.outfits.count) outfits disponibles à l'export".localized)
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    if let error = exportError {
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            Text("Erreur: \(error)".localized)
                                .font(DesignSystem.Typography.body())
                                .foregroundColor(.red)
                                .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                    
                    Button {
                        exportOutfits()
                    } label: {
                        if isExporting {
                            ProgressView()
                                .foregroundColor(AppColors.buttonPrimaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignSystem.Spacing.md)
                                .background(AppColors.buttonPrimary)
                                .cornerRadius(DesignSystem.Radius.md)
                        } else {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Exporter en JSON".localized)
                                    .font(DesignSystem.Typography.headline())
                            }
                            .foregroundColor(AppColors.buttonPrimaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.md)
                            .background(AppColors.buttonPrimary)
                            .cornerRadius(DesignSystem.Radius.md)
                        }
                    }
                    .disabled(isExporting)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .navigationTitle("Export".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Export".localized)
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
    
    private func exportOutfits() {
        isExporting = true
        exportError = nil
        
        do {
            let jsonData = try OutfitShareService.shared.exportOutfitsToJSON(outfits: historyStore.outfits)
            
            // Sauvegarder dans les fichiers de l'app pour partage
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsPath.appendingPathComponent("outfits_export_\(Date().timeIntervalSince1970).json")
            
            try jsonData.write(to: fileURL)
            
            // Partager le fichier
            let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootViewController = windowScene.windows.first?.rootViewController {
                rootViewController.present(activityVC, animated: true)
            }
            
            isExporting = false
            dismiss()
        } catch {
            exportError = error.localizedDescription
            isExporting = false
        }
    }
}

struct ImportOutfitsScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var shareService = OutfitShareService.shared
    @State private var isImporting = false
    @State private var importError: String?
    @State private var showingDocumentPicker = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                    Text("Importer des outfits".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                        .padding(.top, DesignSystem.Spacing.md)
                    
                    Text("Sélectionnez un fichier JSON d'outfits partagés".localized)
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    if let error = importError {
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            Text("Erreur: \(error)".localized)
                                .font(DesignSystem.Typography.body())
                                .foregroundColor(.red)
                                .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                    
                    Button {
                        showingDocumentPicker = true
                    } label: {
                        HStack {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 18, weight: .medium))
                            Text("Sélectionner un fichier".localized)
                                .font(DesignSystem.Typography.headline())
                        }
                        .foregroundColor(AppColors.buttonPrimaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(AppColors.buttonPrimary)
                        .cornerRadius(DesignSystem.Radius.md)
                    }
                    .disabled(isImporting)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .navigationTitle("Import".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Import".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Fermer".localized) { dismiss() }
                        .foregroundColor(AppColors.primaryText)
                }
            }
            .fileImporter(
                isPresented: $showingDocumentPicker,
                allowedContentTypes: [UTType.json],
                allowsMultipleSelection: false
            ) { result in
                handleFileSelection(result)
            }
        }
    }
    
    private func handleFileSelection(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            importOutfits(from: url)
        case .failure(let error):
            importError = error.localizedDescription
        }
    }
    
    private func importOutfits(from url: URL) {
        isImporting = true
        importError = nil
        
        do {
            let jsonData = try Data(contentsOf: url)
            let outfits = try shareService.importOutfitsFromJSON(data: jsonData)
            
            // Sauvegarder les outfits reçus
            shareService.saveReceivedOutfits(outfits)
            
            isImporting = false
            dismiss()
        } catch {
            importError = error.localizedDescription
            isImporting = false
        }
    }
}
