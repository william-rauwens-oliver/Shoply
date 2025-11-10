//
//  BackButtonWithLongPress.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

/// Bouton retour avec affichage "retour" lors d'un long press
struct BackButtonWithLongPress: View {
    @Environment(\.dismiss) var dismiss
    @State private var showingBackLabel = false
    
    var body: some View {
        Button {
            dismiss()
        } label: {
            HStack(spacing: 4) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                
                if showingBackLabel {
                    Text("Retour".localized)
                        .font(.system(size: 16, weight: .semibold))
                        .transition(.opacity.combined(with: .scale))
                }
            }
            .foregroundColor(AppColors.primaryText)
        }
        .simultaneousGesture(
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        showingBackLabel = true
                    }
                    
                    // Masquer après 1 seconde
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            showingBackLabel = false
                        }
                    }
                }
        )
    }
}

