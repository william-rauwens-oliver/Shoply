//
//  OnboardingView.swift
//  ShoplyCore - Android Compatible
//
//  Écran d'onboarding SwiftUI pour Android

import Foundation
#if canImport(SwiftUI)
import SwiftUI
#endif
import Combine

/// Vue d'onboarding (identique iOS)
public struct OnboardingView: View {
    @StateObject private var dataManager = DataManager.shared
    @State private var currentStep = 0
    @State private var firstName: String = ""
    @State private var age: String = ""
    @State private var selectedGender: Gender = .other
    
    public init() {}
    
    var body: some View {
        TabView(selection: $currentStep) {
            // Étape 1: Bienvenue
            WelcomeStepView()
                .tag(0)
            
            // Étape 2: Profil
            ProfileStepView(
                firstName: $firstName,
                age: $age,
                selectedGender: $selectedGender
            )
            .tag(1)
        }
        .tabViewStyle(.page(indexDisplayMode: .automatic))
        .onChange(of: currentStep) { oldValue, newValue in
            if newValue == 1 && !firstName.isEmpty {
                completeOnboarding()
            }
        }
    }
    
    private func completeOnboarding() {
        let ageInt = Int(age) ?? 25
        let profile = UserProfile(
            firstName: firstName,
            lastName: "",
            age: ageInt,
            gender: selectedGender
        )
        dataManager.saveUserProfile(profile)
    }
}

struct WelcomeStepView: View {
    var body: some View {
        VStack(spacing: 32) {
            Image(systemName: "sparkles")
                .font(.system(size: 80))
                .foregroundColor(AppColors.primaryText)
            
            Text("Bienvenue dans Shoply !")
                .font(.system(size: 32, weight: .bold))
                .foregroundColor(AppColors.primaryText)
                .multilineTextAlignment(.center)
            
            Text("Votre assistant personnel pour créer des outfits parfaits")
                .font(.system(size: 18))
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
        }
        .padding()
        .background(AppColors.background)
    }
}

struct ProfileStepView: View {
    @Binding var firstName: String
    @Binding var age: String
    @Binding var selectedGender: Gender
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Créer votre profil")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(AppColors.primaryText)
            
            VStack(spacing: 16) {
                TextField("Prénom", text: $firstName)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                TextField("Âge", text: $age)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .padding(.horizontal)
                
                Picker("Genre", selection: $selectedGender) {
                    ForEach([Gender.male, .female, .notSpecified], id: \.self) { gender in
                        Text(gender.rawValue).tag(gender)
                    }
                }
                .pickerStyle(.menu)
                .padding(.horizontal)
            }
            .padding()
        }
        .padding()
        .background(AppColors.background)
    }
}

