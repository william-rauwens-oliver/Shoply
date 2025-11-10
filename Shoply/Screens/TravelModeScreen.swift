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
    @State private var showingDeleteAllAlert = false
    @State private var selectedPlan: TravelPlan?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if travelService.travelPlans.isEmpty {
                    EmptyTravelStateView {
                            showingAddPlan = true
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(travelService.travelPlans) { plan in
                                TravelPlanCard(plan: plan) {
                                    selectedPlan = plan
                                }
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Mode Voyage".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Mode Voyage".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButtonWithLongPress()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        if !travelService.travelPlans.isEmpty {
                            Menu {
                                Button(role: .destructive, action: {
                                    showingDeleteAllAlert = true
                                }) {
                                    Label("Tout supprimer".localized, systemImage: "trash")
                                }
                            } label: {
                                Image(systemName: "ellipsis.circle")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppColors.primaryText)
                            }
                        }
                        
                    Button {
                        showingAddPlan = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.primaryText)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddPlan) {
                AddTravelPlanScreen()
            }
            .sheet(item: $selectedPlan) { plan in
                TravelPlanDetailScreen(plan: plan)
            }
            .alert("Supprimer tous les voyages".localized, isPresented: $showingDeleteAllAlert) {
                Button("Annuler".localized, role: .cancel) { }
                Button("Supprimer tout".localized, role: .destructive) {
                    travelService.deleteAllTravelPlans()
                }
            } message: {
                Text("Êtes-vous sûr de vouloir supprimer tous les voyages ? Cette action est irréversible.".localized)
            }
            .onAppear {
                travelService.removeExpiredPlans()
            }
        }
    }
}

// MARK: - État Vide

struct EmptyTravelStateView: View {
    let onCreate: () -> Void
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    AppColors.buttonPrimary.opacity(0.15),
                                    AppColors.buttonPrimary.opacity(0.05)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 120, height: 120)
                    
                    Image(systemName: "airplane")
                        .font(.system(size: 50, weight: .light))
                        .foregroundColor(AppColors.buttonPrimary)
                }
                
                VStack(spacing: 12) {
                    Text("Aucun voyage planifié".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                    
                    Text("Créez un plan de voyage pour organiser vos outfits et obtenir une checklist personnalisée".localized)
                        .font(DesignSystem.Typography.body())
                        .foregroundColor(AppColors.secondaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            }
            
            Button(action: onCreate) {
                HStack(spacing: 12) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                    Text("Créer un plan de voyage".localized)
                        .font(DesignSystem.Typography.headline())
                }
                .foregroundColor(AppColors.buttonPrimaryText)
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(AppColors.buttonPrimary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
            }
            
            Spacer()
        }
    }
}

// MARK: - Carte de Plan de Voyage

struct TravelPlanCard: View {
    let plan: TravelPlan
    let onTap: () -> Void
    @StateObject private var travelService = TravelModeService.shared
    @State private var showingDeleteAlert = false
    @State private var isPressed = false
    
    private var completedItems: Int {
        plan.checklist.filter { $0.isChecked }.count
    }
    
    private var totalItems: Int {
        plan.checklist.count
    }
    
