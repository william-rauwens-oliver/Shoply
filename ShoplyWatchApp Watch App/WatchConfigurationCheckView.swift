//
//  WatchConfigurationCheckView.swift
//  ShoplyWatchApp
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct WatchConfigurationCheckView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    let onReceive: () -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "iphone")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
                
                Text("Configuration requise")
                    .font(.headline)
                
                Text("Veuillez configurer l'application Shoply sur votre iPhone avant d'utiliser l'application Apple Watch.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                        Text("Ouvrez l'application Shoply sur votre iPhone")
                            .font(.caption2)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                        Text("Complétez l'onboarding et configurez votre profil")
                            .font(.caption2)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                        Text("L'application se mettra à jour automatiquement")
                            .font(.caption2)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
                // Indicateur de vérification automatique
                HStack(spacing: 6) {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Vérification en cours...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 8)
            }
            .padding()
        }
        .onAppear {
            // Vérifier immédiatement à l'apparition
            onReceive()
        }
    }
}

