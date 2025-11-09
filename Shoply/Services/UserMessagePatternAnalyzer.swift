//
//  UserMessagePatternAnalyzer.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import NaturalLanguage

/// Service pour analyser les patterns de messages de l'utilisateur
/// et générer des suggestions personnalisées basées sur l'historique
class UserMessagePatternAnalyzer {
    static let shared = UserMessagePatternAnalyzer()
    
    private init() {}
    
    // MARK: - Analyse des Patterns
    
    /// Analyse toutes les conversations de l'utilisateur pour extraire les patterns
    func analyzeUserPatterns() -> UserMessagePatterns {
        // Charger toutes les conversations
        var allConversations: [ChatConversation] = []
        if let data = UserDefaults.standard.data(forKey: "chatConversations"),
           let decoded = try? JSONDecoder().decode([ChatConversation].self, from: data) {
            allConversations = decoded
        }
        
        // Extraire tous les messages utilisateur
        var allUserMessages: [String] = []
        for conversation in allConversations {
            let userMessages = conversation.messages
                .filter { $0.isUser && !$0.isSystemMessage }
                .map { $0.content }
            allUserMessages.append(contentsOf: userMessages)
        }
        
        return extractPatterns(from: allUserMessages)
    }
    
    /// Extrait les patterns récurrents des messages utilisateur
    private func extractPatterns(from messages: [String]) -> UserMessagePatterns {
        guard !messages.isEmpty else {
            return UserMessagePatterns(
                frequentTopics: [],
                commonQuestionTypes: [],
                preferredStyle: [],
                frequentKeywords: []
            )
        }
        
        // Analyser les sujets fréquents
        let frequentTopics = extractFrequentTopics(from: messages)
        
        // Analyser les types de questions
        let commonQuestionTypes = extractQuestionTypes(from: messages)
        
        // Analyser le style préféré
        let preferredStyle = extractPreferredStyle(from: messages)
        
        // Extraire les mots-clés fréquents
        let frequentKeywords = extractFrequentKeywords(from: messages)
        
        return UserMessagePatterns(
            frequentTopics: frequentTopics,
            commonQuestionTypes: commonQuestionTypes,
            preferredStyle: preferredStyle,
            frequentKeywords: frequentKeywords
        )
    }
    
    // MARK: - Extraction de Patterns
    
    /// Extrait les sujets fréquents des messages
    private func extractFrequentTopics(from messages: [String]) -> [String] {
        var topicCounts: [String: Int] = [:]
        
        // Mots-clés de sujets
        let topicKeywords: [String: [String]] = [
            "outfit": ["outfit", "tenue", "look", "ensemble", "combinaison"],
            "météo": ["météo", "weather", "température", "froid", "chaud", "pluie", "soleil"],
            "couleur": ["couleur", "color", "rouge", "bleu", "vert", "noir", "blanc"],
            "style": ["style", "mode", "fashion", "élégant", "décontracté", "sportif"],
            "occasion": ["occasion", "événement", "soirée", "travail", "date", "vacances"],
            "garde-robe": ["garde-robe", "wardrobe", "vêtement", "habit", "robe", "pantalon"],
            "conseil": ["conseil", "suggestion", "recommandation", "aide", "help"],
            "achat": ["acheter", "buy", "achat", "shopping", "magasin", "boutique"]
        ]
        
        for message in messages {
            let lowercased = message.lowercased()
            for (topic, keywords) in topicKeywords {
                for keyword in keywords {
                    if lowercased.contains(keyword) {
                        topicCounts[topic, default: 0] += 1
                        break
                    }
                }
            }
        }
        
        // Retourner les 5 sujets les plus fréquents
        return topicCounts.sorted { $0.value > $1.value }
            .prefix(5)
            .map { $0.key }
    }
    
