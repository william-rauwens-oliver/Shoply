//
//  PrivacyConsentView.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

/// Vue de consentement RGPD - Première vue affichée
struct PrivacyConsentView: View {
    @EnvironmentObject var rgpdManager: RGDPManager
    @State private var showPrivacyPolicy = false
    
    var body: some View {
        ZStack {
            AppColors.background
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 60))
                    .foregroundColor(AppColors.primaryText)
                    .padding(.top, 40)
                
                Text("Protection de vos données")
                    .font(.playfairDisplayBold(size: 28))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Text("Nous respectons votre vie privée")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 15) {
                    PrivacyPoint(
                        icon: "checkmark.shield.fill",
                        text: "Vos données sont stockées localement sur votre appareil"
                    )
                    
                    PrivacyPoint(
                        icon: "eye.slash.fill",
                        text: "Aucune donnée n'est partagée avec des tiers"
                    )
                    
                    PrivacyPoint(
                        icon: "trash.fill",
                        text: "Vous pouvez supprimer vos données à tout moment"
                    )
                    
                    PrivacyPoint(
                        icon: "arrow.down.circle.fill",
                        text: "Vous pouvez exporter vos données quand vous le souhaitez"
                    )
                }
                .padding(.horizontal, 30)
                
                Spacer()
                
                Button(action: {
                    showPrivacyPolicy = true
                }) {
                    Text("Lire la politique de confidentialité")
                        .font(.system(size: 14))
                        .foregroundColor(AppColors.primaryText)
                }
                
                VStack(spacing: 15) {
                    Button(action: {
                        rgpdManager.acceptConsent()
                    }) {
                        Text("J'accepte")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.buttonPrimaryText)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(AppColors.buttonPrimary)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        // Même en refusant, on permet l'utilisation de l'app mais sans collecte de données
                        rgpdManager.hasConsentedToDataCollection = false
                        rgpdManager.hasAcceptedPrivacyPolicy = false
                    }) {
                        Text("Refuser")
                            .font(.system(size: 16))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 40)
            }
        }
        .sheet(isPresented: $showPrivacyPolicy) {
            PrivacyPolicyView()
        }
    }
}

struct PrivacyPoint: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(AppColors.primaryText)
                .font(.system(size: 20))
            
            Text(text)
                .font(.system(size: 16))
                .foregroundColor(AppColors.primaryText)
        }
    }
}

struct PrivacyPolicyView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Politique de Confidentialité")
                        .font(.playfairDisplayBold(size: 24))
                        .padding(.bottom, 10)
                    
                    SectionView(title: "1. Collecte des données") {
                        Text("Shoply collecte uniquement les données nécessaires au fonctionnement de l'application : vos favoris et préférences. Toutes les données sont stockées localement sur votre appareil.")
                    }
                    
                    SectionView(title: "2. Utilisation des données") {
                        Text("Vos données sont utilisées uniquement pour personnaliser votre expérience dans l'application. Aucune donnée n'est transmise à des serveurs externes.")
                    }
                    
                    SectionView(title: "3. Vos droits") {
                        Text("Conformément au RGPD, vous avez le droit de :\n• Accéder à vos données\n• Exporter vos données\n• Supprimer vos données\n• Révoquer votre consentement à tout moment")
                    }
                    
                    SectionView(title: "4. Sécurité") {
                        Text("Nous appliquons les meilleures pratiques de sécurité recommandées par l'ANSSI pour protéger vos données.")
                    }
                    
                    SectionView(title: "5. Contact") {
                        Text("Pour toute question concernant vos données, contactez-nous via les paramètres de l'application.")
                    }
                }
                .padding()
            }
            .navigationTitle("Politique de Confidentialité")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Fermer") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SectionView<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
            
            content
                .font(.system(size: 16))
                .foregroundColor(AppColors.secondaryText)
        }
    }
}

#Preview {
    PrivacyConsentView()
        .environmentObject(RGDPManager.shared)
}

