//
//  UserProfile.swift
//  ShoplyCore - Android Compatible
//
//  Created by William on 02/11/2025.
//

import Foundation

/// Profil utilisateur - Compatible Android
struct UserProfile: Codable {
    var firstName: String
    var age: Int
    var gender: Gender
    var email: String?
    var createdAt: Date
    var lastWeatherUpdate: Date?
    var preferences: UserPreferences
    
    init(firstName: String = "", age: Int = 0, gender: Gender = .notSpecified, email: String? = nil, createdAt: Date = Date(), preferences: UserPreferences = UserPreferences()) {
        self.firstName = firstName
        self.age = age
        self.gender = gender
        self.email = email
        self.createdAt = createdAt
        self.preferences = preferences
    }
}

public enum Gender: String, Codable, CaseIterable {
    case male = "Homme"
    case female = "Femme"
    case notSpecified = "Non spécifié"
    case other = "Autre"
    
    public var id: String { rawValue }
    
    public init(rawValue: String) {
        switch rawValue {
        case "Homme": self = .male
        case "Femme": self = .female
        case "Non spécifié": self = .notSpecified
        default: self = .other
        }
    }
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