    /// Extrait les types de questions fréquents
    private func extractQuestionTypes(from messages: [String]) -> [QuestionType] {
        var typeCounts: [QuestionType: Int] = [:]
        
        for message in messages {
            let lowercased = message.lowercased()
            
            if lowercased.hasPrefix("comment") || lowercased.hasPrefix("how") {
                typeCounts[.howTo, default: 0] += 1
            } else if lowercased.hasPrefix("quel") || lowercased.hasPrefix("quelle") || lowercased.hasPrefix("which") || lowercased.hasPrefix("what") {
                typeCounts[.what, default: 0] += 1
            } else if lowercased.hasPrefix("pourquoi") || lowercased.hasPrefix("why") {
                typeCounts[.why, default: 0] += 1
            } else if lowercased.contains("recommand") || lowercased.contains("suggest") || lowercased.contains("conseil") {
                typeCounts[.recommendation, default: 0] += 1
            } else if lowercased.contains("combien") || lowercased.contains("how much") || lowercased.contains("how many") {
                typeCounts[.quantity, default: 0] += 1
            } else if lowercased.contains("?") {
                typeCounts[.general, default: 0] += 1
            } else {
                typeCounts[.statement, default: 0] += 1
            }
        }
        
        // Retourner les 3 types les plus fréquents
        return typeCounts.sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }
    
    /// Extrait le style préféré de l'utilisateur
    private func extractPreferredStyle(from messages: [String]) -> [String] {
        let styleKeywords: [String: [String]] = [
            "décontracté": ["décontracté", "casual", "relax", "confortable", "simple"],
            "élégant": ["élégant", "elegant", "chic", "sophistiqué", "raffiné"],
            "sportif": ["sportif", "sport", "athletic", "sportswear", "training"],
            "professionnel": ["professionnel", "professional", "travail", "work", "bureau", "office"],
            "soirée": ["soirée", "evening", "night", "party", "fête", "gala"]
        ]
        
        var styleCounts: [String: Int] = [:]
        
        for message in messages {
            let lowercased = message.lowercased()
            for (style, keywords) in styleKeywords {
                for keyword in keywords {
                    if lowercased.contains(keyword) {
                        styleCounts[style, default: 0] += 1
                        break
                    }
                }
            }
        }
        
        return styleCounts.sorted { $0.value > $1.value }
            .prefix(3)
            .map { $0.key }
    }
    
    /// Extrait les mots-clés les plus fréquents
    private func extractFrequentKeywords(from messages: [String]) -> [String] {
        var wordCounts: [String: Int] = [:]
        
        // Utiliser NaturalLanguage pour extraire les mots significatifs
        let tagger = NLTagger(tagSchemes: [.lexicalClass])
        
        for message in messages {
            tagger.string = message
            let range = message.startIndex..<message.endIndex
            
            tagger.enumerateTags(in: range, unit: .word, scheme: .lexicalClass) { tag, tokenRange in
                if let tag = tag, tag == .noun || tag == .adjective || tag == .verb {
                    let word = String(message[tokenRange]).lowercased()
                    // Filtrer les mots trop courts ou trop communs
                    if word.count > 3 && !stopWords.contains(word) {
                        wordCounts[word, default: 0] += 1
                    }
                }
                return true
            }
        }
        
        // Retourner les 10 mots-clés les plus fréquents
        return wordCounts.sorted { $0.value > $1.value }
            .prefix(10)
            .map { $0.key }
    }
    
    // MARK: - Génération de Suggestions
    
    /// Génère des suggestions personnalisées basées sur les patterns de l'utilisateur
    func generatePersonalizedSuggestions(patterns: UserMessagePatterns, language: String = "fr") -> [String] {
        var suggestions: [String] = []
        
        // Suggestions basées sur les sujets fréquents
        for topic in patterns.frequentTopics.prefix(3) {
            let topicSuggestions = getTopicSuggestions(for: topic, questionTypes: patterns.commonQuestionTypes, language: language)
            suggestions.append(contentsOf: topicSuggestions)
        }
        
        // Suggestions basées sur le style préféré
        for style in patterns.preferredStyle.prefix(2) {
            let styleSuggestions = getStyleSuggestions(for: style, language: language)
            suggestions.append(contentsOf: styleSuggestions)
        }
        
        // Si pas assez de suggestions, ajouter des suggestions génériques
        if suggestions.count < 4 {
            let genericSuggestions = getGenericSuggestions(language: language)
            suggestions.append(contentsOf: genericSuggestions)
        }
        
        // Retourner jusqu'à 6 suggestions uniques
        return Array(Set(suggestions)).prefix(6).map { $0 }
    }
    
    // MARK: - Suggestions par Catégorie
    
