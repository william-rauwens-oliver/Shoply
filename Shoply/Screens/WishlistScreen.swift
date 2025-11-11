//
//  WishlistScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import PhotosUI

struct WishlistScreen: View {
    @StateObject private var wishlistService = WishlistService.shared
    @State private var showingAddItem = false
    @State private var filter: WishlistFilter = .all
    
    enum WishlistFilter: String, CaseIterable {
        case all = "Tous"
        case unpurchased = "Non achetés"
        case purchased = "Achetés"
        case highPriority = "Priorité haute"
    }
    
    var filteredItems: [WishlistItem] {
        switch filter {
        case .all:
            return wishlistService.items
        case .unpurchased:
            return wishlistService.getUnpurchasedItems()
        case .purchased:
            return wishlistService.items.filter { $0.isPurchased }
        case .highPriority:
            return wishlistService.getItemsByPriority(.high) + wishlistService.getItemsByPriority(.urgent)
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    AdaptiveContentContainer(maxWidthPad: 900, horizontalPadding: 24) {
                        VStack(spacing: 0) {
                            // Filtres modernes
                            ModernFilterPicker(selectedFilter: $filter)
                                .padding(.horizontal, 20)
                                .padding(.top, 12)
                    
                    // Liste
                    if filteredItems.isEmpty {
                                ModernEmptyWishlistView {
                                    showingAddItem = true
                                }
                    } else {
                        ScrollView(showsIndicators: false) {
                                    LazyVStack(spacing: 16) {
                                ForEach(filteredItems) { item in
                                            ModernWishlistItemCard(item: item)
                                                .padding(.horizontal, 20)
                                }
                            }
                                    .padding(.vertical, 20)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Wishlist".localized)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Wishlist".localized)
                        .font(DesignSystem.Typography.title2())
                        .foregroundColor(AppColors.primaryText)
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    BackButtonWithLongPress()
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
                ModernAddWishlistItemScreen()
            }
        }
    }
}

// MARK: - Composants Modernes

struct ModernFilterPicker: View {
    @Binding var selectedFilter: WishlistScreen.WishlistFilter
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(WishlistScreen.WishlistFilter.allCases, id: \.self) { filter in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedFilter = filter
                        }
                    }) {
                        Text(filter.rawValue.localized)
                            .font(DesignSystem.Typography.footnote())
                            .fontWeight(.semibold)
                            .foregroundColor(selectedFilter == filter ? AppColors.buttonPrimaryText : AppColors.secondaryText)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(selectedFilter == filter ? AppColors.buttonPrimary : AppColors.buttonSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
                    }
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

struct ModernWishlistItemCard: View {
    let item: WishlistItem
    @StateObject private var wishlistService = WishlistService.shared
    @State private var showingDeleteAlert = false
    @State private var isPressed = false
    
    var body: some View {
        Card(cornerRadius: DesignSystem.Radius.lg) {
            HStack(spacing: 16) {
                // Image ou icône
                Group {
                    if let imageURL = item.imageURL,
                       let image = PhotoManager.shared.loadPhoto(at: imageURL) {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
                    } else {
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
                                .frame(width: 80, height: 80)
                    
                    Image(systemName: item.category.icon)
                                .font(.system(size: 32, weight: .medium))
                        .foregroundColor(AppColors.buttonPrimary)
                        }
                    }
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                    Text(item.name)
                        .font(DesignSystem.Typography.headline())
                        .foregroundColor(AppColors.primaryText)
                        .strikethrough(item.isPurchased)
                    
                        if item.isPurchased {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.green)
                        }
                    }
                    
                    if let description = item.description, !description.isEmpty {
                        Text(description)
                            .font(DesignSystem.Typography.caption())
                            .foregroundColor(AppColors.secondaryText)
                            .lineLimit(2)
                    }
                    
                    HStack(spacing: 12) {
                        if let price = item.price {
                            HStack(spacing: 4) {
                                Text("\(String(format: "%.2f", price))")
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.buttonPrimary)
                                    .fontWeight(.bold)
                                Text(item.currency)
                                .font(DesignSystem.Typography.caption())
                                .foregroundColor(AppColors.secondaryText)
                            }
                        }
                        
                        Text(item.priority.rawValue.localized)
                            .font(DesignSystem.Typography.caption())
                            .fontWeight(.semibold)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(item.priority.color.opacity(0.2))
                            .foregroundColor(item.priority.color)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.sm))
                    }
                }
                
                Spacer()
                
                VStack(spacing: 12) {
                    if !item.isPurchased {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            wishlistService.markAsPurchased(item)
                            }
                        } label: {
                            Image(systemName: "checkmark.circle")
                                .font(.system(size: 24, weight: .medium))
                                .foregroundColor(AppColors.buttonPrimary)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(AppColors.buttonSecondary))
                        }
                    }
                    
                    Button {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.red)
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(AppColors.buttonSecondary))
                    }
                }
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
        .alert("Supprimer".localized, isPresented: $showingDeleteAlert) {
            Button("Annuler".localized, role: .cancel) { }
            Button("Supprimer".localized, role: .destructive) {
                wishlistService.deleteItem(item)
            }
        } message: {
            Text("Êtes-vous sûr de vouloir supprimer cet élément ?".localized)
        }
    }
}

