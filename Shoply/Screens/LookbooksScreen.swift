//
//  LookbooksScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import PDFKit

struct LookbooksScreen: View {
    @StateObject private var historyStore = OutfitHistoryStore()
    @State private var lookbooks: [Lookbook] = []
    @State private var showingCreateLookbook = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if lookbooks.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Image(systemName: "book.fill")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text("Aucun lookbook".localized)
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("Créez un lookbook PDF de vos meilleurs outfits".localized)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        Button {
                            showingCreateLookbook = true
                        } label: {
                            Text("Créer un lookbook".localized)
                                .font(DesignSystem.Typography.headline())
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
                            ForEach(lookbooks) { lookbook in
                                NavigationLink(destination: LookbookDetailScreen(lookbook: lookbook)) {
                                    LookbookCard(lookbook: lookbook)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        lookbooks.removeAll { $0.id == lookbook.id }
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
            .navigationTitle("Lookbooks".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Lookbooks".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateLookbook = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.primaryText)
                    }
                }
            }
            .sheet(isPresented: $showingCreateLookbook) {
                CreateLookbookScreen(lookbooks: $lookbooks)
            }
        }
    }
}

struct LookbookCard: View {
    let lookbook: Lookbook
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            HStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(AppColors.buttonPrimary.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(AppColors.buttonPrimary)
                }
                
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(lookbook.title)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("\(lookbook.outfits.count) outfits".localized)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                Image(systemName: "doc.fill")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(AppColors.buttonPrimary)
            }
            .padding(DesignSystem.Spacing.sm)
        }
    }
}

struct LookbookDetailScreen: View {
    let lookbook: Lookbook
    @State private var showingExport = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text(lookbook.title)
                                    .font(DesignSystem.Typography.title2())
                                    .foregroundColor(AppColors.primaryText)
                                
                                if let description = lookbook.description {
                                    Text(description)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(AppColors.secondaryText)
                                }
                            }
                            .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.top, DesignSystem.Spacing.md)
                        
                        Button {
                            showingExport = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.up")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Exporter en PDF".localized)
                                    .font(DesignSystem.Typography.headline())
                            }
                            .foregroundColor(AppColors.buttonPrimaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.md)
                            .background(AppColors.buttonPrimary)
                            .cornerRadius(DesignSystem.Radius.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                    .padding(.bottom, DesignSystem.Spacing.xl)
                }
            }
            .navigationTitle("Lookbook".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Lookbook".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
            }
            .sheet(isPresented: $showingExport) {
                ExportPDFScreen(lookbook: lookbook)
            }
        }
    }
}

struct CreateLookbookScreen: View {
    @Environment(\.dismiss) var dismiss
    @Binding var lookbooks: [Lookbook]
    @StateObject private var historyStore = OutfitHistoryStore()
    @StateObject private var geminiService = GeminiService.shared
    @State private var title = ""
    @State private var description = ""
    @State private var theme: Lookbook.LookbookTheme = .minimal
    @State private var geminiDescription: String?
    @State private var isGenerating = false
    
    private var userProfile: UserProfile {
        DataManager.shared.loadUserProfile() ?? UserProfile()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("Titre".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                TextField("Titre du lookbook".localized, text: $title)
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
                                Text("Thème".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                Picker("Thème", selection: $theme) {
                                    ForEach(Lookbook.LookbookTheme.allCases, id: \.self) { theme in
                                        Text(theme.rawValue.localized).tag(theme)
                                    }
                                }
                                .pickerStyle(.menu)
                            }
                            .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("Génération avec Gemini".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                if isGenerating {
                                    ProgressView()
                                        .frame(maxWidth: .infinity)
                                } else if let geminiDesc = geminiDescription {
                                    Text(geminiDesc)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(AppColors.primaryText)
                                    
                                    Button("Utiliser cette description".localized) {
                                        description = geminiDesc
                                    }
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.buttonPrimaryText)
                                    .padding(.vertical, DesignSystem.Spacing.sm)
                                    .frame(maxWidth: .infinity)
                                    .background(AppColors.buttonPrimary)
                                    .cornerRadius(DesignSystem.Radius.sm)
                                } else {
                                    Button("Générer avec Gemini".localized) {
                                        generateWithGemini()
                                    }
                                    .disabled(title.isEmpty || historyStore.outfits.isEmpty)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor((title.isEmpty || historyStore.outfits.isEmpty) ? AppColors.secondaryText : AppColors.buttonPrimaryText)
                                    .padding(.vertical, DesignSystem.Spacing.sm)
                                    .frame(maxWidth: .infinity)
                                    .background((title.isEmpty || historyStore.outfits.isEmpty) ? AppColors.cardBackground : AppColors.buttonPrimary)
                                    .cornerRadius(DesignSystem.Radius.sm)
                                }
                            }
                            .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                    .padding(.vertical, DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Nouveau lookbook".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Nouveau lookbook".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler".localized) { dismiss() }
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer".localized) {
                        let lookbook = Lookbook(
                            title: title,
                            description: description.isEmpty ? geminiDescription : description,
                            outfits: historyStore.outfits.prefix(10).map { historicalOutfit in
                                LookbookOutfit(
                                    outfitId: historicalOutfit.id,
                                    photos: [],
                                    title: historicalOutfit.outfit.displayName,
                                    description: nil,
                                    occasion: nil,
                                    items: historicalOutfit.outfit.items.map { item in
                                        LookbookItem(
                                            itemId: item.id,
                                            name: item.name,
                                            category: item.category.rawValue,
                                            color: item.color,
                                            brand: item.brand
                                        )
                                    }
                                )
                            },
                            coverImageURL: nil,
                            createdAt: Date(),
                            theme: theme
                        )
                        lookbooks.append(lookbook)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .foregroundColor(title.isEmpty ? AppColors.secondaryText : AppColors.buttonPrimary)
                }
            }
        }
    }
    
    private func generateWithGemini() {
        isGenerating = true
        
        Task {
            do {
                let description = try await geminiService.generateLookbook(
                    title: title,
                    description: nil,
                    outfits: Array(historyStore.outfits.prefix(10)),
                    userProfile: userProfile
                )
                await MainActor.run {
                    geminiDescription = description
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                }
            }
        }
    }
}

struct ExportPDFScreen: View {
    @Environment(\.dismiss) var dismiss
    let lookbook: Lookbook
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: DesignSystem.Spacing.lg) {
                    Image(systemName: "doc.fill")
                        .font(.system(size: 60, weight: .light))
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text("Export PDF".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Votre lookbook sera exporté en PDF".localized)
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                    
                    Button {
                        // Exporter en PDF
                        dismiss()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 18, weight: .medium))
                            Text("Exporter".localized)
                                .font(DesignSystem.Typography.headline())
                        }
                        .foregroundColor(AppColors.buttonPrimaryText)
                        .padding(.horizontal, DesignSystem.Spacing.lg)
                        .padding(.vertical, DesignSystem.Spacing.md)
                        .background(AppColors.buttonPrimary)
                        .cornerRadius(DesignSystem.Radius.md)
                    }
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
                    Button("Annuler".localized) { dismiss() }
                        .foregroundColor(AppColors.primaryText)
                }
            }
        }
    }
}
