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
                    ModernCalendarPermissionView {
                            requestCalendarAccess()
                    }
                } else if upcomingEvents.isEmpty {
                    ModernEmptyEventsView()
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(upcomingEvents) { event in
                                NavigationLink(destination: EventOutfitSuggestionScreen(event: event)) {
                                    ModernCalendarEventCard(event: event)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Événements".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Événements".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButtonWithLongPress()
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
            // En iOS 17+, utiliser .fullAccess au lieu de .authorized
            hasCalendarAccess = status == .fullAccess
        } else {
            // Pour iOS < 17, utiliser .authorized
            hasCalendarAccess = status == .authorized
        }
    }
    
    private func requestCalendarAccess() {
        let eventStore = EKEventStore()
        if #available(iOS 17.0, *) {
            Task {
                do {
                    let granted = try await eventStore.requestFullAccessToEvents()
                    await MainActor.run {
                    hasCalendarAccess = granted
                    if granted {
                        loadEvents()
                        }
                    }
                } catch {
                    // Si la nouvelle API échoue, on ne peut pas utiliser l'ancienne en fallback
                    // car elle est dépréciée. On affiche juste l'erreur.
                    await MainActor.run {
                        hasCalendarAccess = false
                    }
                }
            }
        } else {
            eventStore.requestAccess(to: .event) { granted, error in
                DispatchQueue.main.async {
                    self.hasCalendarAccess = granted
                    if granted {
                        self.loadEvents()
                    }
                }
            }
        }
    }
    
    private func loadEvents() {
        // Charger les événements du calendrier
        // Logique de chargement...
    }
}

// MARK: - Composants Modernes

struct ModernCalendarPermissionView: View {
    let onRequest: () -> Void
    
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
                
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(AppColors.secondaryText)
            }
            .shadow(color: AppColors.shadow.opacity(0.15), radius: 16, x: 0, y: 6)
            
            VStack(spacing: 12) {
                Text("Accès au calendrier requis".localized)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(AppColors.primaryText)
                
                Text("Autorisez l'accès à votre calendrier pour obtenir des suggestions d'outfits basées sur vos événements".localized)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: onRequest) {
                HStack {
                    Image(systemName: "lock.open")
                        .font(.system(size: 18, weight: .medium))
                    Text("Autoriser l'accès".localized)
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

struct ModernEmptyEventsView: View {
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
                
                Image(systemName: "calendar")
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(AppColors.secondaryText)
            }
            .shadow(color: AppColors.shadow.opacity(0.15), radius: 16, x: 0, y: 6)
            
            VStack(spacing: 12) {
                Text("Aucun événement à venir".localized)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(AppColors.primaryText)
                
                Text("Ajoutez des événements à votre calendrier pour obtenir des suggestions d'outfits".localized)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

struct ModernCalendarEventCard: View {
    let event: CalendarEvent
    @State private var isPressed = false
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            HStack(spacing: 16) {
                ZStack {
                    RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
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
                    
                    Image(systemName: "calendar")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(AppColors.buttonPrimary)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(event.title)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.primaryText)
                    
                    HStack(spacing: 8) {
                    Text(event.startDate, style: .date)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.secondaryText)
                    
                        if event.startDate != event.endDate {
                            Text("→")
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(AppColors.secondaryText)
                            
                            Text(event.endDate, style: .date)
                        .font(DesignSystem.Typography.caption())
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(AppColors.secondaryText)
            }
            .padding(20)
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct EventOutfitSuggestionScreen: View {
    let event: CalendarEvent
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                Text("Suggestions d'outfits pour \(event.title)")
                                        }
            .navigationTitle("Suggestions".localized)
        }
    }
}
