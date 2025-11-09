//
//  TrendAnalysisScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct TrendAnalysisScreen: View {
    @StateObject private var geminiService = GeminiService.shared
    @State private var geminiTrends: String?
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
                            .padding(.top, DesignSystem.Spacing.md)
                        } else if let trends = geminiTrends {
                            Card(cornerRadius: DesignSystem.Radius.lg) {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                    Text("Tendances Mode".localized)
                                        .font(DesignSystem.Typography.title2())
                                        .foregroundColor(AppColors.primaryText)
                                    
                                    Text(trends)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(AppColors.primaryText)
                                }
                                .padding(DesignSystem.Spacing.md)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.top, DesignSystem.Spacing.md)
                        } else {
                            VStack(spacing: DesignSystem.Spacing.lg) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 60, weight: .light))
                                    .foregroundColor(AppColors.secondaryText)
                                
                                Text("Tendances Mode".localized)
                                    .font(DesignSystem.Typography.title2())
                                    .foregroundColor(AppColors.primaryText)
                                
                                Text("Découvrez les tendances d'outfits selon votre localisation et votre âge".localized)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.secondaryText)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal, DesignSystem.Spacing.lg)
                                
                                Button {
                                    loadGeminiTrends()
                                } label: {
                                    HStack {
                                        Image(systemName: "magnifyingglass")
                                            .font(.system(size: 18, weight: .medium))
                                        Text("Analyser les tendances".localized)
                                            .font(DesignSystem.Typography.headline())
                                    }
                                    .foregroundColor(AppColors.buttonPrimaryText)
                                    .padding(.horizontal, DesignSystem.Spacing.lg)
                                    .padding(.vertical, DesignSystem.Spacing.md)
                                    .background(AppColors.buttonPrimary)
                                    .cornerRadius(DesignSystem.Radius.md)
                                }
                            }
                            .padding(.top, DesignSystem.Spacing.xl)
                        }
                    }
                    .padding(.bottom, DesignSystem.Spacing.xl)
                }
            }
            .navigationTitle("Tendances".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Tendances".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
            }
            .onAppear {
                if geminiTrends == nil {
                    loadGeminiTrends()
                }
            }
        }
    }
    
    private func loadGeminiTrends() {
        isLoading = true
        error = nil
        
        // Détecter le pays et la ville
        let country = detectCountry()
        let city = detectCity()
        
        Task {
            do {
                let trends = try await geminiService.analyzeTrends(
                    country: country,
                    city: city,
                    age: userProfile.age,
                    userProfile: userProfile
                )
                await MainActor.run {
                    geminiTrends = trends
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
    
    private func detectCountry() -> String {
        // Utiliser la langue comme proxy pour le pays
        let language = Locale.current.language.languageCode?.identifier ?? "fr"
        switch language {
        case "fr": return "France"
        case "en": return "États-Unis"
        case "es": return "Espagne"
        case "de": return "Allemagne"
        case "it": return "Italie"
        default: return "France"
        }
    }
    
    private func detectCity() -> String? {
        // Pour l'instant, retourner nil (peut être amélioré avec CoreLocation)
        return nil
    }
}