    var body: some View {
        Button(action: onTap) {
        Card(cornerRadius: DesignSystem.Radius.lg) {
                VStack(alignment: .leading, spacing: 16) {
                    // En-tête
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
                                .frame(width: 56, height: 56)
                        
                        Image(systemName: "airplane")
                                .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(AppColors.buttonPrimary)
                    }
                    
                        VStack(alignment: .leading, spacing: 6) {
                        Text(plan.destination)
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(AppColors.primaryText)
                        
                            HStack(spacing: 8) {
                            Text(plan.startDate, style: .date)
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(AppColors.secondaryText)
                            
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppColors.secondaryText)
                            
                            Text(plan.endDate, style: .date)
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                    
                    Spacer()
                    
                        VStack(alignment: .trailing, spacing: 8) {
                    Text("\(plan.duration) jours".localized)
                        .font(DesignSystem.Typography.footnote())
                        .foregroundColor(AppColors.secondaryText)
                                .fontWeight(.semibold)
                            
                            Button {
                                showingDeleteAlert = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.red)
                                    .frame(width: 32, height: 32)
                                    .background(Circle().fill(AppColors.buttonSecondary))
                            }
                        }
                }
                
                // Progression checklist
                if totalItems > 0 {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Checklist".localized)
                                    .font(DesignSystem.Typography.footnote())
                                    .foregroundColor(AppColors.secondaryText)
                                
                                Spacer()
                                
                                Text("\(completedItems)/\(totalItems)")
                                    .font(DesignSystem.Typography.footnote())
                                    .foregroundColor(AppColors.buttonPrimary)
                                    .fontWeight(.semibold)
                            }
                            
                        ProgressView(value: Double(completedItems), total: Double(totalItems))
                            .tint(AppColors.buttonPrimary)
                                .scaleEffect(x: 1, y: 1.5, anchor: .center)
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.secondaryText)
                        
                            Text("Checklist en cours de génération...".localized)
                                .font(DesignSystem.Typography.footnote())
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
            }
                .padding(20)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
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

// MARK: - Écran de Détail

struct TravelPlanDetailScreen: View {
    let plan: TravelPlan
    @StateObject private var travelService = TravelModeService.shared
    @State private var showingDeleteAlert = false
    @Environment(\.dismiss) var dismiss
    
    private var currentPlan: TravelPlan? {
        travelService.travelPlans.first { $0.id == plan.id }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if let currentPlan = currentPlan {
                    ScrollViewReader { proxy in
                        ScrollView(showsIndicators: false) {
                            VStack(spacing: 24) {
                                // En-tête moderne avec destination
                                ModernTravelHeader(plan: currentPlan)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 20)
                                
                                // Checklist en premier
                                ChecklistSection(plan: currentPlan, travelService: travelService)
                                    .padding(.horizontal, 20)
                                    .id("checklist")
                                
                                // Informations du voyage
                                TravelInfoSection(plan: currentPlan)
                                    .padding(.horizontal, 20)
                            }
                            .padding(.bottom, 20)
                        }
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                withAnimation(.easeInOut(duration: 0.6)) {
                                    proxy.scrollTo("checklist", anchor: .top)
                                }
                            }
                        }
                        .onChange(of: travelService.travelPlans) { oldValue, newValue in
                            if let updatedPlan = newValue.first(where: { $0.id == plan.id }),
                               !updatedPlan.checklist.isEmpty {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                    withAnimation(.easeInOut(duration: 0.5)) {
                                        proxy.scrollTo("checklist", anchor: .top)
                                    }
                                }
                            }
                        }
                    }
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
                
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButtonWithLongPress()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if currentPlan != nil {
                        Button {
                            showingDeleteAlert = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .alert("Supprimer le plan".localized, isPresented: $showingDeleteAlert) {
                Button("Annuler".localized, role: .cancel) { }
                Button("Supprimer".localized, role: .destructive) {
                    if let currentPlan = currentPlan {
                        travelService.deleteTravelPlan(currentPlan)
                        dismiss()
                    }
                }
            } message: {
                Text("Êtes-vous sûr de vouloir supprimer ce plan de voyage ?".localized)
            }
        }
    }
}

// MARK: - En-tête Moderne

struct ModernTravelHeader: View {
    let plan: TravelPlan
    
    var body: some View {
        VStack(spacing: 0) {
            // Icône et destination
            HStack(spacing: 20) {
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
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
                        .frame(width: 80, height: 80)
                        .overlay {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(AppColors.buttonPrimary.opacity(0.3), lineWidth: 1.5)
                        }
                    
                    Image(systemName: "airplane")
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundColor(AppColors.buttonPrimary)
                }
                
                VStack(alignment: .leading, spacing: 10) {
                    Text(plan.destination)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(AppColors.primaryText)
                    
                    HStack(spacing: 10) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.secondaryText)
                            
                            Text(plan.startDate, style: .date)
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(AppColors.secondaryText)
                        }
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppColors.secondaryText.opacity(0.6))
                        
