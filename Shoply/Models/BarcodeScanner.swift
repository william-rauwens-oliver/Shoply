//
//  BarcodeScanner.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import AVFoundation

/// Modèle pour le scanner de codes-barres
struct ScannedProduct: Codable, Identifiable {
    let id: UUID
    let barcode: String
    var name: String?
    var brand: String?
    var price: Double?
    var currency: String
    var category: ClothingCategory?
    var imageURL: String?
    var storeURL: String?
    var scannedAt: Date
    
    init(id: UUID = UUID(), barcode: String, name: String? = nil, brand: String? = nil, price: Double? = nil, currency: String = "EUR", category: ClothingCategory? = nil, imageURL: String? = nil, storeURL: String? = nil, scannedAt: Date = Date()) {
        self.id = id
        self.barcode = barcode
        self.name = name
        self.brand = brand
        self.price = price
        self.currency = currency
        self.category = category
        self.imageURL = imageURL
        self.storeURL = storeURL
        self.scannedAt = scannedAt
    }
}

