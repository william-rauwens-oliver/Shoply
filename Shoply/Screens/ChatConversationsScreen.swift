//
//  ChatConversationsScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct ChatConversationsScreen: View {
    @StateObject private var settingsManager = AppSettingsManager.shared
    @State private var conversations: [ChatConversation] = []
    @State private var showingNewChat = false
    @State private var showingDeleteAllAlert = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                if conversations.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "message.fill")
                            .font(.system(size: 64))
                            .foregroundColor(AppColors.secondaryText)
                        
                        Text("Aucune conversation".localized)
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(AppColors.primaryText)
                        
                        Text("Démarrrez une nouvelle conversation pour obtenir des conseils de style !".localized)
                            .font(.system(size: 14))
                            .foregroundColor(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                } else {
                    List {
                        ForEach(conversations.sorted(by: { $0.lastMessageAt > $1.lastMessageAt })) { conversation in
                            NavigationLink(destination: ChatAIScreen(conversationId: conversation.id, initialMessages: conversation.messages, initialAIMode: {
                                let mode: ChatAIScreen.AIMode
                                switch conversation.aiMode {
                                case "Apple Intelligence":
                                    mode = .appleIntelligence
                                case "Shoply AI", "Gemini", "Advanced", "ChatGPT":
                                    mode = .shoplyAI
                                default:
                                    // Utiliser Apple Intelligence par défaut si disponible
                                    if #available(iOS 18.0, *), AppleIntelligenceServiceWrapper.shared.isEnabled {
                                        mode = .appleIntelligence
                                    } else {
                                        mode = .shoplyAI
                                    }
                                }
                                return mode
                            }())) {
                                ConversationRow(conversation: conversation)
                            }
                        }
                        .onDelete(perform: deleteConversations)
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Conversations")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.primaryText)
                    }
                }
                
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if !conversations.isEmpty {
                        Menu {
                            Button(role: .destructive) {
                                deleteAllConversations()
                            } label: {
                                Label("Supprimer tout", systemImage: "trash")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(AppColors.buttonPrimary)
                        }
                    }
                    
                    Button {
                        showingNewChat = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundColor(AppColors.buttonPrimary)
                    }
                }
            }
            .alert("Supprimer toutes les conversations ?", isPresented: $showingDeleteAllAlert) {
                Button("Annuler", role: .cancel) { }
                Button("Supprimer", role: .destructive) {
                    deleteAllConversationsConfirmed()
                }
            } message: {
                Text("Cette action est irréversible")
            }
        }
        .sheet(isPresented: $showingNewChat) {
            ChatAIScreen(conversationId: nil, initialMessages: [], initialAIMode: nil)
        }
        .onAppear {
            loadConversations()
        }
    }
    
    private func loadConversations() {
        if let data = UserDefaults.standard.data(forKey: "chatConversations"),
           let decoded = try? JSONDecoder().decode([ChatConversation].self, from: data) {
            conversations = decoded
        }
    }
    
    private func deleteConversations(at offsets: IndexSet) {
        conversations.remove(atOffsets: offsets)
        saveConversations()
    }
    
    private func deleteAllConversations() {
        showingDeleteAllAlert = true
    }
    
    private func deleteAllConversationsConfirmed() {
        conversations.removeAll()
        saveConversations()
    }
    
    private func saveConversations() {
        if let encoded = try? JSONEncoder().encode(conversations) {
            UserDefaults.standard.set(encoded, forKey: "chatConversations")
            // Synchronisation iCloud désactivée temporairement pour éviter les crashes
            // La synchronisation peut être faite manuellement depuis SettingsScreen
            // Task {
            //     try? await CloudKitService.shared.saveConversations()
            // }
        }
    }
}

struct ConversationRow: View {
    let conversation: ChatConversation
    
    var body: some View {
        HStack(spacing: 12) {
            // Icône de conversation
            // Logo IA avec design amélioré pour mode sombre
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                AppColors.buttonPrimary.opacity(0.15),
                                AppColors.buttonPrimary.opacity(0.08)
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
                                        AppColors.buttonPrimary.opacity(0.3),
                                        AppColors.buttonPrimary.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                
                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(AppColors.buttonPrimary)
            }
            .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title.isEmpty ? "Nouvelle conversation" : conversation.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColors.primaryText)
                    .lineLimit(1)
                
                Text(conversation.preview)
                    .font(.system(size: 14))
                    .foregroundColor(AppColors.secondaryText)
                    .lineLimit(2)
                
                HStack(spacing: 8) {
                    Label(conversation.aiMode, systemImage: (conversation.aiMode == "ChatGPT" || conversation.aiMode == "Google Gemini") ? "brain" : "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.secondaryText)
                    
                    Text(conversation.lastMessageAt, style: .relative)
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.secondaryText)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ChatConversationsScreen()
}

