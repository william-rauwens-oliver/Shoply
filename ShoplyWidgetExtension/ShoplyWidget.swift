//
//  ShoplyWidget.swift
//  ShoplyWidgetExtension
//
//  Created by William on 01/11/2025.
//

import WidgetKit
import SwiftUI

struct ShoplyWidget: Widget {
    let kind: String = "ShoplyWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ChatWidgetProvider()) { (entry: ChatWidgetEntry) in
            ChatAIWidgetView(entry: entry)
                .containerBackground(.fill.secondary, for: .widget)
        }
        .configurationDisplayName("Shoply Chat")
        .description("Accès rapide au chatbot IA")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct ChatWidgetProvider: TimelineProvider {
    typealias Entry = ChatWidgetEntry
    
    func placeholder(in context: Context) -> ChatWidgetEntry {
        ChatWidgetEntry(date: Date())
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ChatWidgetEntry) -> ()) {
        let entry = ChatWidgetEntry(date: Date())
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<ChatWidgetEntry>) -> ()) {
        let entry = ChatWidgetEntry(date: Date())
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

struct ChatWidgetEntry: TimelineEntry {
    let date: Date
}

struct ChatAIWidgetView: View {
    var entry: ChatWidgetEntry
    @Environment(\.widgetFamily) var family
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallChatWidget()
        case .systemMedium:
            MediumChatWidget()
        case .systemLarge:
            LargeChatWidget()
        default:
            SmallChatWidget()
        }
    }
}

// Small Widget - Design adaptatif
struct SmallChatWidget: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Fond adaptatif selon le thème
            if colorScheme == .dark {
                Color.black
            } else {
                Color.white
            }
            
            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.primary)
            
                VStack(spacing: 4) {
                    Text("Chat IA")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Assistant")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
        }
        .widgetURL(URL(string: "shoply://chat"))
    }
}

// Medium Widget
struct MediumChatWidget: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Fond adaptatif
            if colorScheme == .dark {
                Color.black
            } else {
                Color.white
            }
            
        HStack(spacing: 16) {
                    Image(systemName: "sparkles")
                    .font(.system(size: 32, weight: .medium))
                    .foregroundColor(.primary)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Chat IA Shoply")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Posez vos questions sur la mode")
                        .font(.system(size: 13, weight: .regular))
                            .foregroundColor(.secondary)
                        .lineLimit(2)
            }
            
            Spacer()
            }
            .padding()
        }
        .widgetURL(URL(string: "shoply://chat"))
    }
}

// Large Widget
struct LargeChatWidget: View {
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        ZStack {
            // Fond adaptatif
            if colorScheme == .dark {
                Color.black
            } else {
                Color.white
            }
            
        VStack(alignment: .leading, spacing: 16) {
                HStack(spacing: 12) {
                Image(systemName: "sparkles")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chat IA Shoply")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Assistant Style Intelligent")
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                    }
            }
            
            Divider()
                    .background(Color.secondary.opacity(0.3))
                
            VStack(alignment: .leading, spacing: 8) {
                    Text("Posez vos questions sur :")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Label("Conseils de style", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                        
                        Label("Assortiment de couleurs", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 13))
                    .foregroundColor(.secondary)
                
                        Label("Suggestions d'outfits", systemImage: "checkmark.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
            }
        }
                
                Spacer()
                
        HStack {
                    Spacer()
                    Text("Appuyez pour ouvrir")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.secondary.opacity(0.15))
                        )
                }
            }
            .padding()
        }
        .widgetURL(URL(string: "shoply://chat"))
    }
}

#Preview(as: .systemSmall) {
    ShoplyWidget()
} timeline: {
    ChatWidgetEntry(date: .now)
}
