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
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // Tabs
                        Picker("", selection: $selectedTab) {
                            Text("Style".localized).tag(0)
                            Text("Environnement".localized).tag(1)
                            Text("Coût".localized).tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.top, DesignSystem.Spacing.md)
                        
                        // Contenu selon le tab
                        Group {
                            if selectedTab == 0 {
                                styleStatisticsView
                            } else if selectedTab == 1 {
                                environmentalView
                            } else {
                                costView
                            }
                        }
                    }
                    .padding(.bottom, DesignSystem.Spacing.xl)
                }
            }
            .navigationTitle("Statistiques".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Statistiques".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
            }
            .onAppear {
                loadStatistics()
            }
        }
    }
    
    private var styleStatisticsView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Cartes de résumé
            HStack(spacing: DesignSystem.Spacing.md) {
                StatCard(
                    title: "Vêtements".localized,
                    value: "\(statistics.totalItems)",
                    icon: "tshirt.fill",
                    color: AppColors.buttonPrimary
                )
                
                StatCard(
                    title: "Outfits".localized,
                    value: "\(statistics.totalOutfits)",
                    icon: "sparkles",
                    color: AppColors.buttonPrimary
                )
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            
            // Couleurs les plus portées
            if !statistics.mostWornColors.isEmpty {
                Card(cornerRadius: DesignSystem.Radius.lg) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Couleurs les plus portées".localized)
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(AppColors.primaryText)
                        
                        ForEach(statistics.mostWornColors.prefix(5)) { colorFreq in
                            ColorFrequencyRow(colorFreq: colorFreq)
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
            
            // Catégories les plus portées
            if !statistics.mostWornCategories.isEmpty {
                Card(cornerRadius: DesignSystem.Radius.lg) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                        Text("Catégories les plus portées".localized)
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(AppColors.primaryText)
                        
                        ForEach(statistics.mostWornCategories.prefix(5)) { categoryFreq in
                            CategoryFrequencyRow(categoryFreq: categoryFreq)
                        }
                    }
                    .padding(DesignSystem.Spacing.md)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
            
            // Niveaux moyens
            HStack(spacing: DesignSystem.Spacing.md) {
                Card(cornerRadius: DesignSystem.Radius.lg) {
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text("Confort moyen".localized)
                            .font(DesignSystem.Typography.footnote())
                            .foregroundColor(AppColors.secondaryText)
                        Text(String(format: "%.1f", statistics.averageComfortLevel))
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(AppColors.buttonPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.md)
                }
                
                Card(cornerRadius: DesignSystem.Radius.lg) {
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text("Style moyen".localized)
                            .font(DesignSystem.Typography.footnote())
                            .foregroundColor(AppColors.secondaryText)
                        Text(String(format: "%.1f", statistics.averageStyleLevel))
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(AppColors.buttonPrimary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(DesignSystem.Spacing.md)
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }
    
    private var environmentalView: some View {
        VStack(spacing: DesignSystem.Spacing.lg) {
            // Score de durabilité
            Card(cornerRadius: DesignSystem.Radius.lg) {
                VStack(spacing: DesignSystem.Spacing.md) {
                    Text("Score de Durabilité".localized)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.primaryText)
                    
                    ZStack {
                        Circle()
                            .stroke(AppColors.cardBorder, lineWidth: 20)
                            .frame(width: 150, height: 150)
                        
                        Circle()
                            .trim(from: 0, to: environmentalImpact.sustainabilityScore / 100)
                            .stroke(AppColors.buttonPrimary, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                            .frame(width: 150, height: 150)
                            .rotationEffect(.degrees(-90))
                        
                        VStack(spacing: DesignSystem.Spacing.xs) {
                            Text("\(Int(environmentalImpact.sustainabilityScore))")
                                .font(.system(size: 40, weight: .bold))
                                .foregroundColor(AppColors.primaryText)
                            Text("/ 100")
                                .font(DesignSystem.Typography.footnote())
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                }
                .padding(DesignSystem.Spacing.lg)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            
            // Statistiques environnementales
            Card(cornerRadius: DesignSystem.Radius.lg) {
                VStack(spacing: DesignSystem.Spacing.md) {
                    EnvStatRow(title: "Vêtements portés ce mois".localized, value: "\(environmentalImpact.itemsWornThisMonth)")
                    EnvStatRow(title: "Port moyen par vêtement".localized, value: String(format: "%.1f", environmentalImpact.averageWearPerItem))
                    EnvStatRow(title: "Non portés (30 jours)".localized, value: "\(environmentalImpact.itemsNotWornIn30Days)")
                    EnvStatRow(title: "Réduction CO₂ (kg)".localized, value: String(format: "%.1f", environmentalImpact.carbonFootprintReduction))
                }
                .padding(DesignSystem.Spacing.md)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }
    
    private var costView: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            if costPerWear.isEmpty {
                Card(cornerRadius: DesignSystem.Radius.lg) {
                    VStack(spacing: DesignSystem.Spacing.md) {
                        Image(systemName: "dollarsign.circle")
                            .font(.system(size: 48, weight: .light))
                            .foregroundColor(AppColors.secondaryText)
                        Text("Aucun prix renseigné".localized)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(AppColors.secondaryText)
                    }
                    .padding(DesignSystem.Spacing.xl)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
            } else {
                ForEach(costPerWear.sorted(by: { ($0.costPerWear ?? 0) < ($1.costPerWear ?? 0) })) { cost in
                    CostPerWearRow(cost: cost)
                        .padding(.horizontal, DesignSystem.Spacing.md)
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

// MARK: - Composants

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(spacing: DesignSystem.Spacing.sm) {
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
                
                Text(title)
                    .font(DesignSystem.Typography.footnote())
                    .foregroundColor(AppColors.secondaryText)
            }
            .frame(maxWidth: .infinity)
            .padding(DesignSystem.Spacing.md)
        }
    }
}

struct ColorFrequencyRow: View {
    let colorFreq: ColorFrequency
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Circle()
                .fill(colorFromString(colorFreq.color))
                .frame(width: 20, height: 20)
            
            Text(colorFreq.color)
                .font(DesignSystem.Typography.body())
                .foregroundColor(AppColors.primaryText)
            
            Spacer()
            
            Text("\(colorFreq.count) fois".localized)
                .font(DesignSystem.Typography.footnote())
                .foregroundColor(AppColors.secondaryText)
            
            Text("\(Int(colorFreq.percentage))%")
                .font(DesignSystem.Typography.footnote())
                .foregroundColor(AppColors.primaryText)
                .fontWeight(.semibold)
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
        default: return .gray
        }
    }
}

struct CategoryFrequencyRow: View {
    let categoryFreq: CategoryFrequency
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Text(categoryFreq.category)
                .font(DesignSystem.Typography.body())
                .foregroundColor(AppColors.primaryText)
            
            Spacer()
            
            Text("\(categoryFreq.count) fois".localized)
                .font(DesignSystem.Typography.footnote())
                .foregroundColor(AppColors.secondaryText)
            
            Text("\(Int(categoryFreq.percentage))%")
                .font(DesignSystem.Typography.footnote())
                .foregroundColor(AppColors.primaryText)
                .fontWeight(.semibold)
        }
    }
}

struct EnvStatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Text(title)
                .font(DesignSystem.Typography.body())
                .foregroundColor(AppColors.primaryText)
            
            Spacer()
            
            Text(value)
                .font(DesignSystem.Typography.headline())
                .foregroundColor(AppColors.buttonPrimary)
        }
    }
}

struct CostPerWearRow: View {
    let cost: CostPerWear
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            HStack(spacing: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(cost.itemName)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.primaryText)
                    Text("Porté \(cost.wearCount) fois".localized)
                        .font(DesignSystem.Typography.footnote())
                        .foregroundColor(AppColors.secondaryText)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: DesignSystem.Spacing.xs) {
                    if let costPerWear = cost.costPerWear {
                        Text("\(String(format: "%.2f", costPerWear)) €/port")
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(AppColors.buttonPrimary)
                    }
                    if let price = cost.purchasePrice {
                        Text("Acheté \(String(format: "%.2f", price)) €".localized)
                            .font(DesignSystem.Typography.footnote())
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
            .padding(DesignSystem.Spacing.md)
        }
    }
}
