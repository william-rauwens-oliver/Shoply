//
//  WardrobeManagementScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import PhotosUI

/// Écran de gestion de la garde-robe - Design moderne
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
    
    var hasSelectedItems: Bool {
        !selectedItems.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Barre de recherche moderne
                    ModernSearchBar(text: $searchText)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    
                    // Sélecteur de catégorie moderne
                    ModernCategoryPicker(selectedCategory: $selectedCategory)
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    
                    // Barre d'actions si mode sélection
                    if isSelectionMode {
                        ModernSelectionToolbar(
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
                        .background(AppColors.cardBackground)
                    }
                    
                    // Liste des vêtements
                    if filteredItems.isEmpty {
                        ModernEmptyWardrobeView(category: selectedCategory)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ], spacing: 16) {
                            ForEach(filteredItems) { item in
                                    ModernWardrobeItemCard(
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
                                    .id("card-\(item.id)-\(item.photoURL ?? "nophoto")")
                            }
                        }
                            .padding(20)
                            .id(wardrobeService.items.count)
                        }
                    }
                }
            }
            .navigationTitle(isSelectionMode ? "\(selectedItems.count) sélectionné\(selectedItems.count > 1 ? "s" : "")" : "Garde-robe".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isSelectionMode {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if !wardrobeService.items.isEmpty {
                            Button(action: {
                                showingDeleteAllAlert = true
                            }) {
                                Image(systemName: "trash")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.red)
                            }
                            }
                        }
                    }
                    
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddItem = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(AppColors.buttonPrimary)
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
                Text("Êtes-vous sûr de vouloir supprimer tous les vêtements de votre garde-robe ? Cette action est irréversible.".localized)
            }
            .alert("Supprimer les vêtements sélectionnés".localized, isPresented: $showingDeleteSelectedAlert) {
                Button("Annuler".localized, role: .cancel) { }
                Button("Supprimer".localized, role: .destructive) {
                    deleteSelectedItems()
                }
            } message: {
                Text("Êtes-vous sûr de vouloir supprimer \(selectedItems.count) vêtement\(selectedItems.count > 1 ? "s" : "") ? Cette action est irréversible.".localized)
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

// MARK: - Composants Modernes

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
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.secondaryText)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .liquidGlassCard(cornerRadius: DesignSystem.Radius.lg)
    }
}

struct ModernCategoryPicker: View {
    @Binding var selectedCategory: ClothingCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ClothingCategory.allCases) { category in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedCategory = category
                        }
                    }) {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(selectedCategory == category ? AppColors.buttonPrimary : AppColors.buttonSecondary)
                                    .frame(width: 48, height: 48)
                                
                            Image(systemName: category.icon)
                                    .font(.system(size: 22, weight: .semibold))
                                .foregroundColor(selectedCategory == category ? AppColors.buttonPrimaryText : AppColors.primaryText)
                            }
                            
                            Text(category.rawValue)
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(selectedCategory == category ? AppColors.buttonPrimary : AppColors.secondaryText)
                                .fontWeight(selectedCategory == category ? .semibold : .regular)
                    }
                        .frame(width: 80)
            }
        }
    }
            .padding(.horizontal, 4)
        }
    }
}

struct ModernSelectionToolbar: View {
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
    }
}

