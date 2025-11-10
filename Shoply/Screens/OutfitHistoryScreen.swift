//
//  OutfitHistoryScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import Combine

final class OutfitHistoryStore: ObservableObject {
    @Published var outfits: [HistoricalOutfit] = []
    private let dataManager = DataManager.shared
    private let historyKey = "historicalOutfits"
    
    init() {
        loadHistory()
    }
    
    func addOutfit(_ outfit: MatchedOutfit, date: Date = Date()) {
        let historical = HistoricalOutfit(
            id: UUID(),
            outfit: outfit,
            dateWorn: date
        )
        outfits.insert(historical, at: 0)
        saveHistory()
    }
    
    func removeOutfit(at index: Int) {
        guard outfits.indices.contains(index) else { return }
        outfits.remove(at: index)
        saveHistory()
    }
    
    func removeOutfit(byId id: UUID) {
        outfits.removeAll { $0.id == id }
        saveHistory()
    }
    
    func deleteAllOutfits() {
        outfits.removeAll()
        saveHistory()
    }
    
    func toggleFavorite(outfit: HistoricalOutfit) {
        if let index = outfits.firstIndex(where: { $0.id == outfit.id }) {
            outfits[index].isFavorite.toggle()
            saveHistory()
            
            if outfits[index].isFavorite {
                dataManager.addFavorite(outfitId: outfit.id)
            } else {
                dataManager.removeFavorite(outfitId: outfit.id)
            }
        }
    }
    
    func removeAllFavorites() {
        for outfit in outfits where outfit.isFavorite {
            dataManager.removeFavorite(outfitId: outfit.id)
        }
        outfits.indices.forEach { outfits[$0].isFavorite = false }
        saveHistory()
    }
    
    private func saveHistory() {
        if let encoded = try? JSONEncoder().encode(outfits) {
            UserDefaults.standard.set(encoded, forKey: historyKey)
        }
    }
    
    private func loadHistory() {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let decoded = try? JSONDecoder().decode([HistoricalOutfit].self, from: data) else {
            return
        }
        outfits = decoded
        let favoriteIds = dataManager.getAllFavorites()
        for (index, outfit) in outfits.enumerated() {
            outfits[index].isFavorite = favoriteIds.contains(outfit.id)
        }
    }
}

struct HistoricalOutfit: Identifiable, Codable {
    let id: UUID
    let outfit: MatchedOutfit
    let dateWorn: Date
    var isFavorite: Bool
    
    init(id: UUID = UUID(), outfit: MatchedOutfit, dateWorn: Date, isFavorite: Bool = false) {
        self.id = id
        self.outfit = outfit
        self.dateWorn = dateWorn
        self.isFavorite = isFavorite
    }
}

struct OutfitHistoryScreen: View {
    @StateObject private var historyStore = OutfitHistoryStore()
    @State private var showingDeleteAllAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if historyStore.outfits.isEmpty {
                    EmptyHistoryView()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // Statistiques
                            HistoryStatsCard(historyStore: historyStore)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                            
                            // Liste des outfits
                            LazyVStack(spacing: 16) {
                                ForEach(historyStore.outfits) { historicalOutfit in
                                    HistoricalOutfitCard(
                                        historicalOutfit: historicalOutfit,
                                        onToggleFavorite: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                historyStore.toggleFavorite(outfit: historicalOutfit)
                                            }
                                        },
                                        onDelete: {
                                            historyStore.removeOutfit(byId: historicalOutfit.id)
                                        }
                                    )
                                    .padding(.horizontal, 20)
                                }
                            }
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Historique".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Historique".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButtonWithLongPress()
                }
                
                if !historyStore.outfits.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button {
                            showingDeleteAllAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .alert("Supprimer tout l'historique".localized, isPresented: $showingDeleteAllAlert) {
                Button("Annuler".localized, role: .cancel) { }
                Button("Supprimer tout".localized, role: .destructive) {
                    historyStore.deleteAllOutfits()
                }
            } message: {
                Text("Êtes-vous sûr de vouloir supprimer tout l'historique ? Cette action est irréversible.".localized)
            }
        }
    }
}

