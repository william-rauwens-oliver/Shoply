//
//  EditWardrobeItemView.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import PhotosUI

// MARK: - Édition d'un vêtement
struct EditWardrobeItemView: View {
    let item: WardrobeItem
    @ObservedObject var wardrobeService: WardrobeService
    @Environment(\.dismiss) var dismiss
    
    @State private var name: String = ""
    @State private var selectedCategory: ClothingCategory = .top
    @State private var color: String = ""
    @State private var brand: String = ""
    @State private var selectedSeasons: Set<Season> = []
    @State private var material: String = ""
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var photoImages: [UIImage] = []
    @State private var existingPhotoURLs: [String] = []
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
                    
                    // Afficher les photos existantes
                    if !existingPhotoURLs.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(Array(existingPhotoURLs.enumerated()), id: \.offset) { index, photoURL in
                                    ZStack(alignment: .topTrailing) {
                                        if let image = PhotoManager.shared.loadPhoto(at: photoURL) {
                                            Image(uiImage: image)
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 120, height: 120)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            
                                            Button(action: {
                                                PhotoManager.shared.deletePhoto(at: photoURL)
                                                existingPhotoURLs.remove(at: index)
                                            }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .background(Color.white.clipShape(Circle()))
                                            }
                                            .padding(4)
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    
                    // Afficher les nouvelles photos ajoutées
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
            .navigationTitle("Modifier l'article".localized)
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
            .onAppear {
                loadItemData()
            }
            .onChange(of: selectedPhotos) { oldValue, newValue in
                Task {
                    // Ajouter les nouvelles photos aux photos existantes
                    for photoItem in newValue {
                        if let data = try? await photoItem.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                photoImages.append(image)
                            }
                        }
                    }
                    // Réinitialiser la sélection pour permettre de nouvelles sélections
                    selectedPhotos = []
                }
            }
        }
    }
    
    private func loadItemData() {
        name = item.name
        selectedCategory = item.category
        color = item.color
        brand = item.brand ?? ""
        selectedSeasons = Set(item.season)
        material = item.material ?? ""
        
        // Charger les photos existantes
        if !item.photoURLs.isEmpty {
            existingPhotoURLs = item.photoURLs
        } else if let photoURL = item.photoURL {
            existingPhotoURLs = [photoURL]
        }
    }
    
    private func saveItem() {
        isSaving = true
        
        Task {
            // Créer l'item modifié
            var updatedItem = WardrobeItem(
                id: item.id,
                name: name,
                category: selectedCategory,
                color: color,
                brand: brand.isEmpty ? nil : brand,
                season: Array(selectedSeasons),
                material: material.isEmpty ? nil : material,
                photoURL: nil,
                photoURLs: existingPhotoURLs,
                createdAt: item.createdAt,
                lastWorn: item.lastWorn,
                wearCount: item.wearCount,
                isFavorite: item.isFavorite,
                tags: item.tags
            )
            
            // Sauvegarder les nouvelles photos
            var newPhotoPaths: [String] = []
            for photoImage in photoImages {
                do {
                    let photoPath = try await PhotoManager.shared.savePhoto(photoImage, itemId: item.id)
                    newPhotoPaths.append(photoPath)
                } catch {
                    print("Erreur lors de la sauvegarde de la photo: \(error.localizedDescription)")
                }
            }
            
            // Combiner les photos existantes et nouvelles
            updatedItem.photoURLs = existingPhotoURLs + newPhotoPaths
            if !updatedItem.photoURLs.isEmpty {
                updatedItem.photoURL = updatedItem.photoURLs.first // Compatibilité backward
            }
            
            await MainActor.run {
                wardrobeService.updateItem(updatedItem)
                isSaving = false
                dismiss()
            }
        }
    }
}

