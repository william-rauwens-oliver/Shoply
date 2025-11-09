//
//  TravelModeScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct TravelModeScreen: View {
    @StateObject private var travelService = TravelModeService.shared
    @State private var showingAddPlan = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if travelService.travelPlans.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Image(systemName: "airplane")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text("Aucun voyage planifié".localized)
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("Créez un plan de voyage pour organiser vos outfits".localized)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        Button {
                            showingAddPlan = true
                        } label: {
                            Text("Créer un plan".localized)
                                .font(DesignSystem.Typography.headline())
                                .foregroundColor(AppColors.buttonPrimaryText)
                                .padding(.horizontal, DesignSystem.Spacing.lg)
                                .padding(.vertical, DesignSystem.Spacing.md)
                                .background(AppColors.buttonPrimary)
                                .cornerRadius(DesignSystem.Radius.md)
                        }
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: DesignSystem.Spacing.md) {
                            ForEach(travelService.travelPlans) { plan in
                                NavigationLink(destination: TravelPlanDetailScreen(plan: plan)) {
                                    TravelPlanCard(plan: plan)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                    }
                }
            }
            .navigationTitle("Mode Voyage".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Mode Voyage".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddPlan = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.primaryText)
                    }
                }
            }
            .sheet(isPresented: $showingAddPlan) {
                AddTravelPlanScreen()
            }
        }
    }
}

struct TravelPlanCard: View {
    let plan: TravelPlan
    @StateObject private var travelService = TravelModeService.shared
    @State private var showingDeleteAlert = false
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                HStack {
                    ZStack {
                        Circle()
                            .fill(AppColors.buttonPrimary.opacity(0.15))
                            .frame(width: 40, height: 40)
                        
                        Image(systemName: "airplane")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.buttonPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        Text(plan.destination)
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(AppColors.primaryText)
                        
                        HStack(spacing: DesignSystem.Spacing.xs) {
                            Text(plan.startDate, style: .date)
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(AppColors.secondaryText)
                            
                            Text("→")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(AppColors.secondaryText)
                            
                            Text(plan.endDate, style: .date)
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                    Text("\(plan.duration) jours".localized)
                        .font(DesignSystem.Typography.footnote())
                        .foregroundColor(AppColors.secondaryText)
                }
                
                // Progression checklist
                let completedItems = plan.checklist.filter { $0.isChecked }.count
                let totalItems = plan.checklist.count
                if totalItems > 0 {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        ProgressView(value: Double(completedItems), total: Double(totalItems))
                            .tint(AppColors.buttonPrimary)
                        
                        Text("\(completedItems)/\(totalItems) items".localized)
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
            .padding(DesignSystem.Spacing.sm)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                showingDeleteAlert = true
            } label: {
                Label("Supprimer".localized, systemImage: "trash")
            }
        }
        .alert("Supprimer le plan".localized, isPresented: $showingDeleteAlert) {
            Button("Annuler".localized, role: .cancel) { }
            Button("Supprimer".localized, role: .destructive) {
                travelService.deleteTravelPlan(plan)
            }
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer ce plan de voyage ?".localized)
        }
    }
}

struct TravelPlanDetailScreen: View {
    let plan: TravelPlan
    @StateObject private var travelService = TravelModeService.shared
    @State private var showingSuggestions = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        // En-tête
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text(plan.destination)
                                    .font(DesignSystem.Typography.title2())
                                    .foregroundColor(AppColors.primaryText)
                                
                                HStack(spacing: DesignSystem.Spacing.xs) {
                                    Text(plan.startDate, style: .date)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(AppColors.secondaryText)
                                    
                                    Text("→")
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(AppColors.secondaryText)
                                    
                                    Text(plan.endDate, style: .date)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(AppColors.secondaryText)
                                }
                            }
                            .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        // Bouton suggestions
                        Button {
                            showingSuggestions = true
                        } label: {
                            HStack {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Suggérer des outfits".localized)
                                    .font(DesignSystem.Typography.headline())
                            }
                            .foregroundColor(AppColors.buttonPrimaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, DesignSystem.Spacing.md)
                            .background(AppColors.buttonPrimary)
                            .cornerRadius(DesignSystem.Radius.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        // Checklist
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("Checklist".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                ForEach(plan.checklist) { item in
                                    ChecklistItemRow(
                                        item: item,
                                        onToggle: {
                                            travelService.toggleChecklistItem(planId: plan.id, itemId: item.id)
                                        }
                                    )
                                }
                            }
                            .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        // Outfits planifiés
                        if !plan.plannedOutfits.isEmpty {
                            Card(cornerRadius: DesignSystem.Radius.lg) {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                    Text("Outfits planifiés".localized)
                                        .font(DesignSystem.Typography.headline())
                                        .foregroundColor(AppColors.primaryText)
                                    
                                    ForEach(plan.plannedOutfits) { outfit in
                                        PlannedOutfitRow(outfit: outfit)
                                    }
                                }
                                .padding(DesignSystem.Spacing.md)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Plan de voyage".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Plan de voyage".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
            }
            .sheet(isPresented: $showingSuggestions) {
                TravelOutfitSuggestionsScreen(plan: plan)
            }
        }
    }
}

