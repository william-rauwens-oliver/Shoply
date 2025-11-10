//
//  WardrobeManagementScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import PhotosUI

struct WardrobeManagementScreen: View {
    @StateObject private var wardrobeService = WardrobeService()
    @State private var selectedCategory: ClothingCategory = .top
    @State private var showingAddItem = false
    @State private var searchText = ""
    @State private var isSelectionMode = false
    @State private var selectedItems: Set<UUID> = []
    @State private var showingDeleteAllAlert = false
    @State private var showingDeleteSelectedAlert = false
    
    var filteredItems: [WardrobeItem] {
        if searchText.isEmpty {
            return wardrobeService.getItemsByCategory(selectedCategory)
        } else {
            return wardrobeService.searchItems(query: searchText)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Barre de recherche
                    ModernSearchBar(text: $searchText)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    // Sélecteur de catégorie
                    CategoryPicker(selectedCategory: $selectedCategory)
                        .padding(.horizontal, 20)
                        .padding(.top, 16)
                    
                    // Barre d'actions en mode sélection
                    if isSelectionMode {
                        SelectionToolbar(
                            selectedCount: selectedItems.count,
                            totalCount: filteredItems.count,
                            onSelectAll: {
                                selectedItems = Set(filteredItems.map { $0.id })
                            },
                            onDeselectAll: {
                                selectedItems.removeAll()
                            },
                            onDeleteSelected: {
                                showingDeleteSelectedAlert = true
                            },
                            onCancel: {
                                isSelectionMode = false
                                selectedItems.removeAll()
                            }
                        )
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                    }
                    
                    // Contenu
                    if filteredItems.isEmpty {
                        EmptyWardrobeView(category: selectedCategory)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 16) {
                                ForEach(filteredItems) { item in
                                    WardrobeItemCard(
                                        item: item,
                                        wardrobeService: wardrobeService,
                                        isSelectionMode: $isSelectionMode,
                                        isSelected: Binding(
                                            get: { selectedItems.contains(item.id) },
                                            set: { isSelected in
                                                if isSelected {
                                                    selectedItems.insert(item.id)
                                                } else {
                                                    selectedItems.remove(item.id)
                                                }
                                            }
                                        )
                                    )
                                }
                            }
                            .padding(20)
                        }
                    }
                }
            }
            .navigationTitle(isSelectionMode ? "\(selectedItems.count) sélectionné\(selectedItems.count > 1 ? "s" : "")" : "Garde-robe".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(isSelectionMode ? "\(selectedItems.count) sélectionné\(selectedItems.count > 1 ? "s" : "")" : "Garde-robe".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isSelectionMode && !wardrobeService.items.isEmpty {
                        HStack(spacing: 12) {
                            BackButtonWithLongPress()
                            Button {
                                showingDeleteAllAlert = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.red)
                            }
                        }
                    } else {
                        BackButtonWithLongPress()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.primaryText)
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddWardrobeItemView(wardrobeService: wardrobeService)
            }
            .onChange(of: selectedCategory) { oldValue, newValue in
                if isSelectionMode {
                    selectedItems.removeAll()
                }
            }
            .alert("Supprimer tous les vêtements".localized, isPresented: $showingDeleteAllAlert) {
                Button("Annuler".localized, role: .cancel) { }
                Button("Supprimer tout".localized, role: .destructive) {
                    deleteAllItems()
                }
            } message: {
                Text("Êtes-vous sûr de vouloir supprimer tous les vêtements ? Cette action est irréversible.".localized)
            }
            .alert("Supprimer les vêtements sélectionnés".localized, isPresented: $showingDeleteSelectedAlert) {
                Button("Annuler".localized, role: .cancel) { }
                Button("Supprimer".localized, role: .destructive) {
                    deleteSelectedItems()
                }
            } message: {
                Text("Êtes-vous sûr de vouloir supprimer \(selectedItems.count) vêtement\(selectedItems.count > 1 ? "s" : "") ?".localized)
            }
        }
    }
    
    private func deleteAllItems() {
        for item in wardrobeService.items {
            wardrobeService.deleteItem(item)
        }
    }
    
    private func deleteSelectedItems() {
        let itemsToDelete = wardrobeService.items.filter { selectedItems.contains($0.id) }
        for item in itemsToDelete {
            wardrobeService.deleteItem(item)
        }
        selectedItems.removeAll()
        isSelectionMode = false
    }
}

// MARK: - Composants