struct ModernWardrobeItemCard: View {
    let item: WardrobeItem
    @ObservedObject var wardrobeService: WardrobeService
    @Binding var isSelectionMode: Bool
    @Binding var isSelected: Bool
    @State private var showingDetail = false
    @State private var isPressed = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
        Button(action: {
                if isSelectionMode {
                    withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                    isSelected.toggle()
                    }
                } else {
            showingDetail = true
                }
        }) {
                VStack(alignment: .leading, spacing: 0) {
                // Photo ou placeholder
                Group {
                        let firstPhotoURL = item.photoURLs.first ?? item.photoURL
                        if let photoURL = firstPhotoURL, !photoURL.isEmpty {
                        if let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                    .frame(height: 160)
                                .clipped()
                                    .id("photo-\(item.id)-\(photoURL)")
                            } else {
                                ModernPlaceholderView(icon: item.category.icon)
                                    .frame(height: 160)
                            }
                        } else {
                            ModernPlaceholderView(icon: item.category.icon)
                                .frame(height: 160)
                        }
                    }
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
                    
                    // Informations
                    VStack(alignment: .leading, spacing: 6) {
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
                    .padding(12)
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
                            .padding(6)
                            .background(Circle().fill(Color.white.opacity(0.9)))
                            .shadow(color: AppColors.shadow.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(8)
                
                Spacer()
            }
            
            // Indicateur de sélection
            if isSelectionMode {
                VStack {
                    HStack {
                        Spacer()
                ZStack {
                    Circle()
                        .fill(isSelected ? AppColors.buttonPrimary : Color.white)
                        .frame(width: 28, height: 28)
                                .shadow(color: AppColors.shadow.opacity(0.3), radius: 6, x: 0, y: 3)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.buttonPrimaryText)
                    }
                }
                .padding(8)
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

struct ModernPlaceholderView: View {
    let icon: String
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    AppColors.buttonSecondary,
                    AppColors.buttonSecondary.opacity(0.5)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            Image(systemName: icon)
                .font(.system(size: 48, weight: .light))
                .foregroundColor(AppColors.secondaryText)
        }
    }
}

struct ModernEmptyWardrobeView: View {
    let category: ClothingCategory
    
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
                
            Image(systemName: category.icon)
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(AppColors.secondaryText)
            }
            .shadow(color: AppColors.shadow.opacity(0.15), radius: 16, x: 0, y: 6)
            
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

// MARK: - Écran d'ajout de vêtement (conservé tel quel)
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
            Form {
                Section("Informations de base") {
                    TextField("Nom", text: $name)
                    Picker("Catégorie", selection: $selectedCategory) {
                        ForEach(ClothingCategory.allCases) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    TextField("Couleur", text: $color)
                    TextField("Marque (optionnel)", text: $brand)
                    TextField("Matière (optionnel)", text: $material)
                }
                
                Section("Saisons") {
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
                    }
                }
                
                Section("Photos") {
                    PhotosPicker(
                        selection: $selectedPhotos,
                        maxSelectionCount: 10,
                        matching: .images
                    ) {
                        HStack {
                            Image(systemName: "photo.on.rectangle")
                            Text("Ajouter des photos (jusqu'à 10)")
                        }
                        .foregroundColor(AppColors.primaryText)
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
                                        
                                        Button(action: {
                                            photoImages.remove(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.red)
                                                .background(Color.white.clipShape(Circle()))
                            }
                                        .padding(4)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .navigationTitle("Nouvel article".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler".localized) {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer".localized) {
                        saveItem()
                    }
                    .disabled(name.isEmpty || isSaving)
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
                    print("Erreur lors de la sauvegarde de la photo: \(error.localizedDescription)")
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

// MARK: - Détails d'un vêtement (conservé tel quel)
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
            ScrollView {
                VStack(spacing: 20) {
                        if !item.photoURLs.isEmpty || item.photoURL != nil {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(photoURLsToDisplay, id: \.self) { photoURL in
                                        if let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                                                .frame(maxWidth: 400, maxHeight: 500)
                            .roundedCorner(20)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                                .id("detail-photo-\(item.id)-\(photoURL)")
                                        }
                                    }
                                }
                            .padding(.horizontal)
                            }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: item.category.icon)
                                .font(.system(size: 80))
                                .foregroundColor(AppColors.secondaryText)
                            
                                Text("Aucune photo".localized)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .frame(height: 300)
                        .frame(maxWidth: .infinity)
                        .background(AppColors.buttonSecondary)
                        .roundedCorner(20)
                        .padding(.horizontal)
                    }
                    
                    VStack(alignment: .leading, spacing: 15) {
                        DetailRow(label: "Nom".localized, value: item.name)
                        DetailRow(label: "Catégorie".localized, value: item.category.rawValue)
                        DetailRow(label: "Couleur".localized, value: item.color)
                            DetailRow(label: "Marque".localized, value: item.brand ?? "Non renseigné".localized)
                            DetailRow(label: "Matière".localized, value: item.material ?? "Non renseigné".localized)
                        DetailRow(label: "Saisons".localized, value: item.season.map { $0.rawValue }.joined(separator: ", "))
                    }
                    .padding()
                    .cleanCard(cornerRadius: 20)
                    .padding(.horizontal)
                }
            }
            .navigationTitle(item.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Modifier".localized) {
                            isEditing = true
                        }
                    }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                                .foregroundColor(.red)
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
                Text("Êtes-vous sûr de vouloir supprimer cet article de votre garde-robe ?".localized)
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
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColors.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(AppColors.primaryText)
        }
    }
}

#Preview {
    WardrobeManagementScreen()
}
