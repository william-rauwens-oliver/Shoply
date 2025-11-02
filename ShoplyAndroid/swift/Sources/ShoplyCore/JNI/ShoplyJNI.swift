//
//  ShoplyJNI.swift
//  ShoplyCore - Android JNI Bridge
//
//  Bridge JNI pour exposer les fonctions Swift à Kotlin

import Foundation

// MARK: - OutfitService JNI

/// Charger tous les outfits
@_cdecl("Java_com_shoply_app_ShoplyCore_loadOutfits")
public func loadOutfitsJNI() -> UnsafePointer<CChar>? {
    let service = OutfitService.shared
    service.loadOutfits()
    
    let outfits = service.outfits
    guard let jsonData = try? JSONEncoder().encode(outfits),
          let jsonString = String(data: jsonData, encoding: .utf8) else {
        return nil
    }
    
    let cString = strdup(jsonString)
    return UnsafePointer(cString)
}

/// Toggle favori
@_cdecl("Java_com_shoply_app_ShoplyCore_toggleFavorite")
public func toggleFavoriteJNI(outfitIdString: UnsafePointer<CChar>?) -> Bool {
    guard let outfitIdString = outfitIdString,
          let uuidString = String(utf8String: outfitIdString),
          let outfitId = UUID(uuidString: uuidString) else {
        return false
    }
    
    let service = OutfitService.shared
    if let outfit = service.outfits.first(where: { $0.id == outfitId }) {
        service.toggleFavorite(outfit: outfit)
        return true
    }
    return false
}

/// Obtenir outfits filtrés
@_cdecl("Java_com_shoply_app_ShoplyCore_getOutfitsFor")
public func getOutfitsForJNI(moodString: UnsafePointer<CChar>?, weatherString: UnsafePointer<CChar>?) -> UnsafePointer<CChar>? {
    guard let moodString = moodString,
          let weatherString = weatherString,
          let moodRaw = String(utf8String: moodString),
          let weatherRaw = String(utf8String: weatherString),
          let mood = Mood(rawValue: moodRaw),
          let weather = WeatherType(rawValue: weatherRaw) else {
        return nil
    }
    
    let service = OutfitService.shared
    let outfits = service.getOutfitsFor(mood: mood, weather: weather)
    
    guard let jsonData = try? JSONEncoder().encode(outfits),
          let jsonString = String(data: jsonData, encoding: .utf8) else {
        return nil
    }
    
    let cString = strdup(jsonString)
    return UnsafePointer(cString)
}

// MARK: - WardrobeService JNI

/// Obtenir tous les items de garde-robe
@_cdecl("Java_com_shoply_app_ShoplyCore_getWardrobeItems")
public func getWardrobeItemsJNI() -> UnsafePointer<CChar>? {
    let service = WardrobeService.shared
    let items = service.items
    
    guard let jsonData = try? JSONEncoder().encode(items),
          let jsonString = String(data: jsonData, encoding: .utf8) else {
        return nil
    }
    
    let cString = strdup(jsonString)
    return UnsafePointer(cString)
}

/// Ajouter un item à la garde-robe
@_cdecl("Java_com_shoply_app_ShoplyCore_addWardrobeItem")
public func addWardrobeItemJNI(itemJson: UnsafePointer<CChar>?) -> Bool {
    guard let itemJson = itemJson,
          let jsonString = String(utf8String: itemJson),
          let jsonData = jsonString.data(using: .utf8),
          let item = try? JSONDecoder().decode(WardrobeItem.self, from: jsonData) else {
        return false
    }
    
    let service = WardrobeService.shared
    service.addItem(item)
    return true
}

// MARK: - DataManager JNI

/// Charger le profil utilisateur
@_cdecl("Java_com_shoply_app_ShoplyCore_loadUserProfile")
public func loadUserProfileJNI() -> UnsafePointer<CChar>? {
    let dataManager = DataManager.shared
    guard let profile = dataManager.loadUserProfile() else {
        return nil
    }
    
    guard let jsonData = try? JSONEncoder().encode(profile),
          let jsonString = String(data: jsonData, encoding: .utf8) else {
        return nil
    }
    
    let cString = strdup(jsonString)
    return UnsafePointer(cString)
}

/// Sauvegarder le profil utilisateur
@_cdecl("Java_com_shoply_app_ShoplyCore_saveUserProfile")
public func saveUserProfileJNI(profileJson: UnsafePointer<CChar>?) -> Bool {
    guard let profileJson = profileJson,
          let jsonString = String(utf8String: profileJson),
          let jsonData = jsonString.data(using: .utf8),
          let profile = try? JSONDecoder().decode(UserProfile.self, from: jsonData) else {
        return false
    }
    
    let dataManager = DataManager.shared
    dataManager.saveUserProfile(profile)
    return true
}

/// Vérifier si l'onboarding est terminé
@_cdecl("Java_com_shoply_app_ShoplyCore_hasCompletedOnboarding")
public func hasCompletedOnboardingJNI() -> Bool {
    let dataManager = DataManager.shared
    return dataManager.hasCompletedOnboarding()
}

