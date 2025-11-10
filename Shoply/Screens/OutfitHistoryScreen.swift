//
//  OutfitHistoryScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import Combine

/// Store pour l'historique des outfits portés
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

/// Outfit historique avec date et favori
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

/// Écran d'historique des outfits portés - Design moderne
struct OutfitHistoryScreen: View {
    @StateObject private var historyStore = OutfitHistoryStore()
    @State private var showingDeleteAllAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if historyStore.outfits.isEmpty {
                    ModernEmptyHistoryView()
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Statistiques modernes
                            ModernHistoryStatsCard(historyStore: historyStore)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                            
                            // Liste des outfits
                            LazyVStack(spacing: 16) {
                                ForEach(historyStore.outfits) { historicalOutfit in
                                    ModernHistoricalOutfitCard(
                                        historicalOutfit: historicalOutfit,
                                        onToggleFavorite: {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            historyStore.toggleFavorite(outfit: historicalOutfit)
                                            }
                                        },
                                        onDelete: {
                                            if let index = historyStore.outfits.firstIndex(where: { $0.id == historicalOutfit.id }) {
                                                historyStore.removeOutfit(at: index)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationTitle("Historique".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Historique".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                if !historyStore.outfits.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingDeleteAllAlert = true
                        }) {
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

// MARK: - Composants Modernes

struct ModernHistoryStatsCard: View {
    @ObservedObject var historyStore: OutfitHistoryStore
    
    private var totalOutfits: Int {
        historyStore.outfits.count
    }
    
    private var averageComfort: Double {
        let scores = historyStore.outfits.map { $0.outfit.score }
        guard !scores.isEmpty else { return 0 }
        return scores.reduce(0, +) / Double(scores.count)
    }
    
    private var mostWornStyle: String {
        let styles = historyStore.outfits.compactMap { outfit -> String? in
            if outfit.outfit.reason.contains("casual") || outfit.outfit.reason.contains("décontracté") {
                return "Décontracté"
            } else if outfit.outfit.reason.contains("business") || outfit.outfit.reason.contains("professionnel") {
                return "Professionnel"
            } else if outfit.outfit.reason.contains("formal") || outfit.outfit.reason.contains("formel") {
                return "Formel"
            }
            return nil
        }
        
        let styleCounts = Dictionary(grouping: styles, by: { $0 }).mapValues { $0.count }
        if let mostCommon = styleCounts.max(by: { $0.value < $1.value }) {
            return mostCommon.key
        }
        return "Varié"
    }
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(spacing: 20) {
                HStack {
                    Text("Statistiques".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                    Spacer()
                }
                
                HStack(spacing: 20) {
                    ModernStatItem(
                        value: "\(totalOutfits)",
                        label: "Outfits portés".localized,
                        icon: "sparkles",
                        color: .blue
                    )
                    
                    ModernStatItem(
                        value: "\(Int(averageComfort))%",
                        label: "Confort moyen".localized,
                        icon: "heart.fill",
                        color: .pink
                    )
                    
                    ModernStatItem(
                        value: mostWornStyle,
                        label: "Style favori".localized,
                        icon: "star.fill",
                        color: .orange
                    )
                }
            }
            .padding(20)
        }
    }
}

struct ModernStatItem: View {
    let value: String
    let label: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 44, height: 44)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            Text(value)
                .font(DesignSystem.Typography.title2())
                .foregroundColor(AppColors.primaryText)
                .fontWeight(.bold)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            Text(label)
                .font(DesignSystem.Typography.caption())
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .lineLimit(2)
        }
        .frame(maxWidth: .infinity)
    }
}

struct ModernHistoricalOutfitCard: View {
    let historicalOutfit: HistoricalOutfit
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
        VStack(spacing: 0) {
                // En-tête
                HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(historicalOutfit.outfit.displayName)
                            .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                            .fontWeight(.semibold)
                    
                    Text(historicalOutfit.dateWorn, style: .date)
                            .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                    HStack(spacing: 12) {
                Button(action: onToggleFavorite) {
                    Image(systemName: historicalOutfit.isFavorite ? "heart.fill" : "heart")
                                .font(.system(size: 18, weight: .medium))
                        .foregroundColor(historicalOutfit.isFavorite ? .red : AppColors.secondaryText)
                                .frame(width: 40, height: 40)
                        .background(Circle().fill(AppColors.buttonSecondary))
                }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.red)
                                .frame(width: 40, height: 40)
                            .background(Circle().fill(AppColors.buttonSecondary))
                    }
                }
            }
                .padding(20)
                
                Divider()
                    .background(AppColors.cardBorder.opacity(0.5))
                
                // Items de l'outfit
                VStack(spacing: 12) {
                    ForEach(historicalOutfit.outfit.items) { item in
                        ModernHistoricalOutfitItemRow(item: item)
                    }
                }
                .padding(20)
            }
        }
            .alert("Supprimer cet outfit".localized, isPresented: $showingDeleteAlert) {
                Button("Annuler".localized, role: .cancel) { }
                Button("Supprimer".localized, role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("Êtes-vous sûr de vouloir supprimer cet outfit de l'historique ?".localized)
            }
                }
            }

struct ModernHistoricalOutfitItemRow: View {
    let item: WardrobeItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Photo
            Group {
                let photoURL = item.photoURLs.first ?? item.photoURL
                if let photoURL = photoURL, !photoURL.isEmpty,
               let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
            } else {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                    .fill(AppColors.buttonSecondary)
                        .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: item.category.icon)
                                .font(.system(size: 24, weight: .light))
                            .foregroundColor(AppColors.secondaryText)
                    )
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
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

struct ModernEmptyHistoryView: View {
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
                
                Image(systemName: "clock")
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(AppColors.secondaryText)
            }
            .shadow(color: AppColors.shadow.opacity(0.15), radius: 16, x: 0, y: 6)
            
            VStack(spacing: 12) {
                Text("Aucun historique".localized)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(AppColors.primaryText)
                
                Text("Générez vos premiers outfits pour commencer votre historique de tenues".localized)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

#Preview {
    OutfitHistoryScreen()
}
