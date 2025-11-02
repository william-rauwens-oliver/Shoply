//
//  LiquidGlassTabBar.swift
//  Shoply - Outfit Selector
//
//  Created by William on 02/11/2025.
//

import SwiftUI

struct LiquidGlassTabBar: View {
    @Binding var selectedTab: TabItem
    @Environment(\.colorScheme) var colorScheme
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    
    enum TabItem: Int, CaseIterable {
        case home = 0
        case wardrobe = 1
        case favorites = 2
        case calendar = 3
        case profile = 4
        
        var icon: String {
            switch self {
            case .home: return "house.fill"
            case .wardrobe: return "tshirt.fill"
            case .favorites: return "heart.fill"
            case .calendar: return "calendar"
            case .profile: return "person.fill"
            }
        }
        
        var title: String {
            switch self {
            case .home: return "Accueil"
            case .wardrobe: return "Garde-robe"
            case .favorites: return "Favoris"
            case .calendar: return "Calendrier"
            case .profile: return "Profil"
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            let tabCount = CGFloat(TabItem.allCases.count)
            let tabWidth = (geometry.size.width - 12) / tabCount
            let selectedIndex = CGFloat(selectedTab.rawValue)
            let bubbleOffset = selectedIndex * tabWidth + (tabWidth / 2) + 6
            
            ZStack(alignment: .leading) {
                // Fond Liquid Glass iOS 26 (selon documentation Apple)
                RoundedRectangle(cornerRadius: 28)
                    .fill(.ultraThinMaterial)
                    .background {
                        // Effet liquid glass avec blur et translucidité
                        RoundedRectangle(cornerRadius: 28)
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
                        // Bordure fine translucide (style iOS 26)
                        RoundedRectangle(cornerRadius: 28)
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
                
                // Bulle glissante rectangulaire arrondie sous l'onglet sélectionné (iOS 26 style)
                RoundedRectangle(cornerRadius: 20)
                    .fill(colorScheme == .dark ? Color(white: 0.25) : Color(white: 0.95))
                    .frame(width: tabWidth - 8, height: 56)
                    .shadow(
                        color: Color.black.opacity(colorScheme == .dark ? 0.3 : 0.12),
                        radius: 12,
                        x: 0,
                        y: 4
                    )
                    .offset(x: bubbleOffset - (tabWidth / 2) - 2 + dragOffset)
                    .gesture(
                        DragGesture(minimumDistance: 10)
                            .onChanged { value in
                                isDragging = true
                                // Limiter le déplacement à la zone de la barre
                                let maxOffset = tabWidth * CGFloat(TabItem.allCases.count - 1)
                                dragOffset = max(-maxOffset, min(maxOffset, value.translation.width))
                            }
                            .onEnded { value in
                                let threshold: CGFloat = tabWidth / 2.5
                                let velocity = value.predictedEndTranslation.width - value.translation.width
                                
                                // Changer d'onglet si le glissement dépasse le seuil ou la vélocité est élevée
                                if abs(value.translation.width) > threshold || abs(velocity) > 300 {
                                    if value.translation.width > 0 && selectedTab.rawValue > 0 {
                                        // Glisser vers la droite -> onglet précédent
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                            selectedTab = TabItem(rawValue: selectedTab.rawValue - 1) ?? selectedTab
                                        }
                                    } else if value.translation.width < 0 && selectedTab.rawValue < TabItem.allCases.count - 1 {
                                        // Glisser vers la gauche -> onglet suivant
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                            selectedTab = TabItem(rawValue: selectedTab.rawValue + 1) ?? selectedTab
                                        }
                                    }
                                }
                                
                                // Réinitialiser la position
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                    dragOffset = 0
                                    isDragging = false
                                }
                            }
                    )
                    .animation(isDragging ? nil : .spring(response: 0.35, dampingFraction: 0.75), value: selectedTab)
                
                // Contenu des onglets (au-dessus de la bulle)
                HStack(spacing: 0) {
                    ForEach(TabItem.allCases, id: \.self) { tab in
                        Button {
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                selectedTab = tab
                            }
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: tab.icon)
                                    .font(.system(size: 22, weight: selectedTab == tab ? .semibold : .regular))
                                    .foregroundColor(selectedTab == tab ? Color.purple : (colorScheme == .dark ? Color.white : Color.white))
                                    .symbolVariant(selectedTab == tab ? .fill : .none)
                                
                                Text(tab.title.localized)
                                    .font(.system(size: 11, weight: selectedTab == tab ? .bold : .regular))
                                    .foregroundColor(selectedTab == tab ? Color.white : (colorScheme == .dark ? Color.white : Color.white))
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 6)
            }
            .frame(height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 28))
            .shadow(
                color: Color.black.opacity(colorScheme == .dark ? 0.5 : 0.15),
                radius: 24,
                x: 0,
                y: 6
            )
        }
        .frame(height: 68)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }
}

