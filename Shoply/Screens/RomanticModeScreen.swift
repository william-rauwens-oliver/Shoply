//
//  RomanticModeScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct RomanticModeScreen: View {
    @State private var selectedOccasion: RomanticOutfit.RomanticOccasion?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // En-tête moderne
                        ModernRomanticHeader()
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        // Grille d'occasions
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(RomanticOutfit.RomanticOccasion.allCases, id: \.self) { occasion in
                                ModernRomanticOccasionCard(occasion: occasion) {
                                    withAnimation {
                                        selectedOccasion = occasion
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Dates & Occasions".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Dates & Occasions".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
            }
            .sheet(item: $selectedOccasion) { occasion in
                RomanticSuggestionsScreen(occasion: occasion)
            }
        }
    }
}

extension RomanticOutfit.RomanticOccasion: Identifiable {
    public var id: String { rawValue }
}

// MARK: - Composants Modernes

struct ModernRomanticHeader: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Sélectionnez une occasion pour obtenir des suggestions d'outfits adaptés".localized)
                .font(DesignSystem.Typography.body())
                .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
        }
    }
}

struct ModernRomanticOccasionCard: View {
    let occasion: RomanticOutfit.RomanticOccasion
    let onTap: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            Card(cornerRadius: DesignSystem.Radius.lg) {
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.buttonPrimary.opacity(0.2),
                                        AppColors.buttonPrimary.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 64, height: 64)
                        
                        Image(systemName: iconForOccasion(occasion))
                            .font(.system(size: 28, weight: .semibold))
                            .foregroundColor(AppColors.buttonPrimary)
                    }
                    
                    Text(occasion.rawValue.localized)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.primaryText)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 140)
                .padding(20)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 10)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    private func iconForOccasion(_ occasion: RomanticOutfit.RomanticOccasion) -> String {
        switch occasion {
        case .firstDate: return "heart.fill"
        case .romanticDinner: return "fork.knife"
        case .anniversary: return "gift.fill"
        case .wedding: return "heart.circle.fill"
        case .party: return "party.popper.fill"
        case .dateNight: return "moon.stars.fill"
        case .brunch: return "sunrise.fill"
        case .cinema: return "film.fill"
        case .concert: return "music.note"
        case .beach: return "beach.umbrella.fill"
        case .casualDate: return "tshirt.fill"
        }
    }
}

struct RomanticSuggestionsScreen: View {
    @Environment(\.dismiss) var dismiss
    let occasion: RomanticOutfit.RomanticOccasion
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
                    VStack(spacing: 20) {
                        ModernRomanticOccasionHeader(occasion: occasion)
                            .padding(.horizontal, 20)
                            .padding(.top, 20)
                        
                        if isLoading {
                            AIThinkingAnimation(message: "Génération des recommandations...".localized)
                                .frame(maxWidth: .infinity)
                                .padding(40)
                        } else if let error = error {
                            ModernRomanticErrorCard(error: error) {
                                loadGeminiRecommendations()
                            }
                            .padding(.horizontal, 20)
                        } else if let recommendations = geminiRecommendations {
                            ModernRomanticRecommendationsCard(recommendations: recommendations)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 20)
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
                
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButtonWithLongPress()
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
        guard geminiService.isEnabled else {
            error = "Gemini n'est pas configuré. Veuillez configurer votre clé API Gemini dans les paramètres.".localized
            isLoading = false
            return
        }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let recommendations = try await geminiService.generateRomanticRecommendations(
                    occasion: occasion,
                    userProfile: userProfile,
                    wardrobeItems: wardrobeService.items
                )
                await MainActor.run {
                    geminiRecommendations = recommendations
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
                        self.error = "Erreur lors de la génération des recommandations. Veuillez vérifier votre connexion et réessayer.".localized
                    } else {
                        self.error = error.localizedDescription
                    }
                    isLoading = false
                }
            }
        }
    }
}

