//
//  WeatherService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import CoreLocation
import Combine
#if canImport(WidgetKit)
import WidgetKit
#endif

/// Service de météo utilisant WeatherKit ou OpenWeatherMap
class WeatherService: NSObject, ObservableObject {
    static let shared = WeatherService()
    
    @Published var currentWeather: WeatherData?
    @Published var morningWeather: WeatherData?
    @Published var afternoonWeather: WeatherData?
    @Published var cityName: String = ""
    @Published var isLoading = false
    @Published var error: Error?
    @Published var weatherFetchedSuccessfully: Bool = false
    @Published var weatherStatusMessage: String = ""
    
    private let locationManager = CLLocationManager()
    private(set) var location: CLLocation? // Rendre accessible en lecture seule
    private var locationRequestCompletion: ((Bool) -> Void)?
    private let geocoder = CLGeocoder()
    
    // Utilisez votre clé API OpenWeatherMap ou WeatherKit
    // Si pas de clé, on utilisera des données météo simulées basées sur la saison
    private let apiKey: String? = nil // Mettez votre clé ici si vous en avez une
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    private let useSimulatedWeather: Bool = true // Fallback si pas d'API
    
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
    
    func startLocationUpdates() async -> Bool {
        // Attendre que la localisation soit obtenue
        return await withCheckedContinuation { continuation in
            locationRequestCompletion = { success in
                continuation.resume(returning: success)
            }
            
            switch locationManager.authorizationStatus {
            case .authorizedWhenInUse, .authorizedAlways:
                locationManager.startUpdatingLocation()
            case .notDetermined:
                requestLocationPermission()
            case .denied, .restricted:
                locationRequestCompletion?(false)
            @unknown default:
                locationRequestCompletion?(false)
            }
        }
    }
    
    func startLocationUpdatesSync() {
        guard locationManager.authorizationStatus == .authorizedWhenInUse ||
              locationManager.authorizationStatus == .authorizedAlways else {
            requestLocationPermission()
            return
        }
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - Récupération de la météo
    
    func fetchWeatherForDate(_ targetDate: Date = Date()) async {
        await MainActor.run {
            isLoading = true
            error = nil
            weatherFetchedSuccessfully = false
            weatherStatusMessage = "Récupération de votre localisation..."
        }
        
        // Attendre que la localisation soit obtenue
        if location == nil {
            let locationObtained = await startLocationUpdates()
            if !locationObtained {
                // Attendre un peu pour que la localisation soit mise à jour
                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 secondes
            }
        }
        
        guard let location = location else {
            await MainActor.run {
                isLoading = false
                error = WeatherError.noLocation
                weatherStatusMessage = "Localisation non disponible"
            }
            return
        }
        
        await MainActor.run {
            weatherStatusMessage = "Récupération de la météo..."
        }
        
        do {
            // Si on n'a pas encore le nom de la ville, le récupérer
            if cityName.isEmpty {
                let city = await fetchCityName(from: location)
                await MainActor.run {
                    self.cityName = city
                    self.weatherStatusMessage = "Météo récupérée pour \(city)"
                }
            }
            
            var current: WeatherData
            var forecast: (morning: WeatherData, afternoon: WeatherData)
            
            // Essayer avec l'API si disponible, sinon utiliser des données simulées
            if let apiKey = apiKey, !apiKey.isEmpty, !useSimulatedWeather {
                // Pour aujourd'hui, récupérer la météo actuelle, sinon utiliser les prévisions
                if Calendar.current.isDateInToday(targetDate) {
                    current = try await fetchCurrentWeather(lat: location.coordinate.latitude, lon: location.coordinate.longitude)
                } else {
                    // Pour les dates futures, utiliser les prévisions
                    let forecastData = try await fetchForecast(lat: location.coordinate.latitude, lon: location.coordinate.longitude, for: targetDate)
                    current = forecastData.morning // Utiliser les données du matin comme météo actuelle
                }
            
                // Récupérer les prévisions pour le matin et l'après-midi de la date cible
                forecast = try await fetchForecast(lat: location.coordinate.latitude, lon: location.coordinate.longitude, for: targetDate)
            } else {
                // Utiliser des données météo simulées basées sur la saison et la localisation
                (current, forecast) = await generateSimulatedWeather(for: location, date: targetDate)
            }
            
            await MainActor.run {
                self.currentWeather = current
                self.morningWeather = forecast.morning
                self.afternoonWeather = forecast.afternoon
                self.isLoading = false
                self.weatherFetchedSuccessfully = true
                
                // Sauvegarder pour les widgets
                UserDefaults.standard.set(current.temperature, forKey: "widget_weather_temp")
                UserDefaults.standard.set(current.condition.rawValue, forKey: "widget_weather_condition")
                
                // Demander la mise à jour des widgets
                #if canImport(WidgetKit)
                WidgetCenter.shared.reloadTimelines(ofKind: "ShoplyWidget")
                #endif
                
                if cityName.isEmpty {
                    self.weatherStatusMessage = "Météo récupérée avec succès"
                } else {
                    self.weatherStatusMessage = "Météo récupérée pour \(cityName)"
                }
            }
        } catch {
            // En cas d'erreur API, utiliser des données simulées
            let (current, forecast) = await generateSimulatedWeather(for: location, date: targetDate)
            
            await MainActor.run {
                self.currentWeather = current
                self.morningWeather = forecast.morning
                self.afternoonWeather = forecast.afternoon
                self.isLoading = false
                self.weatherFetchedSuccessfully = true
                
                // Sauvegarder pour les widgets
                UserDefaults.standard.set(current.temperature, forKey: "widget_weather_temp")
                UserDefaults.standard.set(current.condition.rawValue, forKey: "widget_weather_condition")
                
                // Demander la mise à jour des widgets
                #if canImport(WidgetKit)
                WidgetCenter.shared.reloadTimelines(ofKind: "ShoplyWidget")
                #endif
                
                if cityName.isEmpty {
                    self.weatherStatusMessage = "Météo estimée récupérée"
                } else {
                    self.weatherStatusMessage = "Météo estimée pour \(cityName)"
                }
            }
        }
    }
    
    // Alias pour compatibilité avec le code existant
    func fetchWeatherForToday() async {
        await fetchWeatherForDate(Date())
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
            
        }
        
        // Fallback si le geocoding échoue
        return "Votre position"
    }
    
