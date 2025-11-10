//
//  StatisticsScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import Charts

struct StatisticsScreen: View {
    @StateObject private var analyticsService = StyleAnalyticsService.shared
    @StateObject private var wardrobeService = WardrobeService()
    @State private var statistics = StyleStatistics()
    @State private var environmentalImpact = EnvironmentalImpact()
    @State private var costPerWear: [CostPerWear] = []
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Tabs modernes
                        StatisticsTabPicker(selectedTab: $selectedTab)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)
                        
                        // Contenu selon le tab
                        Group {
                            if selectedTab == 0 {
                                modernStyleStatisticsView
                            } else if selectedTab == 1 {
                                modernEnvironmentalView
                            } else {
                                modernCostView
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
            }
            .navigationTitle("Statistiques".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Statistiques".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButtonWithLongPress()
                }
            }
            .onAppear {
                loadStatistics()
            }
        }
    }
    
    private var modernStyleStatisticsView: some View {
        VStack(spacing: 20) {
            // Cartes de résumé
            HStack(spacing: 12) {
                ModernStatCard(
                    title: "Vêtements".localized,
                    value: "\(statistics.totalItems)",
                    icon: "tshirt.fill",
                    color: .blue
                )
                
                ModernStatCard(
                    title: "Outfits".localized,
                    value: "\(statistics.totalOutfits)",
                    icon: "sparkles",
                    color: .purple
                )
            }
            .padding(.horizontal, 20)
            
            // Couleurs les plus portées
            if !statistics.mostWornColors.isEmpty {
                ModernSectionCard(
                    title: "Couleurs les plus portées".localized,
                    icon: "paintpalette.fill",
                    color: .pink
                ) {
                        ForEach(statistics.mostWornColors.prefix(5)) { colorFreq in
                        ModernColorFrequencyRow(colorFreq: colorFreq)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Catégories les plus portées
            if !statistics.mostWornCategories.isEmpty {
                ModernSectionCard(
                    title: "Catégories les plus portées".localized,
                    icon: "square.grid.2x2.fill",
                    color: .orange
                ) {
                        ForEach(statistics.mostWornCategories.prefix(5)) { categoryFreq in
                        ModernCategoryFrequencyRow(categoryFreq: categoryFreq)
                    }
                }
                .padding(.horizontal, 20)
            }
            
            // Niveaux moyens
            HStack(spacing: 12) {
                ModernMetricCard(
                    title: "Confort moyen".localized,
                    value: String(format: "%.1f", statistics.averageComfortLevel),
                    icon: "heart.fill",
                    color: .red
                )
                
                ModernMetricCard(
                    title: "Style moyen".localized,
                    value: String(format: "%.1f", statistics.averageStyleLevel),
                    icon: "star.fill",
                    color: .yellow
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var modernEnvironmentalView: some View {
        VStack(spacing: 20) {
            // Score de durabilité
            ModernSustainabilityCard(score: environmentalImpact.sustainabilityScore)
                .padding(.horizontal, 20)
            
            // Statistiques environnementales
            ModernSectionCard(
                title: "Impact environnemental".localized,
                icon: "leaf.fill",
                color: .green
            ) {
                ModernEnvStatRow(
                    title: "Vêtements portés ce mois".localized,
                    value: "\(environmentalImpact.itemsWornThisMonth)",
                    icon: "calendar"
                )
                ModernEnvStatRow(
                    title: "Port moyen par vêtement".localized,
                    value: String(format: "%.1f", environmentalImpact.averageWearPerItem),
                    icon: "arrow.repeat"
                )
                ModernEnvStatRow(
                    title: "Non portés (30 jours)".localized,
                    value: "\(environmentalImpact.itemsNotWornIn30Days)",
                    icon: "clock"
                )
                ModernEnvStatRow(
                    title: "Réduction CO₂ (kg)".localized,
                    value: String(format: "%.1f", environmentalImpact.carbonFootprintReduction),
                    icon: "leaf.arrow.circlepath"
                )
            }
            .padding(.horizontal, 20)
        }
    }
    
    private var modernCostView: some View {
        VStack(spacing: 16) {
            if costPerWear.isEmpty {
                ModernEmptyStateCard(
                    icon: "dollarsign.circle",
                    title: "Aucun prix renseigné".localized,
                    message: "Ajoutez des prix à vos vêtements pour voir le coût par port".localized
                )
                .padding(.horizontal, 20)
            } else {
                ForEach(costPerWear.sorted(by: { ($0.costPerWear ?? 0) < ($1.costPerWear ?? 0) })) { cost in
                    ModernCostPerWearCard(cost: cost)
                        .padding(.horizontal, 20)
                }
            }
        }
    }
    
    private func loadStatistics() {
        statistics = analyticsService.calculateStatistics()
        environmentalImpact = analyticsService.calculateEnvironmentalImpact()
        costPerWear = analyticsService.calculateCostPerWear(items: wardrobeService.items)
    }
}

// MARK: - Composants Modernes

struct StatisticsTabPicker: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<3) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    Text(tabTitle(for: index))
                        .font(DesignSystem.Typography.footnote())
                        .fontWeight(.semibold)
                        .foregroundColor(selectedTab == index ? AppColors.buttonPrimaryText : AppColors.secondaryText)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(selectedTab == index ? AppColors.buttonPrimary : Color.clear)
                }
            }
        }
        .background(AppColors.buttonSecondary)
        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
    }
    
    private func tabTitle(for index: Int) -> String {
        switch index {
        case 0: return "Style".localized
        case 1: return "Environnement".localized
        case 2: return "Coût".localized
        default: return ""
        }
    }
}

