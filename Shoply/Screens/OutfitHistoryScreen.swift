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
        outfits.insert(historical, at: 0) // Ajouter au début
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
            
            // Synchroniser avec le système de favoris
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
        // Synchroniser les favoris
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

/// Écran d'historique des outfits portés
struct OutfitHistoryScreen: View {
    @StateObject private var historyStore = OutfitHistoryStore()
    @State private var showingDeleteAllAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond opaque simple
                AppColors.background
                    .ignoresSafeArea()
                
                if historyStore.outfits.isEmpty {
                    EmptyHistoryView()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 20) {
                            ForEach(historyStore.outfits) { historicalOutfit in
                                HistoricalOutfitCard(
                                    historicalOutfit: historicalOutfit,
                                    onToggleFavorite: {
                                        historyStore.toggleFavorite(outfit: historicalOutfit)
                                    },
                                    onDelete: {
                                        if let index = historyStore.outfits.firstIndex(where: { $0.id == historicalOutfit.id }) {
                                            historyStore.removeOutfit(at: index)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 24)
                    }
                }
            }
            .navigationTitle("Historique")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !historyStore.outfits.isEmpty {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingDeleteAllAlert = true
                        }) {
                            Image(systemName: "trash")
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

struct HistoricalOutfitCard: View {
    let historicalOutfit: HistoricalOutfit
    let onToggleFavorite: () -> Void
    let onDelete: () -> Void
    @State private var showingDeleteAlert = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header épuré
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(historicalOutfit.outfit.displayName)
                        .font(.playfairDisplayBold(size: 20))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(historicalOutfit.dateWorn, style: .date)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                Button(action: onToggleFavorite) {
                    Image(systemName: historicalOutfit.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(historicalOutfit.isFavorite ? .red : AppColors.secondaryText)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(AppColors.buttonSecondary))
                }
                    
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.red)
                            .frame(width: 36, height: 36)
                            .background(Circle().fill(AppColors.buttonSecondary))
                    }
                }
            }
            .padding(24)
            .alert("Supprimer cet outfit".localized, isPresented: $showingDeleteAlert) {
                Button("Annuler".localized, role: .cancel) { }
                Button("Supprimer".localized, role: .destructive) {
                    onDelete()
                }
            } message: {
                Text("Êtes-vous sûr de vouloir supprimer cet outfit de l'historique ?".localized)
            }
            
            Rectangle()
                .fill(AppColors.separator.opacity(0.6))
                .frame(height: 0.5)
                .padding(.horizontal, 24)
            
            // Items de l'outfit
            VStack(spacing: 16) {
                ForEach(historicalOutfit.outfit.items) { item in
                    HistoricalOutfitItemRow(item: item)
                }
            }
            .padding(24)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 22)
                .fill(Material.regularMaterial)
        .overlay {
                    RoundedRectangle(cornerRadius: 22)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    AppColors.cardBorder.opacity(0.4),
                                    AppColors.cardBorder.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
        }
        )
        .roundedCorner(22)
        .shadow(color: AppColors.shadow.opacity(0.2), radius: 14, x: 0, y: 6)
    }
}

struct HistoricalOutfitItemRow: View {
    let item: WardrobeItem
    
    var body: some View {
        HStack(spacing: 14) {
            // Photo
            if let photoURL = item.photoURL,
               let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppColors.buttonSecondary)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: item.category.icon)
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.secondaryText)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                
                Text(item.category.rawValue)
                    .font(.system(size: 13, weight: .regular))
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
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppColors.cardBorder.opacity(0.3),
                                        AppColors.cardBorder.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                
                Image(systemName: "clock")
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(AppColors.secondaryText)
            }
            .shadow(color: AppColors.shadow.opacity(0.15), radius: 12, x: 0, y: 4)
            
            VStack(spacing: 16) {
                Text("Aucun historique".localized)
                    .font(.playfairDisplayBold(size: 30))
                    .foregroundColor(AppColors.primaryText)
                
                Text("Générez vos premiers outfits pour commencer votre historique de tenues".localized)
                    .font(.system(size: 17, weight: .regular))
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .lineLimit(3)
            }
        }
    }
}

#Preview {
    OutfitHistoryScreen()
}
