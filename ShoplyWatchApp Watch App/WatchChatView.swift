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
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            // Messages - zone principale (sans header)
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 10) {
                        ForEach(messages) { message in
                            MessageView(message: message)
                                .id(message.id)
                        }
                        
                        if isTyping {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.5)
                                    .tint(.white)
                                Text("Shoply IA réfléchit...")
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                            .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 6)
                    .padding(.bottom, 2)
                }
                .onChange(of: messages.count) { _, _ in
                    if let lastMessage = messages.last {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // Input en bas
            HStack(spacing: 8) {
                TextField("Posez une question...", text: $inputText)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(
                        ZStack {
                            // Fond avec gradient
                            RoundedRectangle(cornerRadius: 18)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: isInputFocused
                                            ? [Color.blue.opacity(0.25), Color.blue.opacity(0.15)]
                                            : [Color.gray.opacity(0.2), Color.gray.opacity(0.15)]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                            
                            // Bordure avec gradient (simulée avec overlay)
                            RoundedRectangle(cornerRadius: 18)
                                .stroke(
                                    isInputFocused
                                        ? Color.blue.opacity(0.6)
                                        : Color.white.opacity(0.15),
                                    lineWidth: isInputFocused ? 1.5 : 1
                                )
                        }
                        .shadow(color: isInputFocused ? Color.blue.opacity(0.3) : Color.black.opacity(0.4), radius: isInputFocused ? 10 : 5, x: 0, y: 3)
                    )
                    .focused($isInputFocused)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: inputText.isEmpty || isTyping 
                                    ? [Color.gray.opacity(0.3), Color.gray.opacity(0.2)]
                                    : [Color.blue, Color.blue.opacity(0.8)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: inputText.isEmpty || isTyping ? .clear : Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .disabled(inputText.isEmpty || isTyping)
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 8)
            .padding(.top, 4)
            .padding(.bottom, 6)
        }
        .background(Color.black)
        .navigationBarHidden(true)
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
        guard !inputText.isEmpty, !isTyping else { return }
        
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
        isInputFocused = false
        
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

// Vue de message simplifiée
struct MessageView: View {
    let message: WatchChatMessage
    
    var body: some View {
        HStack(alignment: .top, spacing: 6) {
            if message.isUser {
                Spacer(minLength: 15)
            }
            
            Text(message.text)
                .font(.system(size: message.isUser ? 14 : 16))
                .fontWeight(message.isUser ? .regular : .medium)
                .foregroundColor(.white)
                .padding(.horizontal, message.isUser ? 12 : 14)
                .padding(.vertical, message.isUser ? 10 : 12)
                .background(
                    message.isUser
                        ? LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.blue.opacity(0.9)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        : LinearGradient(
                            gradient: Gradient(colors: [Color.gray.opacity(0.45), Color.gray.opacity(0.35)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                )
                .cornerRadius(14)
            
            if !message.isUser {
                Spacer(minLength: 15)
            }
        }
    }
}
