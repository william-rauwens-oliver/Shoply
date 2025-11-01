//
//  PreviewHelpers.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

/// Helpers pour les previews SwiftUI
struct PreviewHelpers {
    
    // MARK: - Sample Data
    
    static var sampleOutfit: Outfit {
        Outfit(
            name: "Look Dynamique",
            description: "Parfait pour une journée active et productive",
            type: .casual,
            top: "T-shirt coloré",
            bottom: "Jeans slim",
            shoes: "Baskets blanches",
            accessories: ["Montre connectée"],
            suitableMoods: [.energetic, .creative],
            suitableWeather: [.sunny, .warm],
            imageName: "outfit_energetic_1",
            comfortLevel: 5,
            styleLevel: 4
        )
    }
    
    static var sampleOutfits: [Outfit] {
        OutfitFactory.createDefaultOutfits()
    }
    
    // MARK: - Preview Modifiers
    
    static func previewWithEnvironment<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .environmentObject(DataManager.shared)
            .environmentObject(AppState())
    }
    
    static func previewWithService<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .environmentObject(OutfitService())
            .environmentObject(DataManager.shared)
    }
}

