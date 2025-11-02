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
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if historyStore.outfits.isEmpty {
                    EmptyHistoryView()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 14) {
                            ForEach(historyStore.outfits) { historicalOutfit in
                                HistoricalOutfitCard(
                                    historicalOutfit: historicalOutfit,
                                    onToggleFavorite: {
                                        historyStore.toggleFavorite(outfit: historicalOutfit)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
            .navigationTitle("Historique")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct HistoricalOutfitCard: View {
    let historicalOutfit: HistoricalOutfit
    let onToggleFavorite: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header épuré
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(historicalOutfit.outfit.displayName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(historicalOutfit.dateWorn, style: .date)
                        .font(.system(size: 13, weight: .regular))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                Button(action: onToggleFavorite) {
                    Image(systemName: historicalOutfit.isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(historicalOutfit.isFavorite ? .red : AppColors.secondaryText)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(AppColors.buttonSecondary))
                }
            }
            .padding(20)
            
            Divider()
                .background(AppColors.separator.opacity(0.5))
            
            // Items de l'outfit
            VStack(spacing: 14) {
                ForEach(historicalOutfit.outfit.items) { item in
                    HistoricalOutfitItemRow(item: item)
                }
            }
            .padding(20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.cardBackground)
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 0.5)
        }
        .roundedCorner(18)
        .shadow(color: AppColors.shadow.opacity(0.08), radius: 12, x: 0, y: 4)
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
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(AppColors.buttonSecondary)
                    .frame(width: 100, height: 100)
                
                Image(systemName: "clock")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            VStack(spacing: 8) {
                Text("Aucun historique".localized)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.primaryText)
                
                Text("Les outfits que vous portez apparaîtront ici".localized)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 50)
            }
        }
    }
}

#Preview {
    OutfitHistoryScreen()
}
