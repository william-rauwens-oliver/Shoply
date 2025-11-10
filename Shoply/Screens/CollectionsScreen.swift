//
//  CollectionsScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct CollectionsScreen: View {
    @StateObject private var collectionService = WardrobeCollectionService.shared
    @StateObject private var wardrobeService = WardrobeService()
    @State private var showingAddCollection = false
    @State private var selectedCollection: WardrobeCollection?
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if collectionService.collections.isEmpty {
                    ModernEmptyCollectionsView {
                        showingAddCollection = true
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ], spacing: 16) {
                            ForEach(collectionService.collections) { collection in
                                NavigationLink(destination: CollectionDetailScreen(collection: collection)) {
                                    ModernCollectionCard(collection: collection)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                            
                            // Bouton ajouter
                            Button(action: { showingAddCollection = true }) {
                                ModernAddCollectionCard()
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                        .padding(20)
                    }
                }
            }
            .navigationTitle("Collections".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Collections".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButtonWithLongPress()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddCollection = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.primaryText)
                    }
                }
            }
            .sheet(isPresented: $showingAddCollection) {
                AddCollectionScreen()
            }
        }
    }
}

// MARK: - Composants Modernes

struct ModernCollectionCard: View {
    let collection: WardrobeCollection
    @State private var isPressed = false
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            VStack(alignment: .leading, spacing: 16) {
                    ZStack {
                        Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    colorFromString(collection.color).opacity(0.2),
                                    colorFromString(collection.color).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 56, height: 56)
                        
                        Image(systemName: collection.icon)
                        .font(.system(size: 26, weight: .semibold))
                            .foregroundColor(colorFromString(collection.color))
                    }
                    
                VStack(alignment: .leading, spacing: 6) {
                Text(collection.name)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(2)
                
                if !collection.description.isEmpty {
                    Text(collection.description)
                        .font(DesignSystem.Typography.caption())
                        .foregroundColor(AppColors.secondaryText)
                        .lineLimit(2)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 160)
            .padding(16)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "gray", "grey": return .gray
        case "pink": return .pink
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "mint": return .mint
        default: return AppColors.buttonPrimary
        }
    }
}

struct ModernAddCollectionCard: View {
    @State private var isPressed = false
    
    var body: some View {
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
                        .frame(width: 56, height: 56)
                    
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundColor(AppColors.buttonPrimary)
                }
                
                Text("Nouvelle collection".localized)
                    .font(DesignSystem.Typography.footnote())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 160)
        }
        .scaleEffect(isPressed ? 0.97 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

struct ModernEmptyCollectionsView: View {
    let onCreate: () -> Void
    
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
                
                Image(systemName: "folder.fill")
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(AppColors.secondaryText)
            }
            .shadow(color: AppColors.shadow.opacity(0.15), radius: 16, x: 0, y: 6)
            
            VStack(spacing: 12) {
                Text("Aucune collection".localized)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(AppColors.primaryText)
                
                Text("Créez des collections pour organiser vos vêtements".localized)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: onCreate) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                    Text("Créer une collection".localized)
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

struct CollectionDetailScreen: View {
    let collection: WardrobeCollection
    @StateObject private var collectionService = WardrobeCollectionService.shared
    @StateObject private var wardrobeService = WardrobeService()
    
    var items: [WardrobeItem] {
        collectionService.getItemsForCollection(collection)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if items.isEmpty {
                    VStack(spacing: DesignSystem.Spacing.lg) {
                        Image(systemName: collection.icon)
                            .font(.system(size: 60, weight: .light))
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text("Aucun vêtement dans cette collection".localized)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, DesignSystem.Spacing.lg)
                    }
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: DesignSystem.Spacing.md),
                            GridItem(.flexible(), spacing: DesignSystem.Spacing.md)
                        ], spacing: DesignSystem.Spacing.md) {
                            ForEach(items) { item in
                                NavigationLink(destination: EditWardrobeItemView(item: item, wardrobeService: WardrobeService())) {
                                    CollectionWardrobeItemCard(item: item)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(DesignSystem.Spacing.md)
                    }
                }
            }
            .navigationTitle(collection.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(collection.name)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
            }
        }
    }
}

