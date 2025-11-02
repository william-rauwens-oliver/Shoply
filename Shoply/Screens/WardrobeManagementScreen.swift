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
                    SearchBar(text: $searchText)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Sélecteur de catégorie
                    CategoryPicker(selectedCategory: $selectedCategory)
                        .padding(.horizontal)
                        .padding(.top, 10)
                    
                    // Liste des vêtements
                    ScrollView {
                        LazyVGrid(columns: [
                            GridItem(.flexible(), spacing: 15),
                            GridItem(.flexible(), spacing: 15)
                        ], spacing: 15) {
                            ForEach(filteredItems) { item in
                                WardrobeItemCard(item: item, wardrobeService: wardrobeService)
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
            .navigationTitle("Ma Garde-robe".localized)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
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
            .sheet(isPresented: $showingAddItem) {
                AddWardrobeItemView(wardrobeService: wardrobeService)
            }
        }
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

// MARK: - Carte de vêtement
struct WardrobeItemCard: View {
    let item: WardrobeItem
    @ObservedObject var wardrobeService: WardrobeService
    @State private var showingDetail = false
    
    var body: some View {
        Button(action: {
            showingDetail = true
        }) {
            VStack(alignment: .leading, spacing: 8) {
                // Photo ou placeholder
                Group {
                    if let photoURL = item.photoURL, !photoURL.isEmpty {
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
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showingDetail) {
            WardrobeItemDetailView(item: item, wardrobeService: wardrobeService)
        }
    }
}

// MARK: - Vue vide
struct EmptyWardrobeView: View {
    let category: ClothingCategory
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: category.icon)
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Aucun {category} dans votre garde-robe".localized.replacingOccurrences(of: "{category}", with: category.rawValue.lowercased()))
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Appuyez sur + pour ajouter vos premiers vêtements".localized)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 40)
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
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var photoImage: UIImage?
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
                
                Section("Photo") {
                    PhotosPicker(
                        selection: $selectedPhoto,
                        matching: .images
                    ) {
                        HStack {
                            if let photoImage = photoImage {
                                Image(uiImage: photoImage)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(height: 150)
                                    .roundedCorner(20)
                            } else {
                                HStack {
                                    Image(systemName: "photo")
                                    Text("Ajouter une photo")
                                }
                                .foregroundColor(AppColors.primaryText)
                            }
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
            .onChange(of: selectedPhoto) { oldValue, newValue in
                Task {
                    if let newValue = newValue {
                        if let data = try? await newValue.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            photoImage = image
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
            
            // Sauvegarder la photo AVANT d'ajouter l'item si disponible
            if let photoImage = photoImage {
                do {
                    // Sauvegarder la photo et mettre à jour le photoURL de l'item
                    let photoPath = try await PhotoManager.shared.savePhoto(photoImage, itemId: item.id)
                    item.photoURL = photoPath
                } catch {
                    print("Erreur lors de la sauvegarde de la photo: \(error.localizedDescription)")
                }
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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo - Affichage plus grand et meilleur
                    if let photoURL = item.photoURL,
                       let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: .infinity, maxHeight: 500)
                            .roundedCorner(20)
                            .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                            .padding(.horizontal)
                            .padding(.top)
                            .id("detail-photo-\(item.id)-\(photoURL)") // Force le rafraîchissement
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
                        if let brand = item.brand {
                            DetailRow(label: "Marque".localized, value: brand)
                        }
                        if let material = item.material {
                            DetailRow(label: "Matière".localized, value: material)
                        }
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
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(AppColors.primaryText)
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

