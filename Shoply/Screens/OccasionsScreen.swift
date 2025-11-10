//
//  OccasionsScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct OccasionsScreen: View {
    @State private var selectedTab: OccasionTab = .professional
    @State private var selectedProfessionalOccasion: ProfessionalOutfit.ProfessionalOccasion?
    @State private var selectedRomanticOccasion: RomanticOutfit.RomanticOccasion?
    
    enum OccasionTab: String, CaseIterable {
        case professional = "Professionnel"
        case romantic = "Dates & Occasions"
        
        var icon: String {
            switch self {
            case .professional: return "briefcase.fill"
            case .romantic: return "heart.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Sélecteur d'onglets
                    OccasionTabPicker(selectedTab: $selectedTab)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Contenu selon l'onglet sélectionné
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 24) {
                            // En-tête
                            if selectedTab == .professional {
                                ModernProfessionalHeader()
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                            } else {
                                ModernRomanticHeader()
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                            }
                            
                            // Grille d'occasions
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 16) {
                                if selectedTab == .professional {
                                    ForEach(ProfessionalOutfit.ProfessionalOccasion.allCases, id: \.self) { occasion in
                                        ModernOccasionCard(occasion: occasion) {
                                            withAnimation {
                                                selectedProfessionalOccasion = occasion
                                            }
                                        }
                                    }
                                } else {
                                    ForEach(RomanticOutfit.RomanticOccasion.allCases, id: \.self) { occasion in
                                        ModernRomanticOccasionCard(occasion: occasion) {
                                            withAnimation {
                                                selectedRomanticOccasion = occasion
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Occasions".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Occasions".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButtonWithLongPress()
                }
            }
            .sheet(item: $selectedProfessionalOccasion) { occasion in
                ProfessionalSuggestionsScreen(occasion: occasion)
            }
            .sheet(item: $selectedRomanticOccasion) { occasion in
                RomanticSuggestionsScreen(occasion: occasion)
            }
        }
    }
}

// MARK: - Sélecteur d'onglets Liquid Glass

struct OccasionTabPicker: View {
    @Binding var selectedTab: OccasionsScreen.OccasionTab
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            let tabCount = CGFloat(OccasionsScreen.OccasionTab.allCases.count)
            let tabWidth = (geometry.size.width - 8) / tabCount
            let selectedIndex = CGFloat(selectedTab == .professional ? 0 : 1)
            let bubbleOffset = selectedIndex * tabWidth + (tabWidth / 2) + 4
            
            ZStack(alignment: .leading) {
                // Fond Liquid Glass
                RoundedRectangle(cornerRadius: 24)
                    .fill(.ultraThinMaterial)
                    .background {
                        // Effet liquid glass avec blur et translucidité
                        RoundedRectangle(cornerRadius: 24)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.12 : 0.18),
                                        Color.white.opacity(colorScheme == .dark ? 0.06 : 0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .blur(radius: 30)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(colorScheme == .dark ? 0.25 : 0.35),
                                        Color.white.opacity(colorScheme == .dark ? 0.15 : 0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
                
                // Bulle glissante sous l'onglet sélectionné
                RoundedRectangle(cornerRadius: 18)
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.buttonPrimary.opacity(0.9),
                                AppColors.buttonPrimary.opacity(0.8)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: tabWidth - 8, height: 48)
                    .offset(x: bubbleOffset - (tabWidth / 2))
                    .shadow(
                        color: AppColors.buttonPrimary.opacity(0.4),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
                
                // Contenu des onglets (au-dessus de la bulle)
                HStack(spacing: 0) {
                    ForEach(OccasionsScreen.OccasionTab.allCases, id: \.self) { tab in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selectedTab = tab
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 16, weight: selectedTab == tab ? .semibold : .medium))
                                    .foregroundColor(selectedTab == tab ? AppColors.buttonPrimaryText : AppColors.secondaryText)
                                    .symbolVariant(selectedTab == tab ? .fill : .none)
                                
                                Text(tab.rawValue.localized)
                                    .font(DesignSystem.Typography.headline())
                                    .fontWeight(selectedTab == tab ? .bold : .medium)
                                    .foregroundColor(selectedTab == tab ? AppColors.buttonPrimaryText : AppColors.secondaryText)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 4)
            }
            .frame(height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.15),
                radius: 20,
                x: 0,
                y: 6
            )
        }
        .frame(height: 64)
    }
}

