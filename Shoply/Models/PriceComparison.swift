//
//  PriceComparison.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation

/// Comparaison de prix entre différents magasins
struct PriceComparison: Codable, Identifiable {
    let id: UUID
    let itemName: String
    let category: ClothingCategory
    var prices: [StorePrice]
    var bestPrice: StorePrice? {
        prices.min(by: { $0.price < $1.price })
    }
    var averagePrice: Double {
        guard !prices.isEmpty else { return 0 }
        return prices.reduce(0) { $0 + $1.price } / Double(prices.count)
    }
    var priceRange: (min: Double, max: Double) {
        guard !prices.isEmpty else { return (0, 0) }
        let sorted = prices.sorted { $0.price < $1.price }
        return (sorted.first!.price, sorted.last!.price)
    }
    
    init(id: UUID = UUID(), itemName: String, category: ClothingCategory, prices: [StorePrice] = []) {
        self.id = id
        self.itemName = itemName
        self.category = category
        self.prices = prices
    }
}

struct StorePrice: Codable, Identifiable {
    let id: UUID
    let storeName: String
    let price: Double
    let currency: String
    let storeURL: String?
    let availability: Availability
    let lastUpdated: Date
    
    enum Availability: String, Codable {
        case inStock = "En stock"
        case outOfStock = "Rupture de stock"
        case limited = "Stock limité"
        case preOrder = "Précommande"
    }
    
    init(id: UUID = UUID(), storeName: String, price: Double, currency: String = "EUR", storeURL: String? = nil, availability: Availability = .inStock, lastUpdated: Date = Date()) {
        self.id = id
        self.storeName = storeName
        self.price = price
        self.currency = currency
        self.storeURL = storeURL
        self.availability = availability
        self.lastUpdated = lastUpdated
    }
}

