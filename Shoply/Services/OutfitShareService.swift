//
//  OutfitShareService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import Combine

/// Service pour exporter et importer des outfits en JSON
class OutfitShareService: ObservableObject {
    static let shared = OutfitShareService()
    
    private init() {}
    
    /// Exporte les outfits portés en JSON
    func exportOutfitsToJSON(outfits: [HistoricalOutfit]) throws -> Data {
        let exportData = OutfitExportData(
            version: "1.0",
            exportDate: Date(),
            outfits: outfits.map { historicalOutfit in
                ExportedOutfit(
                    id: historicalOutfit.id,
                    outfit: historicalOutfit.outfit,
                    dateWorn: historicalOutfit.dateWorn,
                    isFavorite: historicalOutfit.isFavorite
                )
            }
        )
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        
        return try encoder.encode(exportData)
    }
    
    /// Importe des outfits depuis un JSON
    func importOutfitsFromJSON(data: Data) throws -> [HistoricalOutfit] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let exportData = try decoder.decode(OutfitExportData.self, from: data)
        
        return exportData.outfits.map { exportedOutfit in
            HistoricalOutfit(
                id: exportedOutfit.id,
                outfit: exportedOutfit.outfit,
                dateWorn: exportedOutfit.dateWorn,
                isFavorite: exportedOutfit.isFavorite
            )
        }
    }
    
    /// Sauvegarde les outfits partagés reçus
    func saveReceivedOutfits(_ outfits: [HistoricalOutfit]) {
        let key = "receivedSharedOutfits"
        if let encoded = try? JSONEncoder().encode(outfits) {
            UserDefaults.standard.set(encoded, forKey: key)
        }
    }
    
    /// Charge les outfits partagés reçus
    func loadReceivedOutfits() -> [HistoricalOutfit] {
        let key = "receivedSharedOutfits"
        guard let data = UserDefaults.standard.data(forKey: key),
              let decoded = try? JSONDecoder().decode([HistoricalOutfit].self, from: data) else {
            return []
        }
        return decoded
    }
}

struct OutfitExportData: Codable {
    let version: String
    let exportDate: Date
    let outfits: [ExportedOutfit]
}

struct ExportedOutfit: Codable {
    let id: UUID
    let outfit: MatchedOutfit
    let dateWorn: Date
    let isFavorite: Bool
}