    private func fetchCurrentWeather(lat: Double, lon: Double) async throws -> WeatherData {
        guard let apiKey = apiKey else {
            throw WeatherError.apiKeyMissing
        }
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
    
    private func fetchForecast(lat: Double, lon: Double, for targetDate: Date = Date()) async throws -> (morning: WeatherData, afternoon: WeatherData) {
        guard let apiKey = apiKey else {
            throw WeatherError.apiKeyMissing
        }
        let urlString = "\(baseURL)/forecast?lat=\(lat)&lon=\(lon)&appid=\(apiKey)&units=metric&lang=fr"
        guard let url = URL(string: urlString) else {
            throw WeatherError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(OpenWeatherForecastResponse.self, from: data)
        
        let calendar = Calendar.current
        // Utiliser la date cible au lieu de "maintenant"
        let morning = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: targetDate) ?? targetDate
        let afternoon = calendar.date(bySettingHour: 15, minute: 0, second: 0, of: targetDate) ?? targetDate
        
        // Trouver les prévisions les plus proches du matin et de l'après-midi de la date cible
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
    
    // MARK: - Météo simulée (fallback)
    
    private func generateSimulatedWeather(for location: CLLocation, date: Date = Date()) async -> (current: WeatherData, forecast: (morning: WeatherData, afternoon: WeatherData)) {
        // Générer des données météo réalistes basées sur la saison et la latitude
        let calendar = Calendar.current
        let month = calendar.component(.month, from: date)
        let day = calendar.component(.day, from: date)
        let latitude = location.coordinate.latitude
        
        // Ajouter de la variabilité basée sur le jour pour que chaque jour soit différent
        let dayVariation = Double(day % 7) * 2.0 // Variation de ±6°C selon le jour
        let randomVariation = Double.random(in: -3...3) // Variation aléatoire supplémentaire
        
        // Déterminer la saison
        let seasonType: Season
        switch month {
        case 12, 1, 2: seasonType = .winter
        case 3, 4, 5: seasonType = .spring
        case 6, 7, 8: seasonType = .summer
        default: seasonType = .autumn
        }
        
        // Températures approximatives basées sur la latitude et la saison
        var baseTemp: Double = 20.0
        if abs(latitude) < 30 { // Tropiques
            baseTemp = seasonType == .winter ? 25.0 : 28.0
        } else if abs(latitude) < 45 { // Zones tempérées
            switch seasonType {
            case .winter: baseTemp = 5.0
            case .spring: baseTemp = 15.0
            case .summer: baseTemp = 25.0
            case .autumn: baseTemp = 12.0
            case .allSeason: baseTemp = 18.0
            }
        } else { // Zones froides
            baseTemp = seasonType == .winter ? -5.0 : 10.0
        }
        
        let morningTemp = baseTemp - 3.0 + dayVariation + randomVariation
        let afternoonTemp = baseTemp + 2.0 + dayVariation + randomVariation
        
        // Conditions météo basées sur la saison et le jour pour avoir une variabilité
        // Utiliser le jour comme seed pour avoir une variation cohérente mais différente chaque jour
        let daySeed = day + Int(date.timeIntervalSince1970 / 86400) // Unique pour chaque jour
        let conditions: [WeatherCondition] = seasonType == .winter ? [.cloudy, .cold, .snowy] : [.sunny, .cloudy, .rainy, .windy]
        
        // Sélectionner les conditions en fonction du seed pour avoir des résultats reproductibles mais variés
        let morningIndex = abs(daySeed) % conditions.count
        let afternoonIndex = abs(daySeed * 2) % conditions.count
        let morningCondition = conditions[morningIndex]
        let afternoonCondition = conditions[afternoonIndex]
        
        let current = WeatherData(
            temperature: (morningTemp + afternoonTemp) / 2,
            condition: morningCondition,
            humidity: 60,
            windSpeed: 10.0
        )
        
        let forecast = (
            morning: WeatherData(
                temperature: morningTemp,
                condition: morningCondition,
                humidity: 65,
                windSpeed: 8.0
            ),
            afternoon: WeatherData(
                temperature: afternoonTemp,
                condition: afternoonCondition,
                humidity: 55,
                windSpeed: 12.0
            )
        )
        
        return (current, forecast)
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }
        location = newLocation
        locationManager.stopUpdatingLocation()
        
        // Notifier que la localisation a été obtenue
        locationRequestCompletion?(true)
        
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
        locationRequestCompletion?(false)
        Task { @MainActor in
            self.error = error
            self.isLoading = false
        }
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            locationManager.startUpdatingLocation()
        case .denied, .restricted:
            locationRequestCompletion?(false)
            Task { @MainActor in
                self.error = WeatherError.noLocation
                self.isLoading = false
            }
        case .notDetermined:
            requestLocationPermission()
        @unknown default:
            locationRequestCompletion?(false)
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
    case apiKeyMissing
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

