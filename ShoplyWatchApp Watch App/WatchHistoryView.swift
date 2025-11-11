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
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Historique")
                    .font(.headline)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            
            // Liste
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
        }
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
            if !item.items.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    ForEach(item.items.prefix(3), id: \.self) { itemName in
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                            Text(itemName)
                                .font(.caption)
                                .fontWeight(.medium)
                        }
                    }
                    if item.items.count > 3 {
                        Text("+ \(item.items.count - 3) autres")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.leading, 18)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color.gray.opacity(0.15), Color.gray.opacity(0.08)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(10)
    }
}