                        Text(plan.endDate, style: .date)
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                
                Spacer()
            }
            .padding(24)
        }
        .liquidGlassCard(cornerRadius: DesignSystem.Radius.xl)
    }
}

// MARK: - Section Checklist

struct ChecklistSection: View {
    let plan: TravelPlan
    @ObservedObject var travelService: TravelModeService
    
    private var completedCount: Int {
        plan.checklist.filter { $0.isChecked }.count
    }
    
    private var progress: Double {
        guard !plan.checklist.isEmpty else { return 0 }
        return Double(completedCount) / Double(plan.checklist.count)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // En-tête de la checklist
            HStack(alignment: .center, spacing: 16) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(AppColors.buttonPrimary.opacity(0.15))
                            .frame(width: 48, height: 48)
                        
                        Image(systemName: "checklist")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(AppColors.buttonPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Checklist Shoply AI".localized)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppColors.primaryText)
                        
                        if !plan.checklist.isEmpty {
                            Text("\(completedCount) sur \(plan.checklist.count) complétés".localized)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                }
                
                Spacer()
                
                if !plan.checklist.isEmpty {
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .stroke(AppColors.buttonPrimary.opacity(0.15), lineWidth: 5)
                                .frame(width: 56, height: 56)
                            
                            Circle()
                                .trim(from: 0, to: progress)
                                .stroke(
                                    LinearGradient(
                                        colors: [AppColors.buttonPrimary, AppColors.buttonPrimary.opacity(0.7)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    style: StrokeStyle(lineWidth: 5, lineCap: .round)
                                )
                                .frame(width: 56, height: 56)
                                .rotationEffect(.degrees(-90))
                                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                            
                            Text("\(Int(progress * 100))%")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(AppColors.buttonPrimary)
                        }
                    }
                }
            }
            .padding(24)
            
            if plan.checklist.isEmpty {
                VStack(spacing: 20) {
                    AIThinkingAnimation(message: "Génération de la checklist par Shoply AI".localized)
                        .frame(height: 100)
                    
                    VStack(spacing: 8) {
                        Text("Shoply AI analyse votre destination".localized)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(AppColors.primaryText)
                            .fontWeight(.medium)
                        
                        Text("Les dates, la météo et votre profil sont analysés par Shoply AI pour créer une checklist personnalisée".localized)
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .lineLimit(3)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 0) {
                    Rectangle()
                        .fill(AppColors.separator.opacity(0.3))
                        .frame(height: 1)
                        .padding(.horizontal, 24)
                    
                    VStack(spacing: 0) {
                        ForEach(Array(plan.checklist.enumerated()), id: \.element.id) { index, item in
                            ChecklistItemRow(
                                item: item,
                                plan: plan,
                                travelService: travelService
                            )
                            
                            if index < plan.checklist.count - 1 {
                                Rectangle()
                                    .fill(AppColors.separator.opacity(0.2))
                                    .frame(height: 1)
                                    .padding(.leading, 68)
                            }
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .liquidGlassCard(cornerRadius: DesignSystem.Radius.xl)
    }
}

struct ChecklistItemRow: View {
    let item: TravelChecklistItem
    let plan: TravelPlan
    @ObservedObject var travelService: TravelModeService
    @State private var isPressed = false
    
    var body: some View {
        Button {
            if let index = plan.checklist.firstIndex(where: { $0.id == item.id }) {
                var updatedPlan = plan
                updatedPlan.checklist[index].isChecked.toggle()
                travelService.updateTravelPlan(updatedPlan)
            }
        } label: {
            HStack(spacing: 16) {
                // Checkbox moderne
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(item.isChecked ? AppColors.buttonPrimary.opacity(0.2) : AppColors.buttonSecondary.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .overlay {
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(item.isChecked ? AppColors.buttonPrimary.opacity(0.5) : AppColors.separator.opacity(0.5), lineWidth: 1.5)
                        }
                    
                    if item.isChecked {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColors.buttonPrimary)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                
                // Contenu
                VStack(alignment: .leading, spacing: 6) {
                    Text(item.item)
                        .font(.system(size: 16, weight: item.isChecked ? .medium : .regular))
                        .foregroundColor(item.isChecked ? AppColors.secondaryText : AppColors.primaryText)
                        .strikethrough(item.isChecked)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                    
                    if let quantity = item.quantity, quantity > 1 {
                        HStack(spacing: 6) {
                            Image(systemName: "number.circle.fill")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppColors.buttonPrimary.opacity(0.7))
                            Text("Quantité: \(quantity)".localized)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .background(
                item.isChecked ? AppColors.buttonPrimary.opacity(0.05) : Color.clear
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Section Informations

struct TravelInfoSection: View {
    let plan: TravelPlan
    
    private var avgTemperature: Double {
        guard !plan.weatherForecast.isEmpty else { return 0 }
        return plan.weatherForecast.map { $0.temperature }.reduce(0, +) / Double(plan.weatherForecast.count)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Titre de section
            HStack {
                Text("Informations du voyage".localized)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(AppColors.primaryText)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
            
            // Cartes d'informations
            HStack(spacing: 12) {
                // Durée
                InfoCard(
                    icon: "calendar",
                    title: "Durée".localized,
                    value: "\(plan.duration) jours".localized,
                    color: AppColors.buttonPrimary
                )
                
                // Météo
                if !plan.weatherForecast.isEmpty {
                    InfoCard(
                        icon: "thermometer",
                        title: "Météo".localized,
                        value: "\(Int(avgTemperature))°C",
                        color: .orange
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
}

struct InfoCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 48, height: 48)
                
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(color)
            }
            
            VStack(spacing: 4) {
                Text(title)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(AppColors.secondaryText)
                
                Text(value)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(AppColors.primaryText)
                    .fontWeight(.semibold)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .liquidGlassCard(cornerRadius: DesignSystem.Radius.lg)
    }
}

// MARK: - Écran d'Ajout

struct AddTravelPlanScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var travelService = TravelModeService.shared
    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
    @State private var isCreating = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if isCreating {
                    VStack(spacing: 24) {
                        AIThinkingAnimation(message: "Création du plan de voyage...".localized)
                        
                        Text("Shoply AI génère votre checklist personnalisée".localized)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Destination
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                                VStack(alignment: .leading, spacing: 12) {
                                Text("Destination".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                TextField("Ville, pays ou quartier".localized, text: $destination)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.primaryText)
                                        .padding(16)
                                        .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                            }
                                .padding(20)
                        }
                            .padding(.horizontal, 20)
                        
                            // Dates
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                                VStack(alignment: .leading, spacing: 16) {
                                Text("Dates".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                DatePicker("Date de départ".localized, selection: $startDate, displayedComponents: .date)
                                    .font(DesignSystem.Typography.body())
                                
                                DatePicker("Date de retour".localized, selection: $endDate, displayedComponents: .date)
                                    .font(DesignSystem.Typography.body())
                            }
                                .padding(20)
                        }
                            .padding(.horizontal, 20)
                        }
                        .padding(.vertical, 20)
                                    }
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
                
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButtonWithLongPress()
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer".localized) {
                        createTravelPlan()
                    }
                    .disabled(destination.isEmpty || isCreating)
                    .foregroundColor(destination.isEmpty ? AppColors.secondaryText : AppColors.buttonPrimary)
                }
            }
        }
    }
    
    private func createTravelPlan() {
        guard !destination.isEmpty else { return }
        guard startDate <= endDate else { return }
        
        isCreating = true
        
        Task {
            _ = travelService.createTravelPlan(
                    destination: destination,
                    startDate: startDate,
                endDate: endDate
                )
            
                await MainActor.run {
                isCreating = false
                dismiss()
            }
        }
    }
}
