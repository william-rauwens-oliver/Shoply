//
//  WatchConversationsListView.swift
//  ShoplyWatchApp
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct WatchConversationsListView: View {
    let conversations: [WatchChatConversation]
    @Binding var selectedConversationId: UUID?
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 8) {
                    if conversations.isEmpty {
                        VStack(spacing: 8) {
                            Image(systemName: "message")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("Aucune conversation")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    } else {
                        ForEach(conversations) { conversation in
                            ConversationRow(conversation: conversation) {
                                selectedConversationId = conversation.id
                                dismiss()
                            }
                        }
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
            }
            .navigationTitle("Conversations")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ConversationRow: View {
    let conversation: WatchChatConversation
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(conversation.title)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(conversation.lastMessage)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                Text(conversation.lastMessageDate, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .background(Color.secondary.opacity(0.1))
            .cornerRadius(8)
        }
    }
}

