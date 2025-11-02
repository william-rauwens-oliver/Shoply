//
//  WardrobeManagementScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import PhotosUI

/// Écran de gestion de la garde-robe
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
                // Fond opaque simple
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Barre de recherche
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Sélecteur de catégorie
                    CategoryPicker(selectedCategory: $selectedCategory)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Barre d'actions si mode sélection
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
                        .padding(.horizontal)
                        .padding(.vertical, 8)
                        .background(AppColors.cardBackground)
                    }
                    
                    // Liste des vêtements
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 15),
                            GridItem(.flexible(), spacing: 15)
                        ], spacing: 15) {
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
                                    .id("card-\(item.id)-\(item.photoURL ?? "nophoto")")
                            }
                        }
                        .padding()
                        .id(wardrobeService.items.count) // Force le rafraîchissement quand la liste change
                        
                        if filteredItems.isEmpty {
                            EmptyWardrobeView(category: selectedCategory)
                                .padding(.top, 50)
                        }
                    }
                }
            }
            .navigationTitle(isSelectionMode ? "\(selectedItems.count) sélectionné\(selectedItems.count > 1 ? "s" : "")" : "Garde-robe")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                if !isSelectionMode {
                    ToolbarItem(placement: .navigationBarLeading) {
                        if !wardrobeService.items.isEmpty {
                            Button(action: {
                                showingDeleteAllAlert = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddItem = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(AppColors.primaryText)
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                AddWardrobeItemView(wardrobeService: wardrobeService)
            }
            .onChange(of: selectedCategory) { oldValue, newValue in
                // Réinitialiser la sélection quand on change de catégorie
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
        // Supprimer tous les items de la garde-robe
        for item in wardrobeService.items {
            wardrobeService.deleteItem(item)
        }
    }
    
    private func deleteSelectedItems() {
        // Supprimer les items sélectionnés
        let itemsToDelete = wardrobeService.items.filter { selectedItems.contains($0.id) }
        for item in itemsToDelete {
            wardrobeService.deleteItem(item)
        }
        // Réinitialiser la sélection
        selectedItems.removeAll()
        isSelectionMode = false
    }
}

// MARK: - Barre de recherche
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.secondaryText)
            
            TextField("Rechercher...".localized, text: $text)
                .font(.system(size: 16))
                .foregroundColor(AppColors.primaryText)
        }
        .padding()
        .background(AppColors.buttonSecondary)
        .roundedCorner(20)
    }
}

// MARK: - Sélecteur de catégorie
struct CategoryPicker: View {
    @Binding var selectedCategory: ClothingCategory
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(ClothingCategory.allCases) { category in
                    Button(action: {
                        selectedCategory = category
                    }) {
                        VStack(spacing: 8) {
                            Image(systemName: category.icon)
                                .font(.system(size: 24))
                                .foregroundColor(selectedCategory == category ? AppColors.buttonPrimaryText : AppColors.primaryText)
                            
                            Text(category.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(selectedCategory == category ? AppColors.buttonPrimaryText : AppColors.primaryText)
                        }
                        .frame(width: 80, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(selectedCategory == category ? AppColors.buttonPrimary : AppColors.buttonSecondary)
                        )
                    }
                }
            }
        }
    }
}