struct ModernSearchBar: View {
    @Binding var text: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppColors.secondaryText)
            
            TextField("Rechercher...".localized, text: $text)
                .font(DesignSystem.Typography.body())
                .foregroundColor(AppColors.primaryText)
                .focused($isFocused)
            
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.secondaryText)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .liquidGlassCard(cornerRadius: DesignSystem.Radius.lg)
    }
}

struct CategoryPicker: View {
    @Binding var selectedCategory: ClothingCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ClothingCategory.allCases) { category in
                    Button {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedCategory = category
                        }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(selectedCategory == category ? AppColors.buttonPrimary.opacity(0.2) : AppColors.buttonSecondary.opacity(0.3))
                                    .frame(width: 52, height: 52)
                                
                                Image(systemName: category.icon)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundColor(selectedCategory == category ? AppColors.buttonPrimary : AppColors.primaryText)
                            }
                            
                            Text(category.rawValue)
                                .font(.system(size: 12, weight: selectedCategory == category ? .semibold : .regular))
                                .foregroundColor(selectedCategory == category ? AppColors.buttonPrimary : AppColors.secondaryText)
                        }
                        .frame(width: 70)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct SelectionToolbar: View {
    let selectedCount: Int
    let totalCount: Int
    let onSelectAll: () -> Void
    let onDeselectAll: () -> Void
    let onDeleteSelected: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        HStack(spacing: 16) {
            Button(action: selectedCount == totalCount ? onDeselectAll : onSelectAll) {
                HStack(spacing: 8) {
                    Image(systemName: selectedCount == totalCount ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .medium))
                    Text(selectedCount == totalCount ? "Tout désélectionner".localized : "Tout sélectionner".localized)
                        .font(DesignSystem.Typography.footnote())
                        .fontWeight(.semibold)
                }
                .foregroundColor(AppColors.buttonPrimary)
            }
            
            Spacer()
            
            if selectedCount > 0 {
                Button(action: onDeleteSelected) {
                    HStack(spacing: 8) {
                        Image(systemName: "trash")
                            .font(.system(size: 18, weight: .medium))
                        Text("Supprimer (\(selectedCount))".localized)
                            .font(DesignSystem.Typography.footnote())
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.red)
                }
            }
            
            Button(action: onCancel) {
                Text("Annuler".localized)
                    .font(DesignSystem.Typography.footnote())
                    .fontWeight(.semibold)
                    .foregroundColor(AppColors.primaryText)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
    }
}