struct ModernStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.2), color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(value)
                    .font(DesignSystem.Typography.title())
                    .foregroundColor(AppColors.primaryText)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(AppColors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
        }
    }
}

struct ModernSectionCard<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(color)
        }
                    
                    Text(title)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.primaryText)
                }
                
                content
            }
            .padding(20)
        }
    }
}

struct ModernColorFrequencyRow: View {
    let colorFreq: ColorFrequency
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(colorFromString(colorFreq.color))
                .frame(width: 24, height: 24)
                .overlay {
                    Circle()
                        .stroke(AppColors.cardBorder, lineWidth: 1)
                }
            
            Text(colorFreq.color)
                .font(DesignSystem.Typography.body())
                .foregroundColor(AppColors.primaryText)
            
            Spacer()
            
            HStack(spacing: 8) {
            Text("\(colorFreq.count) fois".localized)
                .font(DesignSystem.Typography.footnote())
                .foregroundColor(AppColors.secondaryText)
            
            Text("\(Int(colorFreq.percentage))%")
                .font(DesignSystem.Typography.footnote())
                .foregroundColor(AppColors.primaryText)
                .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.buttonSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.sm))
            }
        }
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "rouge", "red": return .red
        case "bleu", "blue": return .blue
        case "vert", "green": return .green
        case "jaune", "yellow": return .yellow
        case "noir", "black": return .black
        case "blanc", "white": return .white
        case "gris", "gray", "grey": return .gray
        case "rose", "pink": return .pink
        case "orange": return .orange
        case "violet", "purple": return .purple
        default: return .gray
        }
    }
}

struct ModernCategoryFrequencyRow: View {
    let categoryFreq: CategoryFrequency
    
    var body: some View {
        HStack(spacing: 12) {
            Text(categoryFreq.category)
                .font(DesignSystem.Typography.body())
                .foregroundColor(AppColors.primaryText)
            
            Spacer()
            
            HStack(spacing: 8) {
            Text("\(categoryFreq.count) fois".localized)
                .font(DesignSystem.Typography.footnote())
                .foregroundColor(AppColors.secondaryText)
            
            Text("\(Int(categoryFreq.percentage))%")
                .font(DesignSystem.Typography.footnote())
                .foregroundColor(AppColors.primaryText)
                .fontWeight(.semibold)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColors.buttonSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.sm))
            }
        }
    }
}

struct ModernMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.15))
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(color)
                }
                
                Text(value)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(AppColors.primaryText)
                    .fontWeight(.bold)
                
                Text(title)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(20)
        }
    }
}

struct ModernSustainabilityCard: View {
    let score: Double
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(spacing: 20) {
                Text("Score de Durabilité".localized)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(AppColors.primaryText)
                
                ZStack {
                    Circle()
                        .stroke(AppColors.cardBorder, lineWidth: 16)
                        .frame(width: 160, height: 160)
                    
                    Circle()
                        .trim(from: 0, to: score / 100)
                        .stroke(
                            LinearGradient(
                                colors: [.green, .mint],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            style: StrokeStyle(lineWidth: 16, lineCap: .round)
                        )
                        .frame(width: 160, height: 160)
                        .rotationEffect(.degrees(-90))
                    
                    VStack(spacing: 4) {
                        Text("\(Int(score))")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                        Text("/ 100")
                            .font(DesignSystem.Typography.footnote())
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
            .padding(24)
        }
    }
}

struct ModernEnvStatRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.green)
                .frame(width: 32, height: 32)
                .background(Circle().fill(Color.green.opacity(0.15)))
            
            Text(title)
                .font(DesignSystem.Typography.body())
                .foregroundColor(AppColors.primaryText)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.headline())
                .foregroundColor(.green)
                .fontWeight(.semibold)
        }
    }
}

struct ModernCostPerWearCard: View {
    let cost: CostPerWear
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(cost.itemName)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Porté \(cost.wearCount) fois".localized)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 6) {
                    if let costPerWear = cost.costPerWear {
                        Text("\(String(format: "%.2f", costPerWear)) €/port")
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(AppColors.buttonPrimary)
                            .fontWeight(.bold)
                    }
                    if let price = cost.purchasePrice {
                        Text("Acheté \(String(format: "%.2f", price)) €".localized)
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
            .padding(20)
        }
    }
}

struct ModernEmptyStateCard: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(spacing: 16) {
                Image(systemName: icon)
                    .font(.system(size: 56, weight: .light))
                    .foregroundColor(AppColors.secondaryText)
                
                Text(title)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(AppColors.primaryText)
                
                Text(message)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .padding(32)
        }
    }
}
