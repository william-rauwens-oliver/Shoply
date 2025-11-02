//
//  ChatModels.swift
//  ShoplyCore - Android Compatible
//
//  Created by William on 02/11/2025.
//

import Foundation

struct ChatMessage: Identifiable, Codable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    var isSystemMessage: Bool
    
    init(content: String, isUser: Bool, isSystemMessage: Bool = false) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.isSystemMessage = isSystemMessage
    }
}

struct ChatConversation: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    var createdAt: Date
    var lastMessageAt: Date
    var aiMode: String // "ChatGPT", "Google Gemini" ou "Shoply AI"
    
    init(id: UUID = UUID(), title: String = "", messages: [ChatMessage] = [], createdAt: Date = Date(), aiMode: String = "Shoply AI") {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.lastMessageAt = messages.last?.timestamp ?? createdAt
        self.aiMode = aiMode
    }
    
    var preview: String {
        return messages.last?.content ?? ""
    }
}

