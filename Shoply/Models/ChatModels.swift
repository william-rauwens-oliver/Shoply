//
//  ChatModels.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import UIKit

struct ChatMessage: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let isUser: Bool
    let timestamp: Date
    var isSystemMessage: Bool
    var imageData: Data? // Image en format Data pour la persistance
    var aiModeString: String? // Mode AI utilisé pour générer ce message (pour les messages de l'IA)
    
    init(content: String, isUser: Bool, isSystemMessage: Bool = false, imageData: Data? = nil, aiModeString: String? = nil) {
        self.id = UUID()
        self.content = content
        self.isUser = isUser
        self.timestamp = Date()
        self.isSystemMessage = isSystemMessage
        self.imageData = imageData
        self.aiModeString = aiModeString
    }
    
    // Propriété calculée pour obtenir l'image si disponible
    var image: UIImage? {
        guard let imageData = imageData else { return nil }
        return UIImage(data: imageData)
    }
    
    // Conformité à Equatable - comparer uniquement l'ID pour l'efficacité
    static func == (lhs: ChatMessage, rhs: ChatMessage) -> Bool {
        return lhs.id == rhs.id
    }
}

struct ChatConversation: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    var createdAt: Date
    var lastMessageAt: Date
    var aiMode: String // "ChatGPT", "Google Gemini" ou "Shoply AI"
    
    init(id: UUID = UUID(), title: String = "", messages: [ChatMessage] = [], createdAt: Date = Date(), aiMode: String = "ChatGPT") {
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

