//
//  OutfitReviewService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import Combine
import UIKit

/// Service de gestion des avis et notes sur les outfits
class OutfitReviewService: ObservableObject {
    static let shared = OutfitReviewService()
    
    @Published var reviews: [OutfitReview] = []
    
    private init() {
        loadReviews()
    }
    
    // MARK: - Gestion des Avis
    
    func addReview(_ review: OutfitReview) {
        reviews.append(review)
        saveReviews()
        
        // Ajouter XP pour avoir noté un outfit
        GamificationService.shared.addXP(5)
    }
    
    func updateReview(_ review: OutfitReview) {
        if let index = reviews.firstIndex(where: { $0.id == review.id }) {
            reviews[index] = review
            saveReviews()
        }
    }
    
    func deleteReview(_ review: OutfitReview) {
        reviews.removeAll { $0.id == review.id }
        saveReviews()
    }
    
    func getReviewsForOutfit(_ outfitId: UUID) -> [OutfitReview] {
        return reviews.filter { $0.outfitId == outfitId }
    }
    
    func getAverageRatingForOutfit(_ outfitId: UUID) -> Double {
        let outfitReviews = getReviewsForOutfit(outfitId)
        guard !outfitReviews.isEmpty else { return 0.0 }
        
        let totalRating = outfitReviews.reduce(0.0) { $0 + $1.averageRating }
        return totalRating / Double(outfitReviews.count)
    }
    
    func addPhotoToReview(reviewId: UUID, photoData: Data) -> String? {
        // Sauvegarder la photo et retourner l'URL
        let photoURL = savePhoto(photoData: photoData, reviewId: reviewId)
        
        if let index = reviews.firstIndex(where: { $0.id == reviewId }),
           let url = photoURL {
            reviews[index].photos.append(url)
            saveReviews()
            return url
        }
        
        return nil
    }
    
    // MARK: - Photos
    
    private func savePhoto(photoData: Data, reviewId: UUID) -> String? {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let photosPath = documentsPath.appendingPathComponent("OutfitPhotos")
        
        // Créer le dossier s'il n'existe pas
        try? FileManager.default.createDirectory(at: photosPath, withIntermediateDirectories: true)
        
        let fileName = "\(reviewId.uuidString)_\(UUID().uuidString).jpg"
        let fileURL = photosPath.appendingPathComponent(fileName)
        
        do {
            try photoData.write(to: fileURL)
            return fileURL.path
        } catch {
            print("⚠️ Erreur sauvegarde photo: \(error)")
            return nil
        }
    }
    
    // MARK: - Persistance
    
    private func saveReviews() {
        if let encoded = try? JSONEncoder().encode(reviews) {
            UserDefaults.standard.set(encoded, forKey: "outfit_reviews")
        }
    }
    
    private func loadReviews() {
        if let data = UserDefaults.standard.data(forKey: "outfit_reviews"),
           let decoded = try? JSONDecoder().decode([OutfitReview].self, from: data) {
            reviews = decoded
        }
    }
}

