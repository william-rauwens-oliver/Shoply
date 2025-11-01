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
                adaptiveGradient()
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
                            }
                        }
                        .padding()
                        
                        if filteredItems.isEmpty {
                            EmptyWardrobeView(category: selectedCategory)
                                .padding(.top, 50)
                        }
                    }
                }
            }
            .navigationTitle("Ma Garde-robe")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddItem = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.pink)
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
                .foregroundColor(.gray)
            
            TextField("Rechercher...", text: $text)
                .font(.system(size: 16))
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(12)
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
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                            
                            Text(category.rawValue)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(selectedCategory == category ? .white : .primary)
                        }
                        .frame(width: 80, height: 80)
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(selectedCategory == category ? Color.pink : Color.gray.opacity(0.2))
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
                ZStack {
                    if let photoURL = item.photoURL,
                       let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.3), Color.gray.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Image(systemName: item.category.icon)
                            .font(.system(size: 40))
                            .foregroundColor(.gray)
                    }
                }
                .frame(height: 150)
                .cornerRadius(12)
                .overlay(
                    VStack {
                        HStack {
                            Spacer()
                            if item.isFavorite {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.pink)
                                    .padding(8)
                                    .background(Circle().fill(Color.white))
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
            
            Text("Aucun \(category.rawValue.lowercased()) dans votre garde-robe")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Appuyez sur + pour ajouter vos premiers vêtements")
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
                                    .cornerRadius(8)
                            } else {
                                HStack {
                                    Image(systemName: "photo")
                                    Text("Ajouter une photo")
                                }
                                .foregroundColor(.blue)
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
        
        let item = WardrobeItem(
            name: name,
            category: selectedCategory,
            color: color,
            brand: brand.isEmpty ? nil : brand,
            season: Array(selectedSeasons),
            material: material.isEmpty ? nil : material
        )
        
        Task {
            // Sauvegarder la photo si disponible
            if let photoImage = photoImage {
                do {
                    _ = try await wardrobeService.savePhoto(photoImage, for: item)
                } catch {
                    print("Erreur lors de la sauvegarde de la photo: \(error)")
                }
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
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo
                    if let photoURL = item.photoURL,
                       let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 400)
                            .cornerRadius(20)
                            .padding()
                    }
                    
                    // Informations
                    VStack(alignment: .leading, spacing: 15) {
                        DetailRow(label: "Nom", value: item.name)
                        DetailRow(label: "Catégorie", value: item.category.rawValue)
                        DetailRow(label: "Couleur", value: item.color)
                        if let brand = item.brand {
                            DetailRow(label: "Marque", value: brand)
                        }
                        if let material = item.material {
                            DetailRow(label: "Matière", value: material)
                        }
                        DetailRow(label: "Saisons", value: item.season.map { $0.rawValue }.joined(separator: ", "))
                        DetailRow(label: "Porté", value: "\(item.wearCount) fois")
                    }
                    .padding()
                    .adaptiveCard(cornerRadius: 20)
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
                            .foregroundColor(.red)
                    }
                }
            }
            .alert("Supprimer", isPresented: $showingDeleteAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Supprimer", role: .destructive) {
                    wardrobeService.deleteItem(item)
                    dismiss()
                }
            } message: {
                Text("Êtes-vous sûr de vouloir supprimer cet article de votre garde-robe ?")
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
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16))
                .foregroundColor(.primary)
        }
    }
}

#Preview {
    WardrobeManagementScreen()
}

