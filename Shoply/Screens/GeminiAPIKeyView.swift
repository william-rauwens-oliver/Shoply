//
//  GeminiAPIKeyView.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct GeminiAPIKeyView: View {
    @Binding var isPresented: Bool
    let onSave: (String) -> Void
    @State private var apiKey = ""
    @StateObject private var settingsManager = AppSettingsManager.shared
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        Text("Entrez votre clé API Google Gemini".localized)
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("Vous pouvez obtenir votre clé API sur : https://makersuite.google.com/app/apikey".localized)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                        
                        TextField("Votre clé API Gemini".localized, text: $apiKey)
                            .textFieldStyle(.plain)
                            .padding()
                            .background(AppColors.buttonSecondary)
                            .roundedCorner(16)
                            .autocapitalization(.none)
                            .autocorrectionDisabled()
                        
                        Button(action: {
                            onSave(apiKey)
                            isPresented = false
                        }) {
                            Text("Enregistrer".localized)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(AppColors.buttonPrimary)
                                .roundedCorner(16)
                        }
                        .disabled(apiKey.isEmpty)
                    }
                    .padding()
                }
            }
            .navigationTitle("Clé API Gemini".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Annuler".localized) {
                        isPresented = false
                    }
                }
            }
        }
        .id("gemini-key-\(settingsManager.selectedLanguage)")
    }
}

#Preview {
    GeminiAPIKeyView(isPresented: .constant(true), onSave: { _ in })
}

