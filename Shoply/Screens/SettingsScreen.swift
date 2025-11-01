//
//  SettingsScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import AuthenticationServices
import SafariServices

/// Écran de paramètres pour configurer l'API ChatGPT
struct SettingsScreen: View {
    @StateObject private var openAIService = OpenAIService.shared
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var showingWebView = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // En-tête
                        VStack(spacing: 8) {
                            Text("Paramètres")
                                .font(.system(size: 32, weight: .light))
                                .foregroundColor(.black)
                            
                            Text("Configuration ChatGPT")
                                .font(.system(size: 16, weight: .regular))
                                .foregroundColor(.gray)
                        }
                        .padding(.top, 20)
                        
                        // Section Connexion ChatGPT
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Connexion ChatGPT")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black)
                            
                            Text("Connectez-vous à votre compte OpenAI pour utiliser les suggestions intelligentes d'outfits basées sur vos photos.")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                            
                            // Statut de connexion
                            if openAIService.isEnabled {
                                HStack {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                    Text("Connecté à ChatGPT")
                                        .font(.system(size: 14, weight: .medium))
                                        .foregroundColor(.black)
                                    Spacer()
                                    Button("Déconnecter") {
                                        disconnect()
                                    }
                                    .font(.system(size: 13, weight: .regular))
                                    .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(0)
                            } else {
                                // Bouton de connexion native
                                Button(action: {
                                    showingWebView = true
                                }) {
                                    HStack {
                                        Image(systemName: "person.circle.fill")
                                        Text("Se connecter à ChatGPT")
                                            .font(.system(size: 17, weight: .medium))
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                    }
                                    .foregroundColor(.white)
                                    .padding(.vertical, 16)
                                    .padding(.horizontal, 20)
                                    .background(Color.black)
                                    .cornerRadius(0)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Instructions simplifiées
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Comment ça marche ?")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black)
                            
                            VStack(alignment: .leading, spacing: 12) {
                                InstructionStep(
                                    number: 1,
                                    text: "Cliquez sur \"Se connecter à ChatGPT\""
                                )
                                
                                InstructionStep(
                                    number: 2,
                                    text: "Connectez-vous à votre compte OpenAI"
                                )
                                
                                InstructionStep(
                                    number: 3,
                                    text: "Accédez à vos clés API (platform.openai.com/api-keys)"
                                )
                                
                                InstructionStep(
                                    number: 4,
                                    text: "L'application détectera automatiquement votre clé"
                                )
                                
                                InstructionStep(
                                    number: 5,
                                    text: "Vous serez connecté automatiquement"
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Info coût
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Information")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.black)
                            
                            Text("L'utilisation de ChatGPT pour les suggestions d'outfits consomme des crédits de votre compte OpenAI. Les coûts sont généralement très faibles (quelques centimes par utilisation).")
                                .font(.system(size: 14, weight: .regular))
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Recharger le service pour mettre à jour l'état
                openAIService.reloadAPIKey()
            }
            .alert("Configuration", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
            .sheet(isPresented: $showingWebView) {
                NavigationStack {
                    ChatGPTConnectionWebView(onConnected: { key in
                        saveAPIKey(key)
                        showingWebView = false
                    })
                }
            }
        }
    }
    
    private func saveAPIKey(_ key: String) {
        guard !key.isEmpty else { return }
        
        // Vérifier le format (doit commencer par "sk-")
        if key.hasPrefix("sk-") {
            openAIService.setAPIKey(key)
            alertMessage = "Connexion réussie ! Vous pouvez maintenant utiliser les suggestions intelligentes d'outfits."
            showingAlert = true
        } else {
            alertMessage = "La clé API doit commencer par \"sk-\". Vérifiez que vous avez copié la bonne clé."
            showingAlert = true
        }
    }
    
    private func disconnect() {
        openAIService.setAPIKey("")
        alertMessage = "Déconnexion réussie."
        showingAlert = true
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.black)
                .cornerRadius(12)
            
            Text(text)
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.gray)
            
            Spacer()
        }
    }
}

#Preview {
    SettingsScreen()
}
