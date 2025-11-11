//
//  WatchHistoryView.swift
//  ShoplyWatchApp
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct WatchHistoryView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    @State private var historyItems: [WatchOutfitHistoryItem] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                if historyItems.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "clock")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("Aucun historique")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                } else {
                    ForEach(historyItems) { item in
                        HistoryItemCard(item: item)
                    }
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .navigationTitle("Historique")
        .onAppear {
            loadHistory()
        }
    }
    
    private func loadHistory() {
        historyItems = watchDataManager.getOutfitHistory()
    }
}

struct HistoryItemCard: View {
    let item: WatchOutfitHistoryItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(item.date, style: .date)
                    .font(.caption)
                    .fontWeight(.semibold)
                Spacer()
                if item.isFavorite {
                    Image(systemName: "heart.fill")
                        .font(.caption2)
                        .foregroundColor(.red)
                }
            }
            
            if !item.items.isEmpty {
                VStack(alignment: .leading, spacing: 3) {
                    ForEach(item.items.prefix(3), id: \.self) { itemName in
                        HStack(spacing: 4) {
                            Image(systemName: "tshirt.fill")
                                .font(.caption2)
                                .foregroundColor(.blue)
                            Text(itemName)
                                .font(.caption2)
                        }
                    }
                    if item.items.count > 3 {
                        Text("+ \(item.items.count - 3) autres")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(8)
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(8)
    }
}

