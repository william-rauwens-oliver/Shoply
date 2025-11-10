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
                    ModernEmptyLookbooksView {
                            showingCreateLookbook = true
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(lookbooks) { lookbook in
                                NavigationLink(destination: LookbookDetailScreen(lookbook: lookbook)) {
                                    ModernLookbookCard(lookbook: lookbook)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(20)
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

// MARK: - Composants Modernes

struct ModernEmptyLookbooksView: View {
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
                
                Image(systemName: "book.fill")
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(AppColors.secondaryText)
            }
            .shadow(color: AppColors.shadow.opacity(0.15), radius: 16, x: 0, y: 6)
            
            VStack(spacing: 12) {
                Text("Aucun lookbook".localized)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(AppColors.primaryText)
                
                Text("Créez un lookbook PDF de vos meilleurs outfits".localized)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: onCreate) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                    Text("Créer un lookbook".localized)
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

struct ModernLookbookCard: View {
    let lookbook: Lookbook
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
                    
                    Image(systemName: "book.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(AppColors.buttonPrimary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
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

struct LookbookDetailScreen: View {
    let lookbook: Lookbook
    @State private var showingExport = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        ModernLookbookHeader(lookbook: lookbook)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
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
                            .padding(.vertical, 16)
                            .background(AppColors.buttonPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
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

struct ModernLookbookHeader: View {
    let lookbook: Lookbook
    
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
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: "book.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundColor(AppColors.buttonPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text(lookbook.title)
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(AppColors.primaryText)
                            .fontWeight(.bold)
                        
                        if let description = lookbook.description {
                            Text(description)
                                .font(DesignSystem.Typography.body())
                                .foregroundColor(AppColors.secondaryText)
                                .lineLimit(2)
                        }
                    }
                    
                    Spacer()
                }
            }
            .padding(20)
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
                    VStack(spacing: 20) {
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Titre".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                TextField("Titre du lookbook".localized, text: $title)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.primaryText)
                                    .padding(16)
                                    .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                        
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Description".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                TextField("Description (optionnel)".localized, text: $description, axis: .vertical)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.primaryText)
                                    .padding(16)
                                    .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                                    .frame(minHeight: 80)
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                        
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 12) {
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
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
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
}

struct ExportPDFScreen: View {
    @Environment(\.dismiss) var dismiss
    let lookbook: Lookbook
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
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
                        .padding(.horizontal, 40)
                    
                    Button {
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
                .padding(40)
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
