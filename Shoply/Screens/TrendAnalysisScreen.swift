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
                    VStack(spacing: 24) {
                        if isLoading {
                            AIThinkingAnimation(message: "Analyse des tendances en cours...".localized)
                                .frame(maxWidth: .infinity)
                                .padding(40)
                        } else if let error = error {
                            ModernTrendErrorCard(error: error) {
                                loadGeminiTrends()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        } else if let trends = geminiTrends {
                            ModernTrendsCard(trends: trends)
                                .padding(.horizontal, 20)
                                .padding(.top, 20)
                        } else {
                            ModernEmptyTrendsView {
                                    loadGeminiTrends()
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 40)
                        }
                    }
                    .padding(.bottom, 20)
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
        }
    }
    
    private func loadGeminiTrends() {
        guard geminiService.isEnabled else {
            error = "Gemini n'est pas configuré. Veuillez configurer votre clé API Gemini dans les paramètres.".localized
            isLoading = false
            return
        }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let trends = try await geminiService.analyzeTrends(
                    country: "France",
                    city: nil,
                    age: userProfile.age,
                    userProfile: userProfile
                )
                await MainActor.run {
                    geminiTrends = trends
                    isLoading = false
                }
            } catch let error as GeminiError {
                await MainActor.run {
                    switch error {
                    case .apiKeyMissing:
                        self.error = "Clé API Gemini manquante. Veuillez la configurer dans les paramètres.".localized
                    case .apiError:
                        self.error = "Erreur lors de la communication avec Gemini. Veuillez réessayer plus tard.".localized
                    case .apiErrorWithMessage(let message):
                        self.error = "Erreur Gemini: \(message)".localized
                    case .noResponse:
                        self.error = "Aucune réponse de Gemini. Veuillez réessayer.".localized
                    case .invalidURL:
                        self.error = "Erreur de configuration. Veuillez contacter le support.".localized
                    case .noItems:
                        self.error = "Aucun vêtement dans votre garde-robe.".localized
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    if error.localizedDescription.contains("GeminiError") {
                        self.error = "Erreur lors de l'analyse des tendances. Veuillez vérifier votre connexion et réessayer.".localized
                    } else {
                    self.error = error.localizedDescription
                    }
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Composants Modernes

struct ModernEmptyTrendsView: View {
    let onAnalyze: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.buttonSecondary,
                                AppColors.buttonSecondary.opacity(0.7)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 120, height: 120)
                    .overlay {
                        Circle()
                            .stroke(AppColors.cardBorder.opacity(0.3), lineWidth: 2)
                    }
                
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(AppColors.secondaryText)
            }
            .shadow(color: AppColors.shadow.opacity(0.15), radius: 16, x: 0, y: 6)
            
            VStack(spacing: 12) {
                Text("Tendances Mode".localized)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(AppColors.primaryText)
                
                Text("Découvrez les tendances d'outfits selon votre localisation et votre âge".localized)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: onAnalyze) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 18, weight: .medium))
                    Text("Analyser les tendances".localized)
                        .font(DesignSystem.Typography.headline())
                }
                .foregroundColor(AppColors.buttonPrimaryText)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(AppColors.buttonPrimary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
            }
        }
    }
}

struct ModernTrendsCard: View {
    let trends: String
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Tendances Mode".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                        .fontWeight(.bold)
                    
                    Spacer()
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(AppColors.buttonPrimary)
                }
                
                Text(trends)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(AppColors.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(24)
        }
    }
}

struct ModernTrendErrorCard: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(spacing: 20) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.red)
                
                Text(error)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(AppColors.primaryText)
                    .multilineTextAlignment(.center)
                
                Button(action: onRetry) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Réessayer".localized)
                    }
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(AppColors.buttonPrimaryText)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(AppColors.buttonPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
                }
            }
            .padding(32)
        }
    }
}