    private func getTopicSuggestions(for topic: String, questionTypes: [QuestionType], language: String) -> [String] {
        // questionType peut être utilisé pour personnaliser davantage les suggestions à l'avenir
        _ = questionTypes.first ?? .what
        
        let suggestions: [String: [String]] = [
            "outfit": language == "fr" ? [
                "Quel outfit me conseilles-tu pour aujourd'hui ?",
                "Comment créer un outfit élégant ?",
                "Quelle tenue pour une soirée ?",
                "Peux-tu me suggérer un look décontracté ?"
            ] : [
                "What outfit do you recommend for today?",
                "How to create an elegant outfit?",
                "What to wear for an evening?",
                "Can you suggest a casual look?"
            ],
            "météo": language == "fr" ? [
                "Quel vêtement pour cette météo ?",
                "Que porter quand il fait froid ?",
                "Comment s'habiller pour la pluie ?",
                "Quelle tenue pour le soleil ?"
            ] : [
                "What to wear for this weather?",
                "What to wear when it's cold?",
                "How to dress for rain?",
                "What outfit for sunny weather?"
            ],
            "couleur": language == "fr" ? [
                "Quelle couleur me va le mieux ?",
                "Comment associer les couleurs ?",
                "Quelle couleur pour cette occasion ?",
                "Peux-tu me conseiller sur les couleurs ?"
            ] : [
                "What color suits me best?",
                "How to match colors?",
                "What color for this occasion?",
                "Can you advise me on colors?"
            ],
            "style": language == "fr" ? [
                "Comment trouver mon style ?",
                "Quel style me correspond ?",
                "Peux-tu m'aider à définir mon style ?",
                "Comment améliorer mon style ?"
            ] : [
                "How to find my style?",
                "What style suits me?",
                "Can you help me define my style?",
                "How to improve my style?"
            ],
            "garde-robe": language == "fr" ? [
                "Comment organiser ma garde-robe ?",
                "Quels vêtements essentiels ?",
                "Comment compléter ma garde-robe ?",
                "Quels vêtements manquent à ma garde-robe ?"
            ] : [
                "How to organize my wardrobe?",
                "What essential clothes?",
                "How to complete my wardrobe?",
                "What clothes are missing from my wardrobe?"
            ]
        ]
        
        return suggestions[topic]?.prefix(2).map { $0 } ?? []
    }
    
    private func getStyleSuggestions(for style: String, language: String) -> [String] {
        let suggestions: [String: [String]] = [
            "décontracté": language == "fr" ? [
                "Quel outfit décontracté pour aujourd'hui ?",
                "Comment rester décontracté tout en étant stylé ?"
            ] : [
                "What casual outfit for today?",
                "How to stay casual while being stylish?"
            ],
            "élégant": language == "fr" ? [
                "Comment créer un look élégant ?",
                "Quelle tenue élégante pour cette occasion ?"
            ] : [
                "How to create an elegant look?",
                "What elegant outfit for this occasion?"
            ],
            "sportif": language == "fr" ? [
                "Quel outfit sportif me conseilles-tu ?",
                "Comment s'habiller pour le sport ?"
            ] : [
                "What sporty outfit do you recommend?",
                "How to dress for sports?"
            ]
        ]
        
        return suggestions[style] ?? []
    }
    
    private func getGenericSuggestions(language: String) -> [String] {
        return language == "fr" ? [
            "Quel outfit me conseilles-tu ?",
            "Comment créer un look stylé ?",
            "Quelle tenue pour aujourd'hui ?",
            "Peux-tu m'aider à choisir mes vêtements ?"
        ] : [
            "What outfit do you recommend?",
            "How to create a stylish look?",
            "What to wear today?",
            "Can you help me choose my clothes?"
        ]
    }
    
    // MARK: - Mots vides (stop words)
    
    private let stopWords: Set<String> = [
        "le", "la", "les", "un", "une", "des", "de", "du", "et", "ou", "mais", "pour", "avec", "sans",
        "the", "a", "an", "and", "or", "but", "for", "with", "without", "is", "are", "was", "were",
        "que", "qui", "quoi", "comment", "pourquoi", "quel", "quelle", "quels", "quelles",
        "what", "which", "who", "how", "why", "when", "where"
    ]
}

// MARK: - Structures de Données

struct UserMessagePatterns {
    let frequentTopics: [String]
    let commonQuestionTypes: [QuestionType]
    let preferredStyle: [String]
    let frequentKeywords: [String]
}

enum QuestionType {
    case howTo
    case what
    case why
    case recommendation
    case quantity
    case general
    case statement
}

