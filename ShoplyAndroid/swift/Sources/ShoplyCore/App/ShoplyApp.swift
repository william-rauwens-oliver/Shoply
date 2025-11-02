//
//  ShoplyApp.swift
//  ShoplyCore - Android Compatible
//
//  Point d'entrée de l'application SwiftUI pour Android

import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif

/// Application principale SwiftUI pour Android (identique iOS)
@main
public struct ShoplyApp: App {
    public init() {}
    
    public var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

/// Vue principale avec navigation (identique iOS)
public struct ContentView: View {
    @StateObject private var dataManager = DataManager.shared
    
    public init() {}
    
    public var body: some View {
        Group {
            if dataManager.hasCompletedOnboarding() {
                HomeView()
            } else {
                OnboardingView()
            }
        }
    }
}

