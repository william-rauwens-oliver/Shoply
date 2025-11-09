//
//  UserProfile.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import SwiftUI

/// Profil utilisateur
struct UserProfile: Codable {
    var firstName: String
    var dateOfBirth: Date?
    var age: Int { // Propriété calculée pour compatibilité
        guard let dateOfBirth = dateOfBirth else { return 0 }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: dateOfBirth, to: Date())
        return ageComponents.year ?? 0
    }
    var gender: Gender
    var email: String?
    var profilePhotoData: Data? // Photo de profil encodée en Data
    var createdAt: Date
    var lastWeatherUpdate: Date?
    var preferences: UserPreferences
    
    var profilePhoto: UIImage? {
        get {
            guard let data = profilePhotoData else { return nil }
            return UIImage(data: data)
        }
        set {
            profilePhotoData = newValue?.jpegData(compressionQuality: 0.8)
        }
    }
    
    init(firstName: String = "", dateOfBirth: Date? = nil, age: Int = 0, gender: Gender = .notSpecified, email: String? = nil, profilePhotoData: Data? = nil, createdAt: Date = Date(), preferences: UserPreferences = UserPreferences()) {
        self.firstName = firstName
        // Si dateOfBirth n'est pas fournie mais age l'est (ancienne version), calculer dateOfBirth approximative
        if let dob = dateOfBirth {
            self.dateOfBirth = dob
        } else if age > 0 {
            // Calculer une date de naissance approximative (au 1er janvier de l'année)
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: Date())
            var components = DateComponents()
            components.year = currentYear - age
            components.month = 1
            components.day = 1
            self.dateOfBirth = calendar.date(from: components)
        } else {
            self.dateOfBirth = nil
        }
        self.gender = gender
        self.email = email
        self.profilePhotoData = profilePhotoData
        self.createdAt = createdAt
        self.preferences = preferences
    }
    
    enum CodingKeys: String, CodingKey {
        case firstName
        case dateOfBirth
        case gender
        case email
        case profilePhotoData
        case createdAt
        case lastWeatherUpdate
        case preferences
        // Support ancienne version avec age
        case age
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        firstName = try container.decode(String.self, forKey: .firstName)
        gender = try container.decode(Gender.self, forKey: .gender)
        email = try container.decodeIfPresent(String.self, forKey: .email)
        profilePhotoData = try container.decodeIfPresent(Data.self, forKey: .profilePhotoData)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        lastWeatherUpdate = try container.decodeIfPresent(Date.self, forKey: .lastWeatherUpdate)
        preferences = try container.decodeIfPresent(UserPreferences.self, forKey: .preferences) ?? UserPreferences()
        
        // Essayer d'abord dateOfBirth, sinon age (compatibilité)
        if let dob = try? container.decodeIfPresent(Date.self, forKey: .dateOfBirth) {
            dateOfBirth = dob
        } else if let ageValue = try? container.decodeIfPresent(Int.self, forKey: .age), ageValue > 0 {
            let calendar = Calendar.current
            let currentYear = calendar.component(.year, from: Date())
            var components = DateComponents()
            components.year = currentYear - ageValue
            components.month = 1
            components.day = 1
            dateOfBirth = calendar.date(from: components)
        } else {
            dateOfBirth = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(firstName, forKey: .firstName)
        try container.encodeIfPresent(dateOfBirth, forKey: .dateOfBirth)
        try container.encode(gender, forKey: .gender)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(profilePhotoData, forKey: .profilePhotoData)
        try container.encode(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(lastWeatherUpdate, forKey: .lastWeatherUpdate)
        try container.encode(preferences, forKey: .preferences)
    }
}

enum Gender: String, Codable, CaseIterable, Identifiable {
    case male = "Homme"
    case female = "Femme"
    case notSpecified = "Non spécifié"
    
    var id: String { rawValue }
}

struct UserPreferences: Codable {
    var preferredStyleRawValue: String?
    var favoriteColors: [String] = []
    var comfortLevel: Int = 3 // 1-5
    var styleLevel: Int = 3 // 1-5
    var casualness: Int = 3 // 1-5, 1 = très formel, 5 = très décontracté
    
    var preferredStyle: OutfitType? {
        get {
            guard let rawValue = preferredStyleRawValue else { return nil }
            return OutfitType(rawValue: rawValue)
        }
        set {
            preferredStyleRawValue = newValue?.rawValue
        }
    }
}

