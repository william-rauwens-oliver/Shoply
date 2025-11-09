//
//  ProfessionalModeScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct ProfessionalModeScreen: View {
    @State private var selectedOccasion: ProfessionalOutfit.ProfessionalOccasion?
    @State private var showingSuggestions = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Text("Mode Professionnel".localized)
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(AppColors.primaryText)
                            .padding(.top, DesignSystem.Spacing.md)
                        
                        Text("Sélectionnez une occasion professionnelle pour obtenir des suggestions d'outfits adaptés".localized)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                            GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
                        ], spacing: DesignSystem.Spacing.md) {
                            ForEach(ProfessionalOutfit.ProfessionalOccasion.allCases, id: \.self) { occasion in
                                Button {
                                    selectedOccasion = occasion
                                    showingSuggestions = true
                                } label: {
                                    OccasionCard(occasion: occasion)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                    }
                    .padding(.bottom, DesignSystem.Spacing.xl)
                }
            }
            .navigationTitle("Mode Professionnel".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Mode Professionnel".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
            }
            .sheet(isPresented: $showingSuggestions) {
                if let occasion = selectedOccasion {
                    ProfessionalSuggestionsScreen(occasion: occasion)
                }
            }
        }
    }
}

struct OccasionCard: View {
    let occasion: ProfessionalOutfit.ProfessionalOccasion
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(spacing: DesignSystem.Spacing.md) {
                ZStack {
                    Circle()
                        .fill(AppColors.buttonPrimary.opacity(0.15))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: iconForOccasion(occasion))
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(AppColors.buttonPrimary)
                }
                
                Text(occasion.rawValue.localized)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(AppColors.primaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 120)
            .padding(DesignSystem.Spacing.md)
        }
    }
    
    private func iconForOccasion(_ occasion: ProfessionalOutfit.ProfessionalOccasion) -> String {
        switch occasion {
        case .jobInterview: return "person.badge.plus"
        case .presentation: return "person.wave.2"
        case .meeting: return "person.2"
        case .networking: return "person.3"
        case .conference: return "person.2.badge.gearshape"
        case .clientMeeting: return "handshake"
        }
    }
}

struct ProfessionalSuggestionsScreen: View {
    @Environment(\.dismiss) var dismiss
    let occasion: ProfessionalOutfit.ProfessionalOccasion
    @StateObject private var wardrobeService = WardrobeService()
    @StateObject private var geminiService = GeminiService.shared
    @State private var geminiRecommendations: String?
    @State private var isLoading = false
    @State private var error: String?
    
    private var userProfile: UserProfile {
        DataManager.shared.loadUserProfile() ?? UserProfile()
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text(occasion.rawValue.localized)
                                    .font(DesignSystem.Typography.title2())
                                    .foregroundColor(AppColors.primaryText)
                            }
                            .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.top, DesignSystem.Spacing.md)
                        
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(DesignSystem.Spacing.xl)
                        } else if let error = error {
                            Card(cornerRadius: DesignSystem.Radius.lg) {
                                Text("Erreur: \(error)".localized)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(.red)
                                    .padding(DesignSystem.Spacing.md)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        } else if let recommendations = geminiRecommendations {
                            Card(cornerRadius: DesignSystem.Radius.lg) {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                    Text("Recommandations Gemini".localized)
                                        .font(DesignSystem.Typography.headline())
                                        .foregroundColor(AppColors.primaryText)
                                    
                                    Text(recommendations)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(AppColors.primaryText)
                                }
                                .padding(DesignSystem.Spacing.md)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                        
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("Couleurs recommandées".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: DesignSystem.Spacing.sm) {
                                    ForEach(occasion.colorRecommendations, id: \.self) { color in
                                        Text(color.capitalized)
                                            .font(DesignSystem.Typography.caption())
                                            .foregroundColor(AppColors.buttonPrimary)
                                            .padding(.horizontal, DesignSystem.Spacing.sm)
                                            .padding(.vertical, DesignSystem.Spacing.xs)
                                            .background(AppColors.buttonPrimary.opacity(0.15))
                                            .cornerRadius(DesignSystem.Radius.sm)
                                    }
                                }
                            }
                            .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                    }
                    .padding(.bottom, DesignSystem.Spacing.xl)
                }
            }
            .navigationTitle("Suggestions".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Suggestions".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer".localized) { dismiss() }
                        .foregroundColor(AppColors.primaryText)
                }
            }
            .onAppear {
                loadGeminiRecommendations()
            }
        }
    }
    
    private func loadGeminiRecommendations() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let recommendations = try await geminiService.generateProfessionalRecommendations(
                    occasion: occasion,
                    userProfile: userProfile,
                    wardrobeItems: wardrobeService.items
                )
                await MainActor.run {
                    geminiRecommendations = recommendations
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.error = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}
