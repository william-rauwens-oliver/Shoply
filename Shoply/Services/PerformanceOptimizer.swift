//
//  PerformanceOptimizer.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import UIKit
import Combine

/// Service d'optimisation des performances (batterie, RAM, CPU)
class PerformanceOptimizer {
    static let shared = PerformanceOptimizer()
    
    private var cancellables = Set<AnyCancellable>()
    private var imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.countLimit = 50 // Limiter à 50 images en cache
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB max
        return cache
    }()
    
    private init() {
        setupOptimizations()
    }
    
    private func setupOptimizations() {
        // Réduire la fréquence de rafraîchissement
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                self?.clearCaches()
            }
            .store(in: &cancellables)
        
        // Optimiser la mémoire quand l'app devient inactive
        NotificationCenter.default.publisher(for: UIApplication.willResignActiveNotification)
            .sink { [weak self] _ in
                self?.optimizeMemory()
            }
            .store(in: &cancellables)
    }
    
    /// Cache une image pour éviter de la recharger
    func cacheImage(_ image: UIImage, forKey key: String) {
        imageCache.setObject(image, forKey: key as NSString)
    }
    
    /// Récupère une image du cache
    func getCachedImage(forKey key: String) -> UIImage? {
        return imageCache.object(forKey: key as NSString)
    }
    
    /// Nettoie les caches pour libérer de la mémoire
    func clearCaches() {
        imageCache.removeAllObjects()
        URLCache.shared.removeAllCachedResponses()
    }
    
    /// Optimise l'utilisation mémoire
    func optimizeMemory() {
        // Forcer le garbage collection
        autoreleasepool {
            clearCaches()
        }
    }
    
    /// Débounce pour éviter trop d'appels API
    func debounce<T>(_ value: T, delay: TimeInterval = 0.5, action: @escaping (T) -> Void) {
        // Utiliser un timer pour débouncer
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            action(value)
        }
    }
    
    /// Limite le nombre de requêtes simultanées
    private let requestQueue = DispatchQueue(label: "com.shoply.requests", attributes: .concurrent)
    private let semaphore = DispatchSemaphore(value: 3) // Max 3 requêtes simultanées
    
    func performRequest<T>(_ operation: @escaping () async throws -> T) async throws -> T {
        return try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<T, Error>) in
            requestQueue.async {
                self.semaphore.wait()
                Task {
                    defer { self.semaphore.signal() }
                    do {
                        let result = try await operation()
                        continuation.resume(returning: result)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
}