// MARK: - Composants

struct HistoryStatsCard: View {
    @ObservedObject var historyStore: OutfitHistoryStore
    
    private var totalOutfits: Int {
        historyStore.outfits.count
    }
    
    private var averageComfort: Double {
        let scores = historyStore.outfits.map { $0.outfit.score }
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / Double(scores.count)
    }
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            HStack(spacing: 20) {
                StatItem(
                    value: "\(totalOutfits)",
                    label: "Outfits".localized,
                    icon: "sparkles",
                    color: AppColors.buttonPrimary
                )
                
                StatItem(
                    value: "\(Int(averageComfort))%",
                    label: "Confort".localized,
                    icon: "heart.fill",
                    color: .pink
                )
                
                StatItem(
                    value: "\(historyStore.outfits.filter { $0.isFavorite }.count)",
                    label: "Favoris".localized,
                    icon: "star.fill",
                    color: .orange
                )
            }
            .padding(20)
        }
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color.opacity(0.15))
                    .frame(width: 52, height: 52)
                
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColors.primaryText)
            
            Text(label)
                .font(DesignSystem.Typography.caption())
                .foregroundColor(AppColors.secondaryText)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HistoricalOutfitCard: View {
    let historicalOutfit: HistoricalOutfit
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    @State private var isPressed = false
    
    var body: some View {
        Button {
            // Action si nécessaire
        } label: {
            Card(cornerRadius: DesignSystem.Radius.lg) {
                VStack(spacing: 0) {
                    // En-tête
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(historicalOutfit.outfit.displayName)
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(AppColors.primaryText)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "calendar")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(AppColors.secondaryText)
                                
                                Text(historicalOutfit.dateWorn, style: .date)
                                    .font(DesignSystem.Typography.caption())
                                    .foregroundColor(AppColors.secondaryText)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 12) {
                            Button {
                                onToggleFavorite()
                            } label: {
                                Image(systemName: historicalOutfit.isFavorite ? "heart.fill" : "heart")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(historicalOutfit.isFavorite ? .red : AppColors.secondaryText)
                                    .frame(width: 40, height: 40)
                                    .background(Circle().fill(AppColors.buttonSecondary))
                            }
                            
                            Button {
                                showingDeleteAlert = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.red)
                                    .frame(width: 40, height: 40)
                                    .background(Circle().fill(AppColors.buttonSecondary))
                            }
                        }
                    }
                    .padding(20)
                    
                    Rectangle()
                        .fill(AppColors.separator.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 20)
                    
                    // Items
                    VStack(spacing: 12) {
                        ForEach(historicalOutfit.outfit.items) { item in
                            HistoricalOutfitItemRow(item: item)
                        }
                    }
                    .padding(20)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .alert("Supprimer cet outfit".localized, isPresented: $showingDeleteAlert) {
            Button("Annuler".localized, role: .cancel) { }
            Button("Supprimer".localized, role: .destructive) {
                onDelete()
            }
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer cet outfit ?".localized)
        }
    }
}

struct HistoricalOutfitItemRow: View {
    let item: WardrobeItem
    
    var body: some View {
        HStack(spacing: 14) {
            Group {
                let photoURL = item.photoURLs.first ?? item.photoURL
                if let photoURL = photoURL, !photoURL.isEmpty,
                   let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 64, height: 64)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                            .fill(AppColors.buttonSecondary)
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: item.category.icon)
                            .font(.system(size: 28, weight: .light))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.name)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(AppColors.primaryText)
                
                Text(item.category.rawValue)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
        }
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 32) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.buttonPrimary.opacity(0.15),
                                AppColors.buttonPrimary.opacity(0.05)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                
                Image(systemName: "clock")
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(AppColors.buttonPrimary)
            }
            
            VStack(spacing: 12) {
                Text("Aucun historique".localized)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(AppColors.primaryText)
                
                Text("Générez vos premiers outfits pour commencer votre historique".localized)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}
