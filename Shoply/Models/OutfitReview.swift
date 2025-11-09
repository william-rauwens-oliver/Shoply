//
//  OutfitReview.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import UIKit

/// Avis et notes sur un outfit porté
struct OutfitReview: Codable, Identifiable {
    let id: UUID
    let outfitId: UUID
    var rating: Int // 1-5
    var comfortRating: Int // 1-5
    var styleRating: Int // 1-5
    var notes: String?
    var photos: [String] // URLs des photos de l'outfit porté
    var wornDate: Date
    var weather: String?
    var occasion: String?
    var receivedCompliments: Int
    var createdAt: Date
    
    init(id: UUID = UUID(), outfitId: UUID, rating: Int, comfortRating: Int, styleRating: Int, notes: String? = nil, photos: [String] = [], wornDate: Date = Date(), weather: String? = nil, occasion: String? = nil, receivedCompliments: Int = 0, createdAt: Date = Date()) {
        self.id = id
        self.outfitId = outfitId
        self.rating = rating
        self.comfortRating = comfortRating
        self.styleRating = styleRating
        self.notes = notes
        self.photos = photos
        self.wornDate = wornDate
        self.weather = weather
        self.occasion = occasion
        self.receivedCompliments = receivedCompliments
        self.createdAt = createdAt
    }
    
    var averageRating: Double {
        return Double(rating + comfortRating + styleRating) / 3.0
    }
}

