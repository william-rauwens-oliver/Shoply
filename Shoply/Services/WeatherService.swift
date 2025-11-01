//
//  WeatherService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import CoreLocation
import Combine

/// Service de météo utilisant WeatherKit ou OpenWeatherMap
class WeatherService: NSObject, ObservableObject {
    static let shared = WeatherService()
    
    @Published var currentWeather: WeatherData?
    @Published var morningWeather: WeatherData?
    @Published var afternoonWeather: WeatherData?
    @Published var cityName: String = ""
    @Published var isLoading = false
    @Published var error: Error?
    
    private let locationManager = CLLocationManager()
    private var location: CLLocation?
    private let geocoder = CLGeocoder()
    
    // Utilisez votre clé API OpenWeatherMap ou WeatherKit
    private let apiKey = "YOUR_API_KEY" // À remplacer
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }
    
    // MARK: - Autorisation de localisation
    
    var hasLocation: Bool {
        return location != nil
    }
    
    func requestLocationPermission() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func startLocationUpdates() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Récupération de la météo
    
    func fetchWeatherForToday() async {
        await MainActor.run {
            isLoading = true
            error = nil
        }
        
        guard let location = location else {
            await MainActor.run {
                isLoading = false
                error = WeatherError.noLocation
            }
            return
        }
        
        do {
            // Si on n'a pas encore le nom de la ville, le récupérer
            if cityName.isEmpty {
                let city = await fetchCityName(from: location)
                await MainActor.run {
                    self.cityName = city
                }
            }
            
            // Récupérer la météo actuelle
            let current = try await fetchCurrentWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
            
            // Récupérer les prévisions pour le matin et l'après-midi
            let forecast = try await fetchForecast(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
            
            await MainActor.run {
                self.currentWeather = current
                self.morningWeather = forecast.morning
                self.afternoonWeather = forecast.afternoon
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.error = error
                self.isLoading = false
            }
        }
    }
    
    // MARK: - API Calls
    
    // Récupérer le nom de la ville
    private func fetchCityName(from location: CLLocation) async -> String {
        // Essayer d'abord avec CLGeocoder (gratuit et fonctionne sans API)
        // C'est la méthode recommandée car elle utilise les services Apple
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let placemark = placemarks.first {
                // Essayer dans l'ordre: locality (ville), subAdministrativeArea, administrativeArea
                if let city = placemark.locality {
                    return city
                } else if let city = placemark.subAdministrativeArea {
                    return city
                } else if let city = placemark.administrativeArea {
                    return city
                } else if let city = placemark.name {
                    return city
                }
            }
        } catch {
            print("⚠️ Erreur geocoding: \(error.localizedDescription)")
        }
        
        // Fallback si le geocoding échoue
        return "Votre position"
    }
    
    private func fetchCurrentWeather(lat: Double, lon: Double) async throws -> WeatherData {
        let urlString = "\(baseURL)/weather?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric&lang=fr"
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenWeatherResponse.self, from: data)
        
        return WeatherData(
            temperature: response.main.temp,
            condition: WeatherCondition.from(code: response.weather.first?.id ?? 0),
            humidity: response.main.humidity,
            windSpeed: response.wind?.speed ?? 0
        )
    }
    
    private func fetchForecast(lat: Double, lon: Double) async throws -> (morning: WeatherData, afternoon: WeatherData) {
        let urlString = "\(baseURL)/forecast?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric&lang=fr"
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenWeatherForecastResponse.self, from: data)
        
        let calendar = Calendar.current
        let now = Date()
        let morning = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: now) ?? now
        let afternoon = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: now) ?? now
        
        // Trouver les prévisions les plus proches du matin et de l'après-midi
        let morningForecast = findClosestForecast(to: morning, in: response.list)
        let afternoonForecast = findClosestForecast(to: afternoon, in: response.list)
        
        return (
            morning: WeatherData(
                temperature: morningForecast.main.temp,
                condition: WeatherCondition.from(code: morningForecast.weather.first?.id ?? 0),
                humidity: morningForecast.main.humidity,
                windSpeed: morningForecast.wind?.speed ?? 0
            ),
            afternoon: WeatherData(
                temperature: afternoonForecast.main.temp,
                condition: WeatherCondition.from(code: afternoonForecast.weather.first?.id ?? 0),
                humidity: afternoonForecast.main.humidity,
                windSpeed: afternoonForecast.wind?.speed ?? 0
            )
        )
    }
    
    private func findClosestForecast(to date: Date, in forecasts: [OpenWeatherForecastItem]) -> OpenWeatherForecastItem {
        return forecasts.min { abs($0.dt - date.timeIntervalSince1970) < abs($1.dt - date.timeIntervalSince1970) } ?? forecasts.first!
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        location = newLocation
        locationManager.stopUpdatingLocation()
        
        // Récupérer le nom de la ville en premier (rapide) puis la météo
        Task {
            // Récupérer la ville en premier pour l'afficher rapidement
            let city = await fetchCityName(from: newLocation)
            await MainActor.run {
                self.cityName = city
            }
            
            // Ensuite récupérer la météo
            await fetchWeatherForToday()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            self.error = error
            self.isLoading = false
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startLocationUpdates()
        case .denied, .restricted:
            Task { @MainActor in
                self.error = WeatherError.noLocation
                self.isLoading = false
            }
        case .notDetermined:
            requestLocationPermission()
        @unknown default:
            break
        }
    }
}

// MARK: - Models

struct WeatherData {
    let temperature: Double
    let condition: WeatherCondition
    let humidity: Int
    let windSpeed: Double
    
    var feelsLikeTemperature: Double {
        // Calcul approximatif du ressenti
        temperature
    }
}

enum WeatherCondition: String, Codable {
    case sunny = "Ensoleillé"
    case cloudy = "Nuageux"
    case rainy = "Pluvieux"
    case snowy = "Neigeux"
    case windy = "Venteux"
    case foggy = "Brouillard"
    case stormy = "Orageux"
    case cold = "Froid"
    case warm = "Chaud"
    
    static func from(code: Int) -> WeatherCondition {
        switch code {
        case 200...232: return .stormy
        case 300...321, 500...531: return .rainy
        case 600...622: return .snowy
        case 701: return .foggy
        case 711: return .foggy
        case 721: return .foggy
        case 731, 741: return .foggy
        case 800: return .sunny
        case 801...804: return .cloudy
        default: return .cloudy
        }
    }
}

enum WeatherError: Error {
    case noLocation
    case invalidURL
    case networkError
    case decodingError
}

// MARK: - OpenWeatherMap API Models

struct OpenWeatherResponse: Codable {
    let main: Main
    let weather: [Weather]
    let wind: Wind?
    let name: String? // Nom de la ville retourné par l'API
}

struct Main: Codable {
    let temp: Double
    let humidity: Int
}

struct Weather: Codable {
    let id: Int
    let main: String
    let description: String
}

struct Wind: Codable {
    let speed: Double
}

struct OpenWeatherForecastResponse: Codable {
    let list: [OpenWeatherForecastItem]
}

struct OpenWeatherForecastItem: Codable {
    let dt: TimeInterval
    let main: Main
    let weather: [Weather]
    let wind: Wind?
}