// MARK: - Barre d'outils de sélection
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
                HStack(spacing: 6) {
                    Image(systemName: selectedCount == totalCount ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 16))
                    Text(selectedCount == totalCount ? "Tout désélectionner" : "Tout sélectionner")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(AppColors.buttonPrimary)
            }
            
            Spacer()
            
            if selectedCount > 0 {
                Button(action: onDeleteSelected) {
                    HStack(spacing: 6) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                        Text("Supprimer (\(selectedCount))")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    .foregroundColor(.red)
                }
            }
            
            Button(action: onCancel) {
                Text("Annuler")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - Carte de vêtement
struct WardrobeItemCard: View {
    let item: WardrobeItem
    @ObservedObject var wardrobeService: WardrobeService
    @Binding var isSelectionMode: Bool
    @Binding var isSelected: Bool
    @State private var showingDetail = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
        Button(action: {
                if isSelectionMode {
                    isSelected.toggle()
                } else {
            showingDetail = true
                }
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Photo ou placeholder
                Group {
                        let firstPhotoURL = item.photoURLs.first ?? item.photoURL
                        if let photoURL = firstPhotoURL, !photoURL.isEmpty {
                        if let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 150)
                                .clipped()
                                .id("photo-\(item.id)-\(photoURL)") // Force le rafraîchissement
                        } else {
                            // Si le chemin existe mais l'image ne charge pas
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(height: 150)
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .foregroundColor(AppColors.secondaryText)
                                        Text("Photo introuvable")
                                            .font(.system(size: 12))
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                )
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 150)
                            .overlay(
                                Image(systemName: item.category.icon)
                                    .font(.system(size: 40))
                                    .foregroundColor(AppColors.secondaryText)
                            )
                        }
                    }
                }
                .frame(height: 150)
                .roundedCorner(20)
                .overlay(
                    VStack {
                        HStack {
                            Spacer()
                            if item.isFavorite {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                    .font(.system(size: 16))
                                    .padding(8)
                                    .background(Circle().fill(Color.white.opacity(0.9)))
                            }
                        }
                        Spacer()
                    }
                    .padding(8)
                )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(item.color)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 18)
                    .fill(Material.regularMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(
                                isSelected
                                    ? LinearGradient(
                                        colors: [
                                            AppColors.buttonPrimary.opacity(0.8),
                                            AppColors.buttonPrimary.opacity(0.5)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                    : LinearGradient(
                                        colors: [
                                            AppColors.cardBorder.opacity(0.4),
                                            AppColors.cardBorder.opacity(0.2)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                lineWidth: isSelected ? 2.5 : 1
                            )
                    }
            )
            .roundedCorner(18)
            .shadow(color: AppColors.shadow.opacity(isSelected ? 0.25 : 0.15), radius: isSelected ? 12 : 8, x: 0, y: isSelected ? 5 : 3)
        .buttonStyle(PlainButtonStyle())
            .onLongPressGesture(minimumDuration: 0.5) {
                // Activer le mode sélection au long press
                if !isSelectionMode {
                    isSelectionMode = true
                    isSelected = true
                }
            }
        .sheet(isPresented: $showingDetail) {
            WardrobeItemDetailView(item: item, wardrobeService: wardrobeService)
            }
            
            // Indicateur de sélection
            if isSelectionMode {
                ZStack {
                    Circle()
                        .fill(isSelected ? AppColors.buttonPrimary : Color.white)
                        .frame(width: 28, height: 28)
                        .shadow(color: AppColors.shadow, radius: 4, x: 0, y: 2)
                    
                    if isSelected {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppColors.buttonPrimaryText)
                    }
                }
                .padding(8)
            }
        }
    }
}

// MARK: - Vue vide
struct EmptyWardrobeView: View {
    let category: ClothingCategory
    
    var body: some View {
        VStack(spacing: 28) {
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
                    .frame(width: 100, height: 100)
                    .overlay {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        AppColors.cardBorder.opacity(0.3),
                                        AppColors.cardBorder.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
                
            Image(systemName: category.icon)
                    .font(.system(size: 44, weight: .light))
                    .foregroundColor(AppColors.secondaryText)
            }
            .shadow(color: AppColors.shadow.opacity(0.15), radius: 12, x: 0, y: 4)
            
            VStack(spacing: 14) {
                Text("Aucun \(category.rawValue.lowercased()) dans votre garde-robe".localized)
                    .font(.playfairDisplayBold(size: 24))
                    .foregroundColor(AppColors.primaryText)
                .multilineTextAlignment(.center)
            
                Text("Appuyez sur le bouton + pour ajouter vos premiers vêtements".localized)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundColor(AppColors.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
        }
        .padding(.vertical, 40)
    }
}

// MARK: - Écran d'ajout de vêtement
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
            .navigationTitle("Nouvel article")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Annuler") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Enregistrer") {
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
            // Créer l'item d'abord
            var item = WardrobeItem(
                name: name,
                category: selectedCategory,
                color: color,
                brand: brand.isEmpty ? nil : brand,
                season: Array(selectedSeasons),
                material: material.isEmpty ? nil : material
            )
            
            // Sauvegarder les photos AVANT d'ajouter l'item si disponibles
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
                item.photoURL = photoPaths.first // Compatibilité backward
            }
            
            // Ajouter l'item avec le photoURL mis à jour
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
            ScrollView {
                VStack(spacing: 20) {
                        // Photos - Support multi-photos
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
                        // Afficher un placeholder si pas de photo
                        VStack(spacing: 16) {
                            Image(systemName: item.category.icon)
                                .font(.system(size: 80))
                                .foregroundColor(AppColors.secondaryText)
                            
                            Text("Aucune photo")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppColors.secondaryText)
                        }
                        .frame(height: 300)
                        .frame(maxWidth: .infinity)
                        .background(AppColors.buttonSecondary)
                        .roundedCorner(20)
                        .padding(.horizontal)
                    }
                    
                    // Informations
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

