//
//  PhotoManager.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import UIKit
import SwiftUI

/// Gestionnaire de photos pour la garde-robe
class PhotoManager {
    static let shared = PhotoManager()
    
    private let documentsURL: URL
    
    private init() {
        documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("WardrobePhotos")
        
        // Créer le dossier s'il n'existe pas
        try? FileManager.default.createDirectory(at: documentsURL, withIntermediateDirectories: true)
    }
    
    // MARK: - Sauvegarde de photos
    
    func savePhoto(_ image: UIImage, itemId: UUID) async throws -> String {
        // Redimensionner l'image pour économiser de l'espace
        let resizedImage = image.resized(to: CGSize(width: 800, height: 800))
        
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.7) else {
            throw PhotoError.cannotConvertToData
        }
        
        let filename = "\(itemId.uuidString).jpg"
        let fileURL = documentsURL.appendingPathComponent(filename)
        
        try imageData.write(to: fileURL)
        
        return fileURL.path
    }
    
    // MARK: - Chargement de photos
    
    func loadPhoto(at path: String) -> UIImage? {
        let url = URL(fileURLWithPath: path)
        guard let imageData = try? Data(contentsOf: url) else {
            return nil
        }
        return UIImage(data: imageData)
    }
    
    // MARK: - Suppression de photos
    
    func deletePhoto(at path: String) {
        let url = URL(fileURLWithPath: path)
        try? FileManager.default.removeItem(at: url)
    }
    
    // MARK: - Export pour iCloud
    
    func exportPhotosForiCloud() -> [URL] {
        var urls: [URL] = []
        if let files = try? FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil) {
            urls = files.filter { $0.pathExtension == "jpg" || $0.pathExtension == "png" }
        }
        return urls
    }
}

enum PhotoError: Error {
    case cannotConvertToData
    case cannotSaveFile
}

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}