struct ChecklistItemRow: View {
    let item: TravelChecklistItem
    let onToggle: () -> Void
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.md) {
            Button {
                onToggle()
            } label: {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(item.isChecked ? .green : AppColors.secondaryText)
            }
            
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                Text(item.item)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(AppColors.primaryText)
                    .strikethrough(item.isChecked)
                
                if let quantity = item.quantity {
                    Text("Quantité: \(quantity)".localized)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            
            Spacer()
            
            Image(systemName: item.category.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppColors.buttonPrimary)
        }
    }
}

struct PlannedOutfitRow: View {
    let outfit: PlannedOutfit
    
    var body: some View {
        VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
            Text(outfit.date, style: .date)
                .font(DesignSystem.Typography.headline())
                .foregroundColor(AppColors.primaryText)
            
            if let occasion = outfit.occasion {
                Text(occasion)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(AppColors.secondaryText)
            }
            
            if let notes = outfit.notes {
                Text(notes)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(AppColors.buttonPrimary)
            }
        }
        .padding(DesignSystem.Spacing.sm)
        .background(AppColors.cardBackground)
        .cornerRadius(DesignSystem.Radius.sm)
    }
}

struct AddTravelPlanScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var travelService = TravelModeService.shared
    @StateObject private var geminiService = GeminiService.shared
    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var geminiAdvice: String?
    @State private var isLoadingAdvice = false
    
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
                                Text("Destination".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                TextField("Ville, pays ou quartier".localized, text: $destination)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.primaryText)
                                    .padding(DesignSystem.Spacing.md)
                                    .background(AppColors.cardBackground)
                                    .cornerRadius(DesignSystem.Radius.sm)
                            }
                            .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("Dates".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                DatePicker("Date de départ".localized, selection: $startDate, displayedComponents: .date)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.primaryText)
                                
                                DatePicker("Date de retour".localized, selection: $endDate, displayedComponents: .date)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.primaryText)
                            }
                            .padding(DesignSystem.Spacing.md)
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        
                        if !destination.isEmpty && endDate > startDate {
                            Card(cornerRadius: DesignSystem.Radius.lg) {
                                VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                    Text("Conseils Gemini".localized)
                                        .font(DesignSystem.Typography.headline())
                                        .foregroundColor(AppColors.primaryText)
                                    
                                    if isLoadingAdvice {
                                        ProgressView()
                                            .frame(maxWidth: .infinity)
                                    } else if let advice = geminiAdvice {
                                        Text(advice)
                                            .font(DesignSystem.Typography.body())
                                            .foregroundColor(AppColors.primaryText)
                                    } else {
                                        Button("Obtenir des conseils de voyage".localized) {
                                            loadTravelAdvice()
                                        }
                                        .font(DesignSystem.Typography.headline())
                                        .foregroundColor(AppColors.buttonPrimaryText)
                                        .padding(.vertical, DesignSystem.Spacing.sm)
                                        .frame(maxWidth: .infinity)
                                        .background(AppColors.buttonPrimary)
                                        .cornerRadius(DesignSystem.Radius.sm)
                                    }
                                }
                                .padding(DesignSystem.Spacing.md)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                    }
                    .padding(.vertical, DesignSystem.Spacing.lg)
                }
            }
            .navigationTitle("Nouveau voyage".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Nouveau voyage".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler".localized) { dismiss() }
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer".localized) {
                        let plan = travelService.createTravelPlan(
                            destination: destination,
                            startDate: startDate,
                            endDate: endDate
                        )
                        if let advice = geminiAdvice {
                            var updatedPlan = plan
                            updatedPlan.notes = advice
                            travelService.updateTravelPlan(updatedPlan)
                        }
                        dismiss()
                    }
                    .disabled(destination.isEmpty || endDate <= startDate)
                    .foregroundColor((destination.isEmpty || endDate <= startDate) ? AppColors.secondaryText : AppColors.buttonPrimary)
                }
            }
        }
    }
    
    private func loadTravelAdvice() {
        guard !destination.isEmpty else { return }
        isLoadingAdvice = true
        
        Task {
            do {
                let advice = try await geminiService.generateTravelAdvice(
                    destination: destination,
                    startDate: startDate,
                    endDate: endDate,
                    userProfile: userProfile
                )
                await MainActor.run {
                    geminiAdvice = advice
                    isLoadingAdvice = false
                }
            } catch {
                await MainActor.run {
                    isLoadingAdvice = false
                }
            }
        }
    }
}

struct TravelOutfitSuggestionsScreen: View {
    let plan: TravelPlan
    @StateObject private var travelService = TravelModeService.shared
    @Environment(\.dismiss) var dismiss
    @State private var suggestions: [PlannedOutfit] = []
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.lg) {
                        Text("Suggestions d'outfits pour votre voyage".localized)
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(AppColors.primaryText)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.top, DesignSystem.Spacing.md)
                        
                        if suggestions.isEmpty {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                                .padding(DesignSystem.Spacing.xl)
                        } else {
                            ForEach(suggestions) { outfit in
                                PlannedOutfitRow(outfit: outfit)
                                    .padding(.horizontal, DesignSystem.Spacing.md)
                            }
                        }
                    }
                    .padding(.bottom, DesignSystem.Spacing.lg)
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
                suggestions = travelService.suggestOutfitsForTravel(plan: plan)
            }
        }
    }
}
