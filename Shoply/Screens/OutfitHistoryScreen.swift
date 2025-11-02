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
        // Synchroniser avec Apple Watch
        #if !WIDGET_EXTENSION
        dataManager.syncToWatch()
        #endif
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
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(historyStore.outfits) { historicalOutfit in
                                HistoricalOutfitCard(
                                    historicalOutfit: historicalOutfit,
                                    onToggleFavorite: {
                                        historyStore.toggleFavorite(outfit: historicalOutfit)
                                    }
                                )
                            }
                        }
                        .padding()
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
            // Header avec date et favori
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(historicalOutfit.outfit.displayName)
                        .font(.playfairDisplayBold(size: 18))
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(historicalOutfit.dateWorn, style: .date)
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                Button(action: onToggleFavorite) {
                    Image(systemName: historicalOutfit.isFavorite ? "heart.fill" : "heart")
                        .font(.title3)
                        .foregroundColor(historicalOutfit.isFavorite ? .red : AppColors.secondaryText)
                        .padding(8)
                        .background(Circle().fill(AppColors.buttonSecondary))
                }
            }
            .padding()
            
            Divider()
                .background(AppColors.separator)
            
            // Items de l'outfit
            VStack(spacing: 12) {
                ForEach(historicalOutfit.outfit.items) { item in
                    HistoricalOutfitItemRow(item: item)
                }
            }
            .padding()
        }
        .cleanCard(cornerRadius: 16)
    }
}

struct HistoricalOutfitItemRow: View {
    let item: WardrobeItem
    
    var body: some View {
        HStack(spacing: 12) {
            // Photo
            if let photoURL = item.photoURL,
               let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(AppColors.buttonSecondary)
                    .frame(width: 60, height: 60)
                    .overlay(
                        Image(systemName: item.category.icon)
                            .foregroundColor(AppColors.secondaryText)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                
                Text(item.category.rawValue)
                    .font(.system(size: 13))
                    .foregroundColor(AppColors.secondaryText)
            }
            
            Spacer()
        }
    }
}

struct EmptyHistoryView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "clock")
                .font(.system(size: 60))
                .foregroundColor(AppColors.tertiaryText)
            
            Text("Aucun historique")
                .font(.playfairDisplayBold(size: 24))
                .foregroundColor(AppColors.primaryText)
            
            Text("Les outfits que vous portez apparaîtront ici")
                .font(.system(size: 16))
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
    }
}

#Preview {
    OutfitHistoryScreen()
}
