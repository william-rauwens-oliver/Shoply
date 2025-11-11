//
//  FloatingChatButton.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct FloatingChatButton: View {
    @State private var showingChat = false
    @State private var showingConversations = false
    
    var body: some View {
        Menu {
            Button {
                showingChat = true
            } label: {
                Label("Nouvelle conversation".localized, systemImage: "square.and.pencil")
            }
            
            Button {
                showingConversations = true
            } label: {
                Label("Historique des conversations".localized, systemImage: "message.fill")
            }
        } label: {
            ZStack {
                // Petite bulle ronde avec effet liquid glass amélioré pour mode sombre
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.buttonPrimary.opacity(0.95),
                                AppColors.buttonPrimary.opacity(0.85)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        // Gradient adaptatif selon le mode
                                        AppColors.buttonPrimaryText.opacity(0.4),
                                        AppColors.buttonPrimaryText.opacity(0.2)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
                    .shadow(color: AppColors.buttonPrimary.opacity(0.4), radius: 10, x: 0, y: 5)
                    .shadow(color: AppColors.buttonPrimary.opacity(0.3), radius: 20, x: 0, y: 10)
                
                // Icône sparkles avec effet brillant
                Image(systemName: "sparkles")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(AppColors.buttonPrimaryText)
                    .symbolEffect(.pulse, options: .repeating.speed(0.7))
            }
            .frame(width: 56, height: 56)
        }
        .fullScreenCover(isPresented: $showingChat) {
            ChatAIScreen(conversationId: nil, initialMessages: [], initialAIMode: .gemini)
        }
        .fullScreenCover(isPresented: $showingConversations) {
            ChatConversationsScreen()
        }
    }
}

#Preview {
    ZStack {
        AppColors.background
            .ignoresSafeArea()
        
        VStack {
            Spacer()
            HStack {
                Spacer()
                FloatingChatButton()
                    .padding()
            }
        }
    }
}