struct ModernRomanticOccasionHeader: View {
    let occasion: RomanticOutfit.RomanticOccasion
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppColors.buttonPrimary.opacity(0.2),
                                    AppColors.buttonPrimary.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 64, height: 64)
                    
                    Image(systemName: iconForOccasion(occasion))
                        .font(.system(size: 30, weight: .semibold))
                        .foregroundColor(AppColors.buttonPrimary)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(occasion.rawValue.localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                        .fontWeight(.bold)
                }
                
                Spacer()
            }
            .padding(20)
        }
    }
    
    private func iconForOccasion(_ occasion: RomanticOutfit.RomanticOccasion) -> String {
        switch occasion {
        case .firstDate: return "heart.fill"
        case .romanticDinner: return "fork.knife"
        case .anniversary: return "gift.fill"
        case .wedding: return "heart.circle.fill"
        case .party: return "party.popper.fill"
        case .dateNight: return "moon.stars.fill"
        case .brunch: return "sunrise.fill"
        case .cinema: return "film.fill"
        case .concert: return "music.note"
        case .beach: return "beach.umbrella.fill"
        case .casualDate: return "tshirt.fill"
        }
    }
}

struct ModernRomanticRecommendationsCard: View {
    let recommendations: String
    
    private var parsedSections: (clothes: String, colors: String?, materials: String?) {
        let lines = recommendations.components(separatedBy: .newlines)
        var clothes = ""
        var colors: String? = nil
        var materials: String? = nil
        var currentSection = ""
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.contains("**Vêtements:**") || trimmed.contains("Vêtements:") {
                currentSection = "clothes"
            } else if trimmed.contains("**Couleurs") || trimmed.contains("Couleurs") {
                currentSection = "colors"
            } else if trimmed.contains("**Matières") || trimmed.contains("Matières") {
                currentSection = "materials"
            } else if !trimmed.isEmpty && trimmed.hasPrefix("-") {
                switch currentSection {
                case "clothes":
                    clothes += trimmed + "\n"
                case "colors":
                    colors = (colors ?? "") + trimmed + "\n"
                case "materials":
                    materials = (materials ?? "") + trimmed + "\n"
                default:
                    clothes += trimmed + "\n"
                }
            } else if !trimmed.isEmpty && !trimmed.hasPrefix("*") {
                switch currentSection {
                case "clothes":
                    clothes += trimmed + "\n"
                case "colors":
                    colors = (colors ?? "") + trimmed + "\n"
                case "materials":
                    materials = (materials ?? "") + trimmed + "\n"
                default:
                    clothes += trimmed + "\n"
                }
            }
        }
        
        return (clothes.trimmingCharacters(in: .whitespacesAndNewlines), 
                colors?.trimmingCharacters(in: .whitespacesAndNewlines), 
                materials?.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    var body: some View {
        let sections = parsedSections
        
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(alignment: .leading, spacing: 20) {
                HStack {
                    Text("Recommandations Gemini".localized)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.primaryText)
                    
                    Spacer()
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.buttonPrimary)
                }
                
                // Section Vêtements
                if !sections.clothes.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "tshirt.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.buttonPrimary)
                            
                            Text("Vêtements".localized)
                                .font(DesignSystem.Typography.headline())
                                .foregroundColor(AppColors.primaryText)
                        }
                        
                        Text(sections.clothes)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(AppColors.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                
                // Section Couleurs
                if let colors = sections.colors, !colors.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "paintpalette.fill")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.buttonPrimary)
                            
                            Text("Couleurs recommandées".localized)
                                .font(DesignSystem.Typography.headline())
                                .foregroundColor(AppColors.primaryText)
                        }
                        
                        Text(colors)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(AppColors.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)
                }
                
                // Section Matières
                if let materials = sections.materials, !materials.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "texture")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColors.buttonPrimary)
                            
                            Text("Matières recommandées".localized)
                                .font(DesignSystem.Typography.headline())
                                .foregroundColor(AppColors.primaryText)
                        }
                        
                        Text(materials)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(AppColors.primaryText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, 8)
                }
                
                // Fallback si le parsing n'a pas fonctionné
                if sections.clothes.isEmpty && sections.colors == nil && sections.materials == nil {
                    Text(recommendations)
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(AppColors.primaryText)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(20)
        }
    }
}

struct ModernRomanticErrorCard: View {
    let error: String
    let onRetry: () -> Void
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 32))
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
                    .padding(.vertical, 12)
                    .background(AppColors.buttonPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
                }
            }
            .padding(24)
        }
    }
}

