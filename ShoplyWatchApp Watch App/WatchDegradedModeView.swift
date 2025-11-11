//
//  WatchDegradedModeView.swift
//  ShoplyWatchApp Watch App
//
//  Created by William on 11/11/2025.
//

import SwiftUI

struct WatchDegradedModeView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    let onRetry: () -> Void
    let onContinue: () -> Void
    @State private var retryCount = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                
                Text("Configuration non détectée")
                    .font(.headline)
                
                Text("L'application n'a pas pu détecter la configuration depuis votre iPhone.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Vérifiez que l'app iOS est configurée")
                            .font(.caption2)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.blue)
                        Text("Assurez-vous que les deux appareils sont connectés")
                            .font(.caption2)
                    }
                }
                .padding()
                .background(Color.secondary.opacity(0.1))
                .cornerRadius(8)
                
                // Bouton pour réessayer
                Button(action: {
                    retryCount += 1
                    onRetry()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Réessayer")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
                
                // Bouton pour continuer quand même (mode dégradé)
                Button(action: {
                    onContinue()
                }) {
                    HStack {
                        Image(systemName: "arrow.right")
                        Text("Continuer quand même")
                    }
                    .font(.caption)
                    .foregroundColor(.orange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange, lineWidth: 1)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                
                if retryCount > 0 {
                    Text("Tentative \(retryCount)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .onAppear {
            // Forcer une synchronisation à l'apparition
            watchDataManager.startSync()
        }
    }
}