struct ModernEmptyWishlistView: View {
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
                
                Image(systemName: "heart.circle")
                    .font(.system(size: 52, weight: .light))
                    .foregroundColor(AppColors.secondaryText)
            }
            .shadow(color: AppColors.shadow.opacity(0.15), radius: 16, x: 0, y: 6)
            
            VStack(spacing: 12) {
                Text("Votre wishlist est vide".localized)
                    .font(DesignSystem.Typography.title2())
                    .foregroundColor(AppColors.primaryText)
                
                Text("Ajoutez des vêtements que vous souhaitez acheter".localized)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Button(action: onCreate) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 18, weight: .medium))
                    Text("Ajouter un article".localized)
                        .font(DesignSystem.Typography.headline())
                }
                .foregroundColor(AppColors.buttonPrimaryText)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(AppColors.buttonPrimary)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Écran d'ajout moderne

struct ModernAddWishlistItemScreen: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var wishlistService = WishlistService.shared
    @State private var name = ""
    @State private var description = ""
    @State private var category: ClothingCategory = .top
    @State private var price: String = ""
    @State private var currency = "EUR"
    @State private var storeURL: String = ""
    @State private var priority: Priority = .medium
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isSaving = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Section image
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Image".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                if let image = selectedImage {
                                    VStack(spacing: 12) {
                                        Image(uiImage: image)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(maxHeight: 250)
                                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
                                        
                                        Button {
                                            withAnimation {
                                                selectedImage = nil
                                                selectedPhoto = nil
                                            }
                                        } label: {
                                            HStack {
                                                Image(systemName: "trash")
                                                Text("Supprimer l'image".localized)
                                            }
                                            .font(DesignSystem.Typography.body())
                                            .foregroundColor(.red)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(AppColors.buttonSecondary)
                                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
                                        }
                                    }
                                } else {
                                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                        VStack(spacing: 12) {
                                            Image(systemName: "photo.badge.plus")
                                                .font(.system(size: 40, weight: .light))
                                                .foregroundColor(AppColors.buttonPrimary)
                                            
                                            Text("Ajouter une image".localized)
                                                .font(DesignSystem.Typography.body())
                                                .foregroundColor(AppColors.primaryText)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 40)
                                        .background(AppColors.buttonSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
                                    }
                                }
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                        
                        // Nom
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Nom *".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                TextField("Nom du vêtement".localized, text: $name)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.primaryText)
                                    .padding(16)
                                    .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                        
                        // Description
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Description".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                TextField("Description (optionnel)".localized, text: $description, axis: .vertical)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.primaryText)
                                    .lineLimit(3...6)
                                    .padding(16)
                                    .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                        
                        // Catégorie
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Catégorie".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                Picker("Catégorie".localized, selection: $category) {
                                    ForEach(ClothingCategory.allCases, id: \.self) { cat in
                                        HStack {
                                            Image(systemName: cat.icon)
                                            Text(cat.rawValue.localized)
                                        }
                                        .tag(cat)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(16)
                                .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                        
                        // Prix et devise
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Prix".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                HStack(spacing: 12) {
                                    TextField("0.00", text: $price)
                                        .font(DesignSystem.Typography.body())
                                        .foregroundColor(AppColors.primaryText)
                                        .keyboardType(.decimalPad)
                                        .padding(16)
                                        .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                                        .frame(maxWidth: .infinity)
                                    
                                    Picker("Devise".localized, selection: $currency) {
                                        Text("EUR").tag("EUR")
                                        Text("USD").tag("USD")
                                        Text("GBP").tag("GBP")
                                    }
                                    .pickerStyle(.menu)
                                    .padding(16)
                                    .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                                    .frame(width: 100)
                                }
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                        
                        // Lien boutique
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Lien boutique".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                TextField("URL (optionnel)".localized, text: $storeURL)
                                    .font(DesignSystem.Typography.body())
                                    .foregroundColor(AppColors.primaryText)
                                    .keyboardType(.URL)
                                    .autocapitalization(.none)
                                    .padding(16)
                                    .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                        
                        // Priorité
                        Card(cornerRadius: DesignSystem.Radius.lg) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Priorité".localized)
                                    .font(DesignSystem.Typography.headline())
                                    .foregroundColor(AppColors.primaryText)
                                
                                Picker("Priorité".localized, selection: $priority) {
                                    ForEach(Priority.allCases, id: \.self) { prio in
                                        HStack {
                                            Circle()
                                                .fill(prio.color)
                                                .frame(width: 12, height: 12)
                                            Text(prio.rawValue.localized)
                                        }
                                        .tag(prio)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(16)
                                .liquidGlassCard(cornerRadius: DesignSystem.Radius.md)
                            }
                            .padding(20)
                        }
                        .padding(.horizontal, 20)
                        
                        // Bouton enregistrer
                        Button(action: saveItem) {
                            HStack {
                                if isSaving {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: AppColors.buttonPrimaryText))
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 18, weight: .medium))
                                    Text("Enregistrer".localized)
                                        .font(DesignSystem.Typography.headline())
                                }
                    }
                            .foregroundColor(AppColors.buttonPrimaryText)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(name.isEmpty ? AppColors.buttonSecondary : AppColors.buttonPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
                        }
                        .disabled(name.isEmpty || isSaving)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Nouvel article".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler".localized) { dismiss() }
                        .foregroundColor(AppColors.primaryText)
                }
            }
            .onChangePhotosPicker(selectedPhoto: selectedPhoto, selectedImage: $selectedImage)
        }
    }
    
    private func saveItem() {
        guard !name.isEmpty else { return }
        
        isSaving = true
        
        Task {
            var imageURL: String? = nil
            if let image = selectedImage {
                do {
                    let photoPath = try await PhotoManager.shared.savePhoto(image, itemId: UUID())
                    imageURL = photoPath
                } catch {
                    print("Erreur sauvegarde image: \(error)")
                }
            }
            
                        let item = WishlistItem(
                            name: name,
                            description: description.isEmpty ? nil : description,
                            category: category,
                price: price.isEmpty ? nil : Double(price),
                            currency: currency,
                            storeURL: storeURL.isEmpty ? nil : storeURL,
                imageURL: imageURL,
                            priority: priority
                        )
            
            await MainActor.run {
                        wishlistService.addItem(item)
                isSaving = false
                        dismiss()
            }
        }
    }
}
