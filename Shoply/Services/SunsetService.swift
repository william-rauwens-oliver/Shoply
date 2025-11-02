//
//  SunsetService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import CoreLocation
import UIKit

/// Service pour calculer l'heure du coucher de soleil basé sur la localisation
class SunsetService {
    static let shared = SunsetService()
    
    private init() {}
    
    /// Calcule l'heure du coucher de soleil pour une date et une localisation données
    func calculateSunset(latitude: Double, longitude: Double, date: Date = Date()) -> Date? {
        // Formule simplifiée pour le coucher de soleil
        // Utilise l'équation du temps et la déclinaison solaire
        
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        
        // Déclinaison solaire (en degrés)
        let dayOfYearDouble = Double(dayOfYear)
        let declination = 23.45 * sin((360.0 * (284.0 + dayOfYearDouble) / 365.0) * .pi / 180.0)
        
        // Équation du temps (en minutes)
        let B = (360.0 * (dayOfYearDouble - 81.0) / 365.0) * .pi / 180.0
        let equationOfTime = 9.87 * sin(2.0 * B) - 7.53 * cos(B) - 1.5 * sin(B)
        
        // Angle horaire (en degrés)
        let latRad = latitude * .pi / 180.0
        let decRad = declination * .pi / 180.0
        let hourAngle = acos(-tan(latRad) * tan(decRad)) * 180.0 / .pi
        
        // Heure solaire du coucher (en heures décimales)
        let longitudeOffset = longitude * 4.0 / 60.0 // Conversion degrés -> minutes -> heures
        let solarNoon = 12.0 + longitudeOffset - (equationOfTime / 60.0)
        let sunsetHour = solarNoon + (hourAngle / 15.0)
        
        // Convertir en Date
        let hour = Int(sunsetHour)
        let minute = Int((sunsetHour - Double(hour)) * 60.0)
        
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        return calendar.date(from: components)
    }
    
    /// Calcule l'heure du lever de soleil pour une date et une localisation données
    func calculateSunrise(latitude: Double, longitude: Double, date: Date = Date()) -> Date? {
        // Formule simplifiée pour le lever de soleil
        // Similaire au coucher mais avec l'angle horaire négatif
        
        let calendar = Calendar.current
        let dayOfYear = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        
        // Déclinaison solaire (en degrés)
        let dayOfYearDouble = Double(dayOfYear)
        let declination = 23.45 * sin((360.0 * (284.0 + dayOfYearDouble) / 365.0) * .pi / 180.0)
        
        // Équation du temps (en minutes)
        let B = (360.0 * (dayOfYearDouble - 81.0) / 365.0) * .pi / 180.0
        let equationOfTime = 9.87 * sin(2.0 * B) - 7.53 * cos(B) - 1.5 * sin(B)
        
        // Angle horaire (en degrés) - négatif pour le lever
        let latRad = latitude * .pi / 180.0
        let decRad = declination * .pi / 180.0
        let hourAngle = acos(-tan(latRad) * tan(decRad)) * 180.0 / .pi
        
        // Heure solaire du lever (en heures décimales)
        let longitudeOffset = longitude * 4.0 / 60.0 // Conversion degrés -> minutes -> heures
        let solarNoon = 12.0 + longitudeOffset - (equationOfTime / 60.0)
        let sunriseHour = solarNoon - (hourAngle / 15.0)
        
        // Convertir en Date
        let hour = Int(sunriseHour)
        let minute = Int((sunriseHour - Double(hour)) * 60.0)
        
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = hour
        components.minute = minute
        components.second = 0
        
        return calendar.date(from: components)
    }
    
    /// Détermine si c'est le jour ou la nuit basé sur le coucher et lever de soleil
    func isDaytime(latitude: Double, longitude: Double, currentTime: Date = Date()) -> Bool {
        // Protection contre les valeurs invalides
        guard !latitude.isNaN && !longitude.isNaN && !latitude.isInfinite && !longitude.isInfinite else {
            let hour = Calendar.current.component(.hour, from: currentTime)
            return hour >= 6 && hour < 20
        }
        
        guard let sunrise = calculateSunrise(latitude: latitude, longitude: longitude, date: currentTime),
              let sunset = calculateSunset(latitude: latitude, longitude: longitude, date: currentTime) else {
            // Fallback: utiliser l'heure pour déterminer jour/nuit
            let hour = Calendar.current.component(.hour, from: currentTime)
            return hour >= 6 && hour < 20
        }
        
        // Si l'heure actuelle est entre le lever et le coucher de soleil, c'est le jour
        return currentTime >= sunrise && currentTime < sunset
    }
    
    /// Retourne la salutation appropriée (Bonjour/Bonsoir) basée sur le lever/coucher du soleil
    func getGreeting(latitude: Double, longitude: Double, currentTime: Date = Date()) -> String {
        // Protection contre les valeurs invalides
        guard !latitude.isNaN && !longitude.isNaN && !latitude.isInfinite && !longitude.isInfinite else {
            let hour = Calendar.current.component(.hour, from: currentTime)
            return (hour >= 5 && hour < 18) ? "Bonjour" : "Bonsoir"
        }
        
        if isDaytime(latitude: latitude, longitude: longitude, currentTime: currentTime) {
            return "Bonjour"
        } else {
            return "Bonsoir"
        }
    }
}

