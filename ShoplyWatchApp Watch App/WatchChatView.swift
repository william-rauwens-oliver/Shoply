//
//  WatchChatView.swift
//  ShoplyWatchApp
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct WatchChatView: View {
    @EnvironmentObject var watchDataManager: WatchDataManager
    @State private var messages: [WatchChatMessage] = []
    @State private var inputText = ""
    @State private var isTyping = false
    @State private var conversations: [WatchChatConversation] = []
    @State private var showingConversations = false
    @State private var selectedConversationId: UUID?
    
    var body: some View {
        VStack(spacing: 8) {
            // Bouton pour voir les conversations
            if !conversations.isEmpty {
                Button(action: {
                    showingConversations = true
                }) {
                    HStack {
                        Image(systemName: "message.fill")
                        Text("Historique (\(conversations.count))")
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Messages
            ScrollView {
                VStack(spacing: 6) {
                    ForEach(messages) { message in
                        ChatBubble(message: message)
                    }
                    
                    if isTyping {
                        HStack {
                            ProgressView()
                                .scaleEffect(0.7)
                            Text("Shoply IA réfléchit...")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .padding(.horizontal, 4)
            }
            
            // Input
            HStack(spacing: 6) {
                TextField("Posez une question...", text: $inputText)
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(8)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title3)
                }
                .disabled(inputText.isEmpty || isTyping)
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Chat IA")
        .sheet(isPresented: $showingConversations) {
            WatchConversationsListView(conversations: conversations, selectedConversationId: $selectedConversationId)
        }
        .onAppear {
            loadConversations()
            loadInitialMessage()
        }
        .onChange(of: selectedConversationId) { _, newId in
            if let id = newId {
                loadConversation(id: id)
            }
        }
    }
    
    private func loadConversations() {
        conversations = watchDataManager.getChatConversations()
    }
    
    private func loadConversation(id: UUID) {
        if let conversation = watchDataManager.getChatConversation(id: id) {
            messages = conversation.messages
        }
    }
    
    private func loadInitialMessage() {
        if messages.isEmpty {
            messages.append(WatchChatMessage(
                id: UUID(),
                text: "Bonjour ! Je suis Shoply IA. Comment puis-je vous aider avec votre style aujourd'hui ?",
                isUser: false,
                timestamp: Date()
            ))
        }
    }
    
    private func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        let userMessage = WatchChatMessage(
            id: UUID(),
            text: inputText,
            isUser: true,
            timestamp: Date()
        )
        messages.append(userMessage)
        
        let question = inputText
        inputText = ""
        isTyping = true
        
        Task {
            let response = await watchDataManager.sendChatMessage(question)
            await MainActor.run {
                messages.append(WatchChatMessage(
                    id: UUID(),
                    text: response,
                    isUser: false,
                    timestamp: Date()
                ))
                isTyping = false
            }
        }
    }
}

struct ChatBubble: View {
    let message: WatchChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            Text(message.text)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(message.isUser ? Color.blue : Color.secondary.opacity(0.2))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(8)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

