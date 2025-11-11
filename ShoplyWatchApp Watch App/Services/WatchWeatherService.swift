//
//  WatchWeatherService.swift
//  ShoplyWatchApp
//
//  Created by William on 01/11/2025.
//

import Foundation
import Combine
import CoreLocation

class WatchWeatherService: NSObject, ObservableObject {
    static let shared = WatchWeatherService()
    
    @Published var currentWeather: WatchWeather?
    @Published var isLoading = false
    
    private let locationManager = CLLocationManager()
    private var lastUpdate: Date?
    private let cacheDuration: TimeInterval = 300 // 5 minutes
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    // MARK: - Fetch Weather
    func fetchCurrentWeather() {
        // Vérifier le cache
        if let lastUpdate = lastUpdate,
           Date().timeIntervalSince(lastUpdate) < cacheDuration,
           currentWeather != nil {
            return
        }
        
        isLoading = true
        
        // Demander la localisation
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
    }
    
    private func fetchWeatherForLocation(_ location: CLLocation) {
        // Utiliser l'API météo (simplifié pour la Watch)
        // En production, utiliser la même API que l'app iOS
        
        Task {
            // Simulation d'une API météo
            // En production, remplacer par un vrai appel API
            let weather = await simulateWeatherAPI(location: location)
            
            await MainActor.run {
                self.currentWeather = weather
                self.isLoading = false
                self.lastUpdate = Date()
            }
        }
    }
    
    private func simulateWeatherAPI(location: CLLocation) async -> WatchWeather {
        // Simulation - en production, utiliser une vraie API météo
        // Par exemple OpenWeatherMap, WeatherKit, etc.
        
        // Pour l'instant, retourner des données simulées
        let temperature = Double.random(in: 5...30)
        let conditions = ["Ensoleillé", "Nuageux", "Pluvieux", "Partiellement nuageux"].randomElement() ?? "Ensoleillé"
        
        return WatchWeather(
            temperature: temperature,
            condition: conditions,
            humidity: Double.random(in: 40...80),
            windSpeed: Double.random(in: 5...25),
            location: "Position actuelle"
        )
    }
    
    // MARK: - Get Weather from iOS App
    func syncWeatherFromiOS() {
        // Synchroniser la météo depuis l'app iOS via App Groups
        guard let sharedDefaults = UserDefaults(suiteName: "group.com.william.shoply"),
              let data = sharedDefaults.data(forKey: "current_weather"),
              let weather = try? JSONDecoder().decode(WatchWeather.self, from: data) else {
            // Si pas de données, essayer de récupérer directement
            fetchCurrentWeather()
            return
        }
        
        currentWeather = weather
        lastUpdate = Date()
    }
}

// MARK: - CLLocationManagerDelegate
extension WatchWeatherService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        fetchWeatherForLocation(location)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Erreur de localisation: \(error.localizedDescription)")
        isLoading = false
        
        // Essayer de synchroniser depuis l'app iOS
        syncWeatherFromiOS()
    }
}