struct AddCollectionScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var collectionService = WardrobeCollectionService.shared
    @State private var name = ""
    @State private var description = ""
    @State private var selectedIcon = "folder.fill"
    @State private var selectedColor = "blue"
    
    let icons = ["folder.fill", "briefcase.fill", "calendar", "airplane", "figure.run", "moon.stars.fill", "tshirt.fill", "sparkles"]
    let colors = ["blue", "green", "orange", "red", "purple", "gray", "pink", "yellow", "cyan", "mint"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Nom".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                TextField("Nom de la collection".localized, text: $name)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.primaryText)
                                    .padding(16)
                                    .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                        
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Description".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                TextField("Description (optionnel)".localized, text: $description, axis: .vertical)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.primaryText)
                                    .padding(16)
                                    .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                                    .frame(minHeight: 80)
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                        
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Icône".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(icons, id: \.self) { icon in
                                        Button {
                                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                            selectedIcon = icon
                                            }
                                        } label: {
                                            ZStack {
                                                Circle()
                                                    .fill(selectedIcon == icon ? AppColors.buttonPrimary.opacity(0.2) : AppColors.buttonSecondary)
                                                    .frame(width: 56, height: 56)
                                                
                                                Image(systemName: icon)
                                                    .font(.system(size: 24, weight: .medium))
                                                    .foregroundColor(selectedIcon == icon ? AppColors.buttonPrimary : AppColors.secondaryText)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                        
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Couleur".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(colors, id: \.self) { color in
                                        Button {
                                            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                                            selectedColor = color
                                            }
                                        } label: {
                                            ZStack {
                                                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                                                    .fill(colorFromString(color))
                                                    .frame(height: 56)
                                                
                                                if selectedColor == color {
                                                    Image(systemName: "checkmark")
                                                        .font(.system(size: 18, weight: .bold))
                                                        .foregroundColor(.white)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Nouvelle collection".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Nouvelle collection".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler".localized) { dismiss() }
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Créer".localized) {
                        let collection = WardrobeCollection(
                            name: name,
                            description: description,
                            icon: selectedIcon,
                            color: selectedColor
                        )
                        collectionService.addCollection(collection)
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                    .foregroundColor(name.isEmpty ? AppColors.secondaryText : AppColors.buttonPrimary)
                }
            }
        }
    }
    
    private func colorFromString(_ colorName: String) -> Color {
        switch colorName.lowercased() {
        case "blue": return .blue
        case "green": return .green
        case "orange": return .orange
        case "red": return .red
        case "purple": return .purple
        case "gray", "grey": return .gray
        case "pink": return .pink
        case "yellow": return .yellow
        case "cyan": return .cyan
        case "mint": return .mint
        default: return AppColors.buttonPrimary
        }
    }
}

struct CollectionWardrobeItemCard: View {
    let item: WardrobeItem
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.md) {
            VStack(alignment: .leading, spacing: DesignSystem.Spacing.sm) {
                if let photoURL = item.photoURL, !photoURL.isEmpty {
                    AsyncImage(url: URL(fileURLWithPath: photoURL)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Rectangle()
                            .fill(AppColors.cardBackground)
                    }
                    .frame(height: 120)
                    .cornerRadius(DesignSystem.Radius.sm)
                    .clipped()
                } else {
                    Rectangle()
                        .fill(AppColors.cardBackground)
                        .frame(height: 120)
                        .cornerRadius(DesignSystem.Radius.sm)
                        .overlay {
                            Image(systemName: item.category.icon)
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(AppColors.secondaryText)
                        }
                }
                
                Text(item.name)
                    .font(DesignSystem.Typography.caption())
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(1)
            }
        }
    }
}
