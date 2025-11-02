//
//  RecipeGenerationScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//
//  Écran pour prendre des photos d'aliments et générer des recettes

import SwiftUI
import PhotosUI

struct RecipeGenerationScreen: View {
    @StateObject private var foodRecognitionService = FoodRecognitionService.shared
    @StateObject private var recipeService = RecipeGenerationService.shared
    @StateObject private var settingsManager = AppSettingsManager.shared
    
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var capturedImage: UIImage?
    @State private var foodItems: [FoodItem] = []
    @State private var generatedRecipe: Recipe?
    @State private var isAnalyzing = false
    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var showingRecipe = false
    @State private var showingCamera = false
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Instruction
                    VStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 60))
                            .foregroundColor(AppColors.accent)
                            .padding(.bottom, 8)
                        
                        Text("Prenez une photo de vos aliments".localized)
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)
                        
                        Text("Photographiez votre frigo, votre table ou vos ingrédients, et nous générerons une recette pour vous !".localized)
                            .font(.subheadline)
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .padding(.top)
                    
                    // Image capturée ou sélectionnée
                    if let image = capturedImage {
                        VStack(spacing: 16) {
                            Image(uiImage: image)
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(maxHeight: 300)
                                .roundedCorner(20)
                                .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
                                .padding(.horizontal)
                            
                            if !foodItems.isEmpty {
                                // Afficher les aliments détectés
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Ingrédients détectés".localized)
                                        .font(.headline)
                                        .padding(.horizontal)
                                    
                                    ForEach(foodItems) { food in
                                        HStack {
                                            Text(food.category.icon)
                                            Text(food.name)
                                                .fontWeight(.medium)
                                            Spacer()
                                            Text("\(Int(food.confidence * 100))%")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                        .background(AppColors.buttonSecondary)
                                        .roundedCorner(12)
                                        .padding(.horizontal)
                                    }
                                }
                                .padding(.vertical)
                            }
                        }
                    }
                    
                    // Actions
                    VStack(spacing: 12) {
                        // Bouton prendre une photo
                        Button {
                            showingCamera = true
                        } label: {
                            HStack {
                                Image(systemName: "camera.fill")
                                Text("Prendre une photo".localized)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.accent)
                            .foregroundColor(.white)
                            .roundedCorner(16)
                        }
                        .padding(.horizontal)
                        .sheet(isPresented: $showingCamera) {
                            CameraView(capturedImage: $capturedImage)
                        }
                        
                        // Bouton choisir depuis la galerie
                        PhotosPicker(selection: $selectedPhoto, matching: .images) {
                            HStack {
                                Image(systemName: "photo.on.rectangle")
                                Text("Choisir depuis la galerie".localized)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.buttonSecondary)
                            .foregroundColor(AppColors.accent)
                            .roundedCorner(16)
                        }
                        .padding(.horizontal)
                        .onChange(of: selectedPhoto) { oldValue, newValue in
                            Task {
                                if let newValue = newValue {
                                    if let data = try? await newValue.loadTransferable(type: Data.self),
                                       let image = UIImage(data: data) {
                                        await MainActor.run {
                                            capturedImage = image
                                            foodItems = []
                                            generatedRecipe = nil
                                        }
                                    }
                                }
                            }
                        }
                        
                        // Bouton analyser
                        if capturedImage != nil && foodItems.isEmpty {
                            Button {
                                analyzeImage()
                            } label: {
                                HStack {
                                    if isAnalyzing {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "magnifyingglass")
                                    }
                                    Text(isAnalyzing ? "Analyse en cours...".localized : "Analyser les aliments".localized)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isAnalyzing ? AppColors.secondaryText : AppColors.accent)
                                .foregroundColor(.white)
                                .roundedCorner(16)
                            }
                            .disabled(isAnalyzing)
                            .padding(.horizontal)
                        }
                        
                        // Bouton générer recette
                        if !foodItems.isEmpty && generatedRecipe == nil {
                            Button {
                                generateRecipe()
                            } label: {
                                HStack {
                                    if isGenerating {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Image(systemName: "wand.and.stars")
                                    }
                                    Text(isGenerating ? "Génération en cours...".localized : "Générer une recette".localized)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isGenerating ? AppColors.secondaryText : AppColors.accent)
                                .foregroundColor(.white)
                                .roundedCorner(16)
                            }
                            .disabled(isGenerating)
                            .padding(.horizontal)
                        }
                        
                        // Afficher l'erreur si présente
                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                                .padding(.horizontal)
                                .multilineTextAlignment(.center)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Génération de recettes".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
            .sheet(isPresented: $showingRecipe) {
                if let recipe = generatedRecipe {
                    RecipeDetailView(recipe: recipe)
                }
            }
        }
    }
    
    private func analyzeImage() {
        guard let image = capturedImage else { return }
        
        isAnalyzing = true
        errorMessage = nil
        
        Task {
            do {
                let detectedFoods = try await foodRecognitionService.recognizeFoods(in: image)
                await MainActor.run {
                    foodItems = detectedFoods
                    isAnalyzing = false
                    if detectedFoods.isEmpty {
                        errorMessage = "Aucun aliment détecté. Assurez-vous que la photo est claire et contient des aliments visibles. Vous pouvez aussi sélectionner manuellement des ingrédients.".localized
                    }
                }
            } catch {
                await MainActor.run {
                    isAnalyzing = false
                    // Si c'est une erreur de détection mais qu'on a une image, proposer un message plus utile
                    if let recognitionError = error as? FoodRecognitionError,
                       recognitionError == .noFoodsDetected {
                        errorMessage = "Aucun aliment détecté dans l'image. Assurez-vous que la photo montre clairement vos ingrédients (farine, œufs, légumes, etc.). Vérifiez aussi que Gemini ou ChatGPT est bien connecté dans les paramètres.".localized
                    } else {
                        errorMessage = "Erreur lors de l'analyse: \(error.localizedDescription). Assurez-vous que Gemini ou ChatGPT est connecté dans les paramètres.".localized
                    }
                }
            }
        }
    }
    
    private func generateRecipe() {
        guard !foodItems.isEmpty else { return }
        
        isGenerating = true
        errorMessage = nil
        
        Task {
            do {
                let recipe = try await recipeService.generateRecipe(from: foodItems)
                await MainActor.run {
                    generatedRecipe = recipe
                    isGenerating = false
                    showingRecipe = true
                }
            } catch {
                await MainActor.run {
                    isGenerating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

// MARK: - Vue caméra
struct CameraView: UIViewControllerRepresentable {
    @Binding var capturedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = true
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraView
        
        init(_ parent: CameraView) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let editedImage = info[.editedImage] as? UIImage {
                parent.capturedImage = editedImage
            } else if let originalImage = info[.originalImage] as? UIImage {
                parent.capturedImage = originalImage
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Vue détail recette
struct RecipeDetailView: View {
    let recipe: Recipe
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // En-tête
                    VStack(alignment: .leading, spacing: 8) {
                        Text(recipe.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text(recipe.description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        // Métadonnées
                        HStack(spacing: 16) {
                            if let prepTime = recipe.prepTime {
                                Label(prepTime, systemImage: "clock")
                                    .font(.caption)
                            }
                            if let cookTime = recipe.cookTime {
                                Label(cookTime, systemImage: "flame")
                                    .font(.caption)
                            }
                            if let servings = recipe.servings {
                                Label("\(servings) portions", systemImage: "person.2")
                                    .font(.caption)
                            }
                            Text(recipe.difficulty.icon)
                                .font(.caption)
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    
                    Divider()
                    
                    // Ingrédients
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingrédients".localized)
                            .font(.headline)
                        
                        ForEach(recipe.ingredients, id: \.self) { ingredient in
                            HStack(alignment: .top, spacing: 12) {
                                Text("•")
                                    .foregroundColor(AppColors.accent)
                                Text(ingredient)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                    .padding()
                    
                    Divider()
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions".localized)
                            .font(.headline)
                        
                        ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 12) {
                                    Text("\(index + 1)")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                        .frame(width: 28, height: 28)
                                        .background(AppColors.accent)
                                        .clipShape(Circle())
                                    
                                    Text(instruction)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding()
                }
                .padding(.vertical)
            }
            .navigationTitle("Recette".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
            }
        }
    }
}

