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
    
    var body: some View {
        VStack(spacing: 8) {
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
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title3)
                }
                .disabled(inputText.isEmpty || isTyping)
            }
            .padding(.horizontal, 4)
        }
        .navigationTitle("Chat IA")
        .onAppear {
            loadInitialMessage()
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