struct WardrobeItemCard: View {
    let item: WardrobeItem
    @ObservedObject var wardrobeService: WardrobeService
    @Binding var isSelectionMode: Bool
    @Binding var isSelected: Bool
    @State private var showingDetail = false
    @State private var isPressed = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            Button {
                if isSelectionMode {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                        isSelected.toggle()
                    }
                } else {
                    showingDetail = true
                }
            } label: {
                VStack(alignment: .leading, spacing: 0) {
                    // Photo
                    Group {
                        let firstPhotoURL = item.photoURLs.first ?? item.photoURL
                        if let photoURL = firstPhotoURL, !photoURL.isEmpty,
                           let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 180)
                                .clipped()
                        } else {
                            ZStack {
                                LinearGradient(
                                    colors: [
                                        AppColors.buttonSecondary,
                                        AppColors.buttonSecondary.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                                
                                Image(systemName: item.category.icon)
                                    .font(.system(size: 48, weight: .light))
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            .frame(height: 180)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
                    
                    // Informations
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.name)
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(AppColors.primaryText)
                            .lineLimit(1)
                        
                        HStack(spacing: 6) {
                            Circle()
                                .fill(colorFromString(item.color))
                                .frame(width: 12, height: 12)
                            
                            Text(item.color)
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(AppColors.secondaryText)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .liquidGlassCard(cornerRadius: DesignSystem.Radius.lg)
            }
            .buttonStyle(PlainButtonStyle())
            .scaleEffect(isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
            .onLongPressGesture(minimumDuration: 0.5) {
                if !isSelectionMode {
                    isSelectionMode = true
                    isSelected = true
                }
            }
            .sheet(isPresented: $showingDetail) {
                WardrobeItemDetailView(item: item, wardrobeService: wardrobeService)
            }
            
            // Indicateurs
            VStack {
                HStack {
                    Spacer()
                    if item.isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.red)
                            .padding(8)
                            .background(Circle().fill(.ultraThinMaterial))
                            .shadow(color: AppColors.shadow.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(10)
                
                Spacer()
            }
            
            // Indicateur de sélection
            if isSelectionMode {
                VStack {
                    HStack {
                        Spacer()
                        ZStack {
                            Circle()
                                .fill(isSelected ? AppColors.buttonPrimary : .white)
                                .frame(width: 28, height: 28)
                                .shadow(color: AppColors.shadow.opacity(0.3), radius: 6, x: 0, y: 3)
                            
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(AppColors.buttonPrimaryText)
                            }
                        }
                        .padding(10)
                    }
                    Spacer()
                }
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

struct EmptyWardrobeView: View {
    let category: ClothingCategory
    
    var body: some View {
        VStack(spacing: 24) {
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
                
                Image(systemName: category.icon)
                    .font(.system(size: 50, weight: .light))
                    .foregroundColor(AppColors.buttonPrimary)
            }
            
            VStack(spacing: 12) {
                Text("Aucun \(category.rawValue.lowercased()) dans votre garde-robe".localized)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(AppColors.primaryText)
                    .multilineTextAlignment(.center)
                
                Text("Appuyez sur le bouton + pour ajouter vos premiers vêtements".localized)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
        }
    }
}

// MARK: - Écran d'ajout

struct AddWardrobeItemView: View {
    @ObservedObject var wardrobeService: WardrobeService
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var selectedCategory: ClothingCategory = .top
    @State private var color = ""
    @State private var brand = ""
    @State private var selectedSeasons: Set<Season> = []
    @State private var material = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoImages: [UIImage] = []
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Informations de base
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Informations de base".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                VStack(spacing: 12) {
                                    TextField("Nom".localized, text: $name)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(AppColors.primaryText)
                                        .padding(14)
                                        .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                                    
                                    Picker("Catégorie".localized, selection: $selectedCategory) {
                                        ForEach(ClothingCategory.allCases) { category in
                                            Text(category.rawValue).tag(category)
                                        }
                                    }
                                    .padding(14)
                                    .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                                    
                                    TextField("Couleur".localized, text: $color)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(AppColors.primaryText)
                                        .padding(14)
                                        .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                                    
                                    TextField("Marque (optionnel)".localized, text: $brand)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(AppColors.primaryText)
                                        .padding(14)
                                        .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                                    
                                    TextField("Matière (optionnel)".localized, text: $material)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(AppColors.primaryText)
                                        .padding(14)
                                        .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                                }
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                        
                        // Saisons
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Saisons".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                VStack(spacing: 12) {
                                    ForEach(Season.allCases, id: \.rawValue) { season in
                                        Toggle(season.rawValue, isOn: Binding(
                                            get: { selectedSeasons.contains(season) },
                                            set: { isOn in
                                                if isOn {
                                                    selectedSeasons.insert(season)
                                                } else {
                                                    selectedSeasons.remove(season)
                                                }
                                            }
                                        ))
                                        .tint(AppColors.buttonPrimary)
                                    }
                                }
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                        
                        // Photos
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Photos".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                PhotosPicker(
                                    selection: $selectedPhotos,
                                    maxSelectionCount: 10,
                                    matching: .images
                                ) {
                                    HStack {
                                        Image(systemName: "photo.on.rectangle")
                                        Text("Ajouter des photos (jusqu'à 10)".localized)
                                    }
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.primaryText)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                                    .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                                }
                                
                                if !photoImages.isEmpty {
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(spacing: 12) {
                                            ForEach(Array(photoImages.enumerated()), id: \.offset) { index, image in
                                                ZStack(alignment: .topTrailing) {
                                                    Image(uiImage: image)
                                                        .resizable()
                                                        .aspectRatio(contentMode: .fill)
                                                        .frame(width: 120, height: 120)
                                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                                    
                                                    Button {
                                                        photoImages.remove(at: index)
                                                    } label: {
                                                        Image(systemName: "xmark.circle.fill")
                                                            .foregroundColor(.red)
                                                            .background(Color.white.clipShape(Circle()))
                                                    }
                                                    .padding(4)
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Nouvel article".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Nouvel article".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButtonWithLongPress()
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer".localized) {
                        saveItem()
                    }
                    .disabled(name.isEmpty || isSaving)
                    .foregroundColor(name.isEmpty ? AppColors.secondaryText : AppColors.buttonPrimary)
                }
            }
            .onChange(of: selectedPhotos) { oldValue, newValue in
                Task {
                    photoImages.removeAll()
                    for photoItem in newValue {
                        if let data = try? await photoItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                photoImages.append(image)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func saveItem() {
        isSaving = true
        
        Task {
            var item = WardrobeItem(
                name: name,
                category: selectedCategory,
                color: color,
                brand: brand.isEmpty ? nil : brand,
                season: Array(selectedSeasons),
                material: material.isEmpty ? nil : material
            )
            
            var photoPaths: [String] = []
            for photoImage in photoImages {
                do {
                    let photoPath = try await PhotoManager.shared.savePhoto(photoImage, itemId: item.id)
                    photoPaths.append(photoPath)
                } catch {
                    // Erreur silencieuse
                }
            }
            
            if !photoPaths.isEmpty {
                item.photoURLs = photoPaths
                item.photoURL = photoPaths.first
            }
            
            await MainActor.run {
                wardrobeService.addItem(item)
                isSaving = false
                dismiss()
            }
        }
    }
}

// MARK: - Détails d'un vêtement

struct WardrobeItemDetailView: View {
    let item: WardrobeItem
    @ObservedObject var wardrobeService: WardrobeService
    @Environment(\.dismiss) var dismiss
    @State private var showingDeleteAlert = false
    @State private var isEditing = false
    
    var body: some View {
        if isEditing {
            EditWardrobeItemView(item: item, wardrobeService: wardrobeService)
        } else {
            NavigationStack {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 24) {
                        // Photos
                        if !item.photoURLs.isEmpty || item.photoURL != nil {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(photoURLsToDisplay, id: \.self) { photoURL in
                                        if let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fit)
                                                .frame(maxWidth: 400, maxHeight: 500)
                                                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.xl))
                                        }
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        } else {
                            VStack(spacing: 16) {
                                Image(systemName: item.category.icon)
                                    .font(.system(size: 80, weight: .light))
                                    .foregroundColor(AppColors.secondaryText)
                                
                                Text("Aucune photo".localized)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.secondaryText)
                            }
                            .frame(height: 300)
                            .frame(maxWidth: .infinity)
                            .liquidGlassCard(cornerRadius: DesignSystem.Radius.xl)
                            .padding(.horizontal, 20)
                        }
                        
                        // Informations
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 16) {
                                ForEach(detailRows, id: \.label) { row in
                                    HStack {
                                        Text(row.label)
                                            .font(DesignSystem.Typography.caption())
                                            .foregroundColor(AppColors.secondaryText)
                                        
                                        Spacer()
                                        
                                        Text(row.value)
                                            .font(DesignSystem.Typography.body())
                                            .foregroundColor(AppColors.primaryText)
                                    }
                                    
                                    if row.label != detailRows.last?.label {
                                        Divider()
                                            .background(AppColors.separator.opacity(0.3))
                                    }
                                }
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
                .navigationTitle(item.name)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        Text(item.name)
                            .font(DesignSystem.Typography.title2())
                            .foregroundColor(AppColors.primaryText)
                            .lineLimit(1)
                    }
                    
                    ToolbarItem(placement: .navigationBarLeading) {
                        BackButtonWithLongPress()
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 16) {
                            Button {
                                isEditing = true
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppColors.primaryText)
                            }
                            
                            Button {
                                showingDeleteAlert = true
                            } label: {
                                Image(systemName: "trash")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.red)
                            }
                        }
                    }
                }
                .alert("Supprimer".localized, isPresented: $showingDeleteAlert) {
                    Button("Annuler".localized, role: .cancel) { }
                    Button("Supprimer".localized, role: .destructive) {
                        wardrobeService.deleteItem(item)
                        dismiss()
                    }
                } message: {
                    Text("Êtes-vous sûr de vouloir supprimer cet article ?".localized)
                }
            }
        }
    }
    
    private var photoURLsToDisplay: [String] {
        if !item.photoURLs.isEmpty {
            return item.photoURLs
        } else if let photoURL = item.photoURL {
            return [photoURL]
        }
        return []
    }
    
    private var detailRows: [(label: String, value: String)] {
        [
            ("Nom".localized, item.name),
            ("Catégorie".localized, item.category.rawValue),
            ("Couleur".localized, item.color),
            ("Marque".localized, item.brand ?? "Non renseigné".localized),
            ("Matière".localized, item.material ?? "Non renseigné".localized),
            ("Saisons".localized, item.season.map { $0.rawValue }.joined(separator: ", "))
        ]
    }
}
