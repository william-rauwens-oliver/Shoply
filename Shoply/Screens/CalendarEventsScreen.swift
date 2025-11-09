//
//  CalendarEventsScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import EventKit

struct CalendarEventsScreen: View {
    @State private var events: [CalendarEvent] = []
    @State private var showingPermissionRequest = false
    @State private var hasCalendarAccess = false
    
    var upcomingEvents: [CalendarEvent] {
        events.filter { $0.startDate >= Date() }
            .sorted { $0.startDate < $1.startDate }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if !hasCalendarAccess {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Image(systemName: "calendar.badge.exclamationmark")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text("Accès au calendrier requis".localized)
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("Autorisez l'accès à votre calendrier pour obtenir des suggestions d'outfits basées sur vos événements".localized)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                        
                        Button {
                            requestCalendarAccess()
                        } label: {
                            HStack {
                                Image(systemName: "lock.open")
                                    .font(.system(size: 18, weight: .medium))
                                Text("Autoriser l'accès".localized)
                                    .font(DesignSystem.Typography.headline())
                            }
                            .foregroundColor(AppColors.buttonPrimaryText)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                            .padding(.vertical, DesignSystem.Spacing.md)
                            .background(AppColors.buttonPrimary)
                            .cornerRadius(DesignSystem.Radius.md)
                        }
                    }
                } else if upcomingEvents.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Image(systemName: "calendar")
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text("Aucun événement à venir".localized)
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(AppColors.primaryText)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: DesignSystem.Spacing.md) {
                            ForEach(upcomingEvents) { event in
                                NavigationLink(destination: EventOutfitSuggestionScreen(event: event)) {
                                    CalendarEventCard(event: event)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                    }
                }
            }
            .navigationTitle("Événements".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Événements".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
            }
            .onAppear {
                checkCalendarAccess()
                if hasCalendarAccess {
                    loadEvents()
                }
            }
        }
    }
    
    private func checkCalendarAccess() {
        let status = EKEventStore.authorizationStatus(for: .event)
        if #available(iOS 17.0, *) {
            hasCalendarAccess = status == .fullAccess
        } else {
            hasCalendarAccess = status == .authorized
        }
    }
    
    private func requestCalendarAccess() {
        let eventStore = EKEventStore()
        if #available(iOS 17.0, *) {
            eventStore.requestFullAccessToEvents { granted, error in
                DispatchQueue.main.async {
                    hasCalendarAccess = granted
                    if granted {
                        loadEvents()
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    hasCalendarAccess = granted
                    if granted {
                        loadEvents()
                    }
                }
            }
        }
    }
    
    private func loadEvents() {
        // Charger les événements du calendrier
        // Pour l'instant, données de test
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        events = [
            CalendarEvent(
                id: "1",
                title: "Entretien d'embauche".localized,
                startDate: tomorrow,
                endDate: Calendar.current.date(byAdding: .hour, value: 1, to: tomorrow) ?? tomorrow,
                eventType: .interview
            ),
            CalendarEvent(
                id: "2",
                title: "Dîner entre amis".localized,
                startDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date(),
                endDate: Calendar.current.date(byAdding: .hour, value: 3, to: Calendar.current.date(byAdding: .day, value: 3, to: Date()) ?? Date()) ?? Date(),
                eventType: .casual
            )
        ]
    }
}

struct CalendarEventCard: View {
    let event: CalendarEvent
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            HStack(spacing: DesignSystem.Spacing.md) {
                VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                    Text(event.title)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.primaryText)
                    
                    Text(event.startDate, style: .date)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text(event.eventType.rawValue.localized)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.buttonPrimary)
                        .padding(.horizontal, DesignSystem.Spacing.sm)
                        .padding(.vertical, DesignSystem.Spacing.xs)
                        .background(AppColors.buttonPrimary.opacity(0.15))
                        .cornerRadius(DesignSystem.Radius.sm)
                }
                
                Spacer()
                
                if event.suggestedOutfit != nil {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(.green)
                } else {
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(AppColors.buttonPrimary)
                }
            }
            .padding(DesignSystem.Spacing.sm)
        }
    }
}

struct EventOutfitSuggestionScreen: View {
    let event: CalendarEvent
    @StateObject private var wardrobeService = WardrobeService()
    @StateObject private var geminiService = GeminiService.shared
    @StateObject private var weatherService = WeatherService.shared
    @State private var geminiSuggestions: [String] = []
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
                                Text(event.title)
                                    .font(DesignSystem.Typography.title2())
                                    .foregroundColor(AppColors.primaryText)
                                
                                Text("Type: \(event.eventType.rawValue.localized)")
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.secondaryText)
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
                        } else if !geminiSuggestions.isEmpty {
                            VStack(alignment: .leading, spacing: DesignSystem.Spacing.md) {
                                Text("Suggestions Gemini".localized)
                                    .font(DesignSystem.Typography.title2())
                                    .foregroundColor(AppColors.primaryText)
                                    .padding(.horizontal, DesignSystem.Spacing.md)
                                
                                ForEach(Array(geminiSuggestions.enumerated()), id: \.offset) { index, suggestion in
                                    Card(cornerRadius: DesignSystem.Radius.lg) {
                                        VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                                            Text("Style \(index + 1)".localized)
                                                .font(DesignSystem.Typography.headline())
                                                .foregroundColor(AppColors.buttonPrimary)
                                            
                                            Text(suggestion)
                                                .font(DesignSystem.Typography.body())
                                                .foregroundColor(AppColors.primaryText)
                                        }
                                        .padding(DesignSystem.Spacing.md)
                                    }
                                    .padding(.horizontal, DesignSystem.Spacing.md)
                                }
                            }
                        } else {
                            Button {
                                generateSuggestions()
                            } label: {
                                HStack {
                                    Image(systemName: "sparkles")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Générer des suggestions avec Gemini".localized)
                                        .font(DesignSystem.Typography.headline())
                                }
                                .foregroundColor(AppColors.buttonPrimaryText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, DesignSystem.Spacing.md)
                                .background(AppColors.buttonPrimary)
                                .cornerRadius(DesignSystem.Radius.md)
                            }
                            .padding(.horizontal, DesignSystem.Spacing.md)
                        }
                    }
                    .padding(.bottom, DesignSystem.Spacing.xl)
                }
            }
            .navigationTitle("Suggestion".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Suggestion".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
            }
            .onAppear {
                if geminiSuggestions.isEmpty {
                    generateSuggestions()
                }
            }
        }
    }
    
    private func generateSuggestions() {
        isLoading = true
        error = nil
        
        Task {
            do {
                let suggestions = try await geminiService.generateEventOutfitSuggestions(
                    event: event,
                    userProfile: userProfile,
                    wardrobeItems: wardrobeService.items,
                    weather: weatherService.currentWeather
                )
                await MainActor.run {
                    geminiSuggestions = suggestions
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
