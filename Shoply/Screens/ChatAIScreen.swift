//
//  ChatAIScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI
import PhotosUI

struct ChatAIScreen: View {
    let initialMessages: [ChatMessage]
    let initialAIMode: AIMode
    
    @StateObject private var geminiService = GeminiService.shared
    @StateObject private var appleIntelligenceWrapper = AppleIntelligenceServiceWrapper.shared
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var wardrobeService = WardrobeService()
    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var settingsManager = AppSettingsManager.shared
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var aiMode: AIMode
    @State private var conversationId: UUID
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @Environment(\.dismiss) var dismiss
    
    enum AIMode: String, CaseIterable {
        case appleIntelligence = "Apple Intelligence"
        case gemini = "Gemini"
        case shoplyAI = "Shoply AI"
    }
    
    init(conversationId: UUID? = nil, initialMessages: [ChatMessage] = [], initialAIMode: AIMode? = nil) {
        self.initialMessages = initialMessages
        
        // Protection contre les crashes lors de l'initialisation
        // Utiliser un mode par défaut sûr
        let defaultMode: AIMode
        
        // Si un mode est fourni, l'utiliser
        if let providedMode = initialAIMode {
            self.initialAIMode = providedMode
            _aiMode = State(initialValue: providedMode)
            _conversationId = State(initialValue: conversationId ?? UUID())
            return
        }
        
        // Sinon, utiliser Shoply AI par défaut (toujours disponible et sûr)
        // La détection des autres modes se fera dans onAppear pour éviter les crashes
        defaultMode = .shoplyAI
        
        self.initialAIMode = defaultMode
        _aiMode = State(initialValue: defaultMode)
        _conversationId = State(initialValue: conversationId ?? UUID())
    }
    
    // Vérifier si iOS 18.0 est disponible
    private var isIOS18Available: Bool {
        if #available(iOS 18.0, *) {
            return true
        } else {
            return false
        }
    }
    
    // Computed property pour obtenir les modes IA disponibles dynamiquement
    private var availableAIModes: [AIMode] {
        var modes: [AIMode] = [.shoplyAI] // Shoply AI toujours disponible
        
        // Ajouter Apple Intelligence si disponible
        // Sur iOS 18+, afficher Apple Intelligence si l'appareil est supporté
        if #available(iOS 18.0, *) {
            // Vérifier le wrapper (qui observe le service)
            if appleIntelligenceWrapper.isEnabled {
                modes.insert(.appleIntelligence, at: 0)
            }
        }
        
        // Ajouter Gemini si disponible
        if geminiService.isEnabled {
            modes.append(.gemini)
        }
        
        // Debug: afficher les modes disponibles
        print("🔍 Modes IA disponibles dans le picker: \(modes.map { $0.rawValue })")
        if #available(iOS 18.0, *) {
            print("   - Apple Intelligence (wrapper.isEnabled): \(appleIntelligenceWrapper.isEnabled)")
        }
        print("   - Gemini (isEnabled): \(geminiService.isEnabled)")
        
        return modes
    }
    
    private let clothingKeywords = [
        "outfit", "vêtement", "tenue", "habit", "robe", "pantalon", "chemise", "t-shirt", "jean", "jeans",
        "veste", "manteau", "chaussure", "botte", "basket", "sac", "accessoire", "pull", "sweat", "sweatshirt",
        "garde-robe", "style", "mode", "fashion", "dress", "clothing", "wardrobe", "porter", "porterai", "porté",
        "météo", "weather", "température", "temperature", "saisonnier", "seasonal", "sport", "sportif",
        "couleur", "color", "matière", "material", "genre", "gender", "conseil", "conseille", "recommand",
        "advice", "suggestion", "recommandation", "recommendation", "chaud", "cold", "quel", "quelle", "quels",
        "froid", "hot", "pluie", "rain", "soleil", "sun", "neige", "snow", "mieux", "meilleur", "adapté", "adaptée"
    ]
    
    // Détecter si on est sur iPad
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    // Largeur maximale du contenu pour iPad (centré)
    private var maxContentWidth: CGFloat {
        isIPad ? 700 : .infinity
    }
    
    // Vue principale du contenu
    private var contentView: some View {
        VStack(spacing: 0) {
            // Zone des messages avec design épuré
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: isIPad ? 24 : 20) {
                        // Message de bienvenue
                        if messages.isEmpty {
                            WelcomeMessageView(isIPad: isIPad)
                                .padding(.top, isIPad ? 60 : 40)
                                .id("welcome")
                        }
                        
                        // Messages avec espacement optimisé
                        ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                            MessageBubble(message: message, isIPad: isIPad)
                                .id(message.id)
                        }
                        
                        // Indicateur de chargement moderne
                        if isSending {
                            LoadingIndicatorView(isIPad: isIPad)
                                .padding(.top, isIPad ? 8 : 4)
                                .id("loading")
                        }
                        
                        // Spacer pour pousser vers le bas
                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding(.horizontal, isIPad ? 40 : 20)
                    .padding(.vertical, isIPad ? 32 : 20)
                    .frame(maxWidth: maxContentWidth)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
                .defaultScrollAnchor(.bottom)
                .onAppear {
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: messages.count) { oldValue, newValue in
                    if newValue > oldValue {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            scrollToMessage(proxy: proxy)
                        }
                    }
                }
                .onChange(of: isSending) { oldValue, newValue in
                    if newValue {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                            withAnimation(.easeOut(duration: 0.4)) {
                                proxy.scrollTo("loading", anchor: .bottom)
                            }
                        }
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            scrollToMessage(proxy: proxy)
                        }
                    }
                }
                .onChange(of: aiMode) { oldValue, newValue in
                    if oldValue != newValue {
                        handleAIModeChange(newValue: newValue, proxy: proxy)
                    }
                }
            }
            
            // Suggestions de messages
            if messages.isEmpty || (messages.count <= 2 && messages.allSatisfy { !$0.isUser }) {
                MessageSuggestionsView(
                    suggestions: getSuggestions(),
                    onSuggestionTapped: { suggestion in
                        inputText = suggestion
                    },
                    isIPad: isIPad,
                    maxWidth: maxContentWidth
                )
                .padding(.horizontal, isIPad ? 40 : 20)
                .padding(.vertical, isIPad ? 12 : 10)
            }
            
            // Séparateur
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 0.5)
                .padding(.horizontal, isIPad ? 40 : 20)
            
            // Zone de saisie
            ModernInputArea(
                inputText: $inputText,
                isSending: isSending,
                isIPad: isIPad,
                selectedPhoto: $selectedPhoto,
                selectedImage: $selectedImage,
                onSend: sendMessage,
                maxWidth: maxContentWidth
            )
            .onChange(of: selectedPhoto) { oldValue, newValue in
                Task {
                    if let newValue = newValue {
                        if let data = try? await newValue.loadTransferable(type: Data.self),
                           let image = UIImage(data: data) {
                            await MainActor.run {
                                selectedImage = image
                            }
                        }
                    } else {
                        selectedImage = nil
                    }
                }
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Fond opaque simple
                AppColors.background
                    .ignoresSafeArea()
                
                contentView
            }
            .navigationBarTitleDisplayMode(isIPad ? .large : .inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    ChatHeaderView(
                        isIPad: isIPad,
                        availableModes: availableAIModes,
                        selectedMode: $aiMode
                    )
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(AppColors.buttonSecondary)
                                .frame(width: isIPad ? 36 : 32, height: isIPad ? 36 : 32)
                            
                            Image(systemName: "xmark")
                                .font(.system(size: isIPad ? 16 : 14, weight: .semibold))
                                .foregroundColor(AppColors.primaryText)
                        }
                        .shadow(color: AppColors.shadow.opacity(0.1), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if isIPad {
                    // Sélecteur IA en bas pour iPad
                    ModernAIPicker(
                        availableModes: availableAIModes,
                        selectedMode: $aiMode,
                        maxWidth: maxContentWidth
                    )
                }
            }
        }
        .id("chat-\(settingsManager.selectedLanguage)")
        .onAppear {
            if initialMessages.isEmpty {
                loadMessages()
            } else {
                messages = initialMessages
            }
        }
        .onChange(of: messages) { oldValue, newValue in
            // Scroller vers le bas quand les messages changent (chargement d'une conversation)
            if newValue.count > 0 && oldValue.count == 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    // Le scroll sera géré par le ScrollViewReader dans onChange(of: messages.count)
                }
            }
        }
        .onChange(of: aiMode) { oldValue, newValue in
            // Ne sauvegarder que si il y a des messages utilisateur
            if messages.contains(where: { $0.isUser }) {
                saveConversation()
            }
        }
        .onDisappear {
            // Nettoyer les conversations vides à la fermeture
            let hasUserMessages = messages.contains { $0.isUser }
            if hasUserMessages {
                saveConversation()
            } else {
                removeEmptyConversation()
            }
        }
    }
    
    private func sendMessage() {
        let question = inputText.trimmingCharacters(in: .whitespaces)
        guard (!question.isEmpty || selectedImage != nil),
              !isSending else { return }
        
        // Convertir l'image en Data si disponible
        let imageData = selectedImage?.jpegData(compressionQuality: 0.7)
        let userMessage = ChatMessage(
            content: question.isEmpty ? "Photo envoyée" : question,
            isUser: true,
            imageData: imageData
        )
        messages.append(userMessage)
        saveConversation()
        
        let currentImage = selectedImage ?? userMessage.image
        inputText = ""
        selectedImage = nil
        selectedPhoto = nil
        isSending = true
        
        Task { @MainActor in
            do {
                // Obtenir le contexte
                let userProfile = dataManager.loadUserProfile() ?? UserProfile()
                let currentWeather = weatherService.currentWeather
                let wardrobeItems = wardrobeService.items
                
                // Envoyer la question à l'IA selon le mode sélectionné
                let response: String
                let questionText = question.isEmpty ? "Analyse cette image" : question
                
                // Utiliser le mode sélectionné dans le picker
                if aiMode == .appleIntelligence {
                    // Apple Intelligence sélectionné
                    if #available(iOS 18.0, *), appleIntelligenceWrapper.isEnabled {
                        response = try await appleIntelligenceWrapper.askAboutClothing(
                            question: questionText,
                            userProfile: userProfile,
                            currentWeather: currentWeather,
                            wardrobeItems: wardrobeItems
                        )
                    } else {
                        // Apple Intelligence non disponible - utiliser Shoply AI
                        response = await answerWithLocalAI(
                            question: questionText,
                            userProfile: userProfile,
                            currentWeather: currentWeather,
                            wardrobeItems: wardrobeItems,
                            image: currentImage
                        )
                    }
                } else if aiMode == .gemini {
                    // Gemini sélectionné - LLM conversationnel polyvalent
                    if geminiService.isEnabled {
                        // Passer l'historique de conversation pour un dialogue naturel
                        let conversationHistory = messages.filter { !$0.isSystemMessage }
                        response = try await geminiService.askAboutClothing(
                            question: questionText,
                            userProfile: userProfile,
                            currentWeather: currentWeather,
                            wardrobeItems: wardrobeItems,
                            image: currentImage,
                            conversationHistory: conversationHistory
                        )
                    } else {
                        // Gemini non disponible - utiliser Shoply AI sans message (silencieux)
                        response = await answerWithLocalAI(
                            question: questionText,
                            userProfile: userProfile,
                            currentWeather: currentWeather,
                            wardrobeItems: wardrobeItems,
                            image: currentImage
                        )
                    }
                } else {
                    // Shoply AI sélectionnée - LLM avec 500k paramètres créé par William
                    // Utiliser le LLM Shoply AI (pas Gemini)
                    response = await answerWithLocalAI(
                        question: questionText,
                        userProfile: userProfile,
                        currentWeather: currentWeather,
                        wardrobeItems: wardrobeItems,
                        image: currentImage
                    )
                }
                
                await MainActor.run {
                    let responseMessage = ChatMessage(content: response, isUser: false)
                    messages.append(responseMessage)
                    saveConversation()
                    isSending = false
                }
            } catch {
                await MainActor.run {
                    var errorMessage: String
                    
                    // Gestion spécifique des erreurs selon le service IA
                    if aiMode == .appleIntelligence, #available(iOS 18.0, *), let appleError = error as? AppleIntelligenceError {
                        switch appleError {
                        case .notAvailable:
                            errorMessage = "Apple Intelligence n'est pas disponible sur cet appareil.".localized
                        case .noItems:
                            errorMessage = "Votre garde-robe est vide. Ajoutez des vêtements d'abord.".localized
                        case .generationFailed(_):
                            // Basculer automatiquement sur Shoply AI sans afficher de message d'erreur
                            fallbackToLocalAI(question: question)
                            return
                        }
                    } else if aiMode == .gemini, let geminiError = error as? GeminiError {
                        switch geminiError {
                        case .apiKeyMissing:
                            errorMessage = "Clé API Gemini manquante. Veuillez la configurer dans les paramètres.".localized
                        case .apiErrorWithMessage(_):
                            // Basculer automatiquement sur Shoply AI sans afficher de message d'erreur
                            fallbackToLocalAI(question: question)
                            return
                        case .apiError:
                            // Basculer automatiquement sur Shoply AI sans afficher de message d'erreur
                            fallbackToLocalAI(question: question)
                            return
                        case .invalidURL:
                            errorMessage = "Erreur de configuration Gemini. Veuillez vérifier vos paramètres.".localized
                        case .noResponse:
                            errorMessage = "Gemini n'a pas renvoyé de réponse. Veuillez réessayer.".localized
                        case .noItems:
                            errorMessage = "Votre garde-robe est vide. Ajoutez des vêtements d'abord.".localized
                        }
                    } else if (aiMode == .appleIntelligence && (!appleIntelligenceWrapper.isEnabled || !isIOS18Available)) ||
                              (aiMode == .gemini && !geminiService.isEnabled) {
                        // Basculer automatiquement sur Shoply AI sans message d'erreur
                        fallbackToLocalAI(question: question)
                        return
                    } else {
                        // Erreur inconnue - basculer sur Shoply AI
                        print("⚠️ Erreur inconnue avec \(aiMode.rawValue), basculement automatique sur Shoply AI")
                        fallbackToLocalAI(question: question)
                        return
                    }
                    
                    let responseMessage = ChatMessage(
                        content: errorMessage,
                        isUser: false
                    )
                    messages.append(responseMessage)
                    saveConversation()
                    isSending = false
                }
            }
        }
    }
    
    private func isGreeting(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        let greetings = ["salut", "bonjour", "bonsoir", "hello", "hi", "hey", "coucou"]
        return greetings.contains { lowercased.contains($0) }
    }
    
    private func isGeneralQuestion(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        // Questions générales qui peuvent mener à des conseils vestimentaires
        return lowercased.contains("mieux") || lowercased.contains("meilleur") || 
               lowercased.contains("quoi") || lowercased.contains("conseil") ||
               lowercased.contains("sport") || lowercased.contains("jean")
    }
    
    private func isClothingRelated(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        return clothingKeywords.contains { keyword in
            lowercased.contains(keyword.lowercased())
        }
    }
    
    private func saveConversation() {
        // Ne sauvegarder que si il y a au moins un message utilisateur (conversation active)
        let hasUserMessages = messages.contains { $0.isUser }
        guard hasUserMessages else {
            // Supprimer la conversation si elle existe déjà et qu'elle est vide
            removeEmptyConversation()
            return
        }
        
        // Générer un titre à partir du premier message utilisateur
        let firstUserMessage = messages.first { $0.isUser }
        let title = firstUserMessage?.content.prefix(30) ?? "Nouvelle conversation"
        
        // Déterminer le nom du mode IA pour la sauvegarde
        let aiModeString = aiMode.rawValue
        
        var conversation = ChatConversation(
            id: conversationId,
            title: String(title),
            messages: messages,
            aiMode: aiModeString
        )
        conversation.lastMessageAt = messages.last?.timestamp ?? Date()
        
        // Charger toutes les conversations
        var allConversations: [ChatConversation] = []
        if let data = UserDefaults.standard.data(forKey: "chatConversations"),
           let decoded = try? JSONDecoder().decode([ChatConversation].self, from: data) {
            allConversations = decoded
        }
        
        // Mettre à jour ou ajouter cette conversation
        if let index = allConversations.firstIndex(where: { $0.id == conversationId }) {
            allConversations[index] = conversation
        } else {
            allConversations.append(conversation)
        }
        
        // Sauvegarder
        if let encoded = try? JSONEncoder().encode(allConversations) {
            UserDefaults.standard.set(encoded, forKey: "chatConversations")
        }
    }
    
    // Supprimer une conversation vide de l'historique
    private func removeEmptyConversation() {
        var allConversations: [ChatConversation] = []
        if let data = UserDefaults.standard.data(forKey: "chatConversations"),
           let decoded = try? JSONDecoder().decode([ChatConversation].self, from: data) {
            allConversations = decoded
        }
        
        // Supprimer cette conversation si elle existe
        allConversations.removeAll { $0.id == conversationId }
        
        // Sauvegarder
        if let encoded = try? JSONEncoder().encode(allConversations) {
            UserDefaults.standard.set(encoded, forKey: "chatConversations")
        }
    }
    
    private func getSuggestions() -> [String] {
        let patternAnalyzer = UserMessagePatternAnalyzer.shared
        let patterns = patternAnalyzer.analyzeUserPatterns()
        let language = settingsManager.selectedLanguage.rawValue
        
        // Générer des suggestions personnalisées basées sur l'historique
        let personalizedSuggestions = patternAnalyzer.generatePersonalizedSuggestions(
            patterns: patterns,
            language: language
        )
        
        // Si l'utilisateur n'a pas encore d'historique, utiliser des suggestions génériques
        if personalizedSuggestions.isEmpty {
            return getDefaultSuggestions(language: language)
        }
        
        return personalizedSuggestions
    }
    
    /// Retourne des suggestions par défaut si l'utilisateur n'a pas d'historique
    private func getDefaultSuggestions(language: String) -> [String] {
        if language == "fr" {
            return [
                "Quel outfit me conseilles-tu ?",
                "Comment créer un look stylé ?",
                "Quelle tenue pour aujourd'hui ?",
                "Peux-tu m'aider à choisir mes vêtements ?",
                "Quel style me correspond ?",
                "Comment s'habiller selon la météo ?"
            ]
        } else {
            return [
                "What outfit do you recommend?",
                "How to create a stylish look?",
                "What to wear today?",
                "Can you help me choose my clothes?",
                "What style suits me?",
                "How to dress according to the weather?"
            ]
        }
    }
    
    private func loadMessages() {
        guard let data = UserDefaults.standard.data(forKey: "chatConversations"),
              let allConversations = try? JSONDecoder().decode([ChatConversation].self, from: data),
              let conversation = allConversations.first(where: { $0.id == conversationId }) else {
            return
        }
        
        messages = conversation.messages
        // Déterminer le mode IA depuis la conversation sauvegardée
        switch conversation.aiMode {
        case "Apple Intelligence":
            aiMode = .appleIntelligence
        case "Shoply AI":
            aiMode = .shoplyAI
        case "Gemini", "Advanced", "ChatGPT":
            aiMode = .gemini
        default:
            // Utiliser Apple Intelligence par défaut si disponible
            if #available(iOS 18.0, *), appleIntelligenceWrapper.isEnabled {
                aiMode = .appleIntelligence
            } else {
                aiMode = .gemini
            }
        }
    }
    
    // MARK: - Shoply AI
    
    private let shoplyAI = ShoplyAILLM.shared
    
    private func answerWithLocalAI(
        question: String,
        userProfile: UserProfile,
        currentWeather: WeatherData?,
        wardrobeItems: [WardrobeItem],
        image: UIImage? = nil
    ) async -> String {
        // Utiliser Shoply AI LLM (500k paramètres créé par William)
        // Protection contre les crashes
        let conversationHistory = messages.filter { !$0.isUser && !$0.isSystemMessage }
        let response = await shoplyAI.generateResponse(
            input: question,
            userProfile: userProfile,
            currentWeather: currentWeather,
            wardrobeItems: wardrobeItems,
            conversationHistory: conversationHistory
        )
        
        // Vérifier que la réponse n'est pas vide
        if response.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Fallback si réponse vide
            let intelligentAI = IntelligentLocalAI.shared
            return intelligentAI.generateIntelligentResponse(
                question: question,
                userProfile: userProfile,
                currentWeather: currentWeather,
                wardrobeItems: wardrobeItems,
                conversationHistory: [],
                image: image
            )
        }
        
        return response
    }
    
    private func fallbackToLocalAI(question: String) {
        let userProfile = dataManager.loadUserProfile() ?? UserProfile()
        let currentWeather = weatherService.currentWeather
        let wardrobeItems = wardrobeService.items
        
        Task { @MainActor in
            let localResponse = await answerWithLocalAI(
                question: question,
                userProfile: userProfile,
                currentWeather: currentWeather,
                wardrobeItems: wardrobeItems
            )
            let responseMessage = ChatMessage(content: localResponse, isUser: false)
            messages.append(responseMessage)
            saveConversation()
            isSending = false
        }
    }
    
    // Helper functions pour le scrolling
    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeOut(duration: 0.3)) {
                if let lastMessage = messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                } else {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }
    
    private func scrollToMessage(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.4)) {
                if isSending {
                    proxy.scrollTo("loading", anchor: .bottom)
                } else if let lastMessage = messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                } else {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }
    
    private func handleAIModeChange(newValue: AIMode, proxy: ScrollViewProxy) {
        let modeName = newValue.rawValue
        
        if let lastMessage = messages.last, lastMessage.isSystemMessage {
            messages.removeLast()
        }
        
        let switchMessage = ChatMessage(
            content: modeName,
            isUser: false,
            isSystemMessage: true
        )
        messages.append(switchMessage)
        saveConversation()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            withAnimation(.easeOut(duration: 0.4)) {
                if let lastMessage = messages.last {
                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                } else {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }
        }
    }
}

// MARK: - Welcome Message View

private struct WelcomeMessageView: View {
    let isIPad: Bool
    
    var body: some View {
        VStack(spacing: isIPad ? 28 : 22) {
            // Logo avec design minimaliste
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
                    .frame(width: isIPad ? 100 : 72, height: isIPad ? 100 : 72)
                    .overlay(
                        Circle()
                            .stroke(
                                AppColors.buttonPrimary.opacity(0.25),
                                lineWidth: isIPad ? 2 : 1.5
                            )
                    )
                
                Image(systemName: "sparkles")
                    .font(.system(size: isIPad ? 48 : 34, weight: .medium))
                    .foregroundColor(AppColors.buttonPrimary)
            }
            .shadow(
                color: AppColors.shadow.opacity(0.1),
                radius: isIPad ? 16 : 12,
                x: 0,
                y: isIPad ? 6 : 4
            )
            
            VStack(spacing: isIPad ? 14 : 12) {
                Text("Assistant Style".localized)
                    .font(.playfairDisplayBold(size: isIPad ? 36 : 30))
                    .foregroundColor(AppColors.primaryText)
                
                Text("Je suis là pour discuter de tout avec vous !".localized)
                    .font(.system(size: isIPad ? 19 : 16, weight: .regular))
                    .foregroundColor(AppColors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .padding(.horizontal, isIPad ? 60 : 40)
            }
        }
        .padding(.vertical, isIPad ? 40 : 32)
    }
}

// MARK: - Message Bubble

struct MessageBubble: View {
    let message: ChatMessage
    let isIPad: Bool
    @StateObject private var settingsManager = AppSettingsManager.shared
    
    private var isIPadDevice: Bool {
        isIPad || UIDevice.current.userInterfaceIdiom == .pad
    }
    
    var body: some View {
        if message.isSystemMessage {
            // Message système - design épuré
            HStack {
                Spacer()
                
                HStack(spacing: isIPadDevice ? 12 : 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: isIPadDevice ? 15 : 13, weight: .medium))
                        .foregroundColor(AppColors.buttonPrimary)
                    
                    Text(message.content)
                        .font(.system(size: isIPadDevice ? 14 : 12, weight: .medium))
                        .foregroundColor(AppColors.buttonPrimary)
                }
                .padding(.horizontal, isIPadDevice ? 18 : 14)
                .padding(.vertical, isIPadDevice ? 10 : 8)
                .background(
                    Capsule()
                        .fill(AppColors.buttonPrimary.opacity(0.08))
                        .overlay(
                            Capsule()
                                .stroke(AppColors.buttonPrimary.opacity(0.25), lineWidth: 1)
                        )
                )
                
                Spacer()
            }
            .padding(.vertical, isIPadDevice ? 8 : 6)
        } else {
            // Messages utilisateur/IA - design moderne
            HStack(alignment: .top, spacing: isIPadDevice ? 14 : 10) {
                if !message.isUser {
                    // Avatar IA
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        AppColors.buttonPrimary.opacity(0.12),
                                        AppColors.buttonPrimary.opacity(0.06)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: isIPadDevice ? 20 : 16, weight: .medium))
                            .foregroundColor(AppColors.buttonPrimary)
                    }
                    .frame(width: isIPadDevice ? 42 : 34, height: isIPadDevice ? 42 : 34)
                }
                
                // Bulle de message
                VStack(alignment: message.isUser ? .trailing : .leading, spacing: isIPadDevice ? 8 : 6) {
                    // Afficher l'image si disponible
                    if let image = message.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: isIPadDevice ? 300 : 200, maxHeight: isIPadDevice ? 300 : 200)
                            .clipShape(RoundedRectangle(cornerRadius: isIPadDevice ? 16 : 12))
                            .shadow(color: AppColors.shadow.opacity(0.1), radius: 8, x: 0, y: 4)
                    }
                    
                    // Afficher le texte si présent
                    if !message.content.isEmpty && message.content != "Photo envoyée" {
                        Text(message.content)
                            .font(.system(size: isIPadDevice ? 17 : 15))
                            .foregroundColor(
                                message.isUser
                                ? AppColors.buttonPrimaryText
                                : AppColors.primaryText
                            )
                            .padding(.horizontal, isIPadDevice ? 18 : 14)
                            .padding(.vertical, isIPadDevice ? 14 : 12)
                            .background(
                                RoundedRectangle(cornerRadius: isIPadDevice ? 22 : 18)
                                    .fill(
                                        message.isUser
                                        ? AppColors.buttonPrimary
                                        : AppColors.cardBackground
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: isIPadDevice ? 22 : 18)
                                            .stroke(
                                                message.isUser
                                                    ? Color.clear
                                                    : AppColors.cardBorder.opacity(0.25),
                                                lineWidth: 1
                                            )
                                    )
                            )
                            .shadow(
                                color: AppColors.shadow.opacity(message.isUser ? 0.25 : 0.15),
                                radius: message.isUser ? 14 : 10,
                                x: 0,
                                y: message.isUser ? 6 : 4
                            )
                    }
                }
                .frame(
                    maxWidth: isIPadDevice ? 550 : .infinity,
                    alignment: message.isUser ? .trailing : .leading
                )
                
                if message.isUser {
                    // Avatar utilisateur
                    ZStack {
                        Circle()
                            .fill(AppColors.buttonPrimary)
                        
                        Image(systemName: "person.fill")
                            .font(.system(size: isIPadDevice ? 18 : 14, weight: .medium))
                            .foregroundColor(AppColors.buttonPrimaryText)
                    }
                    .frame(width: isIPadDevice ? 36 : 30, height: isIPadDevice ? 36 : 30)
                    .shadow(
                        color: AppColors.shadow.opacity(0.12),
                        radius: 6,
                        x: 0,
                        y: 3
                    )
                }
            }
            .frame(
                maxWidth: .infinity,
                alignment: message.isUser ? .trailing : .leading
            )
            .padding(.horizontal, message.isUser ? (isIPadDevice ? 40 : 20) : 0)
        }
    }
}

// MARK: - Composants Modernes

struct ChatHeaderView: View {
    let isIPad: Bool
    let availableModes: [ChatAIScreen.AIMode]
    @Binding var selectedMode: ChatAIScreen.AIMode
    
    var body: some View {
        if isIPad {
            // iPad : Titre uniquement dans la toolbar
            Text("Assistant Style".localized)
                .font(.playfairDisplayBold(size: 32))
                .foregroundColor(AppColors.primaryText)
        } else {
            // iPhone : Titre + Picker dans la toolbar
            VStack(spacing: 6) {
                Text("Assistant Style".localized)
                    .font(.playfairDisplayBold(size: 18))
                    .foregroundColor(AppColors.primaryText)
                
                Picker("Mode IA", selection: $selectedMode) {
                    ForEach(availableModes, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: min(280, CGFloat(availableModes.count) * 85))
            }
        }
    }
}

struct ModernInputArea: View {
    @Binding var inputText: String
    let isSending: Bool
    let isIPad: Bool
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var selectedImage: UIImage?
    let onSend: () -> Void
    let maxWidth: CGFloat
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
            VStack(spacing: isIPad ? 12 : 10) {
            // Aperçu de l'image sélectionnée
            if let image = selectedImage {
                HStack {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: isIPad ? 80 : 60, height: isIPad ? 80 : 60)
                        .clipShape(RoundedRectangle(cornerRadius: isIPad ? 12 : 10))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Photo sélectionnée".localized)
                            .font(.system(size: isIPad ? 15 : 13, weight: .medium))
                            .foregroundColor(AppColors.primaryText)
                        Text("Appuyez sur X pour supprimer".localized)
                            .font(.system(size: isIPad ? 13 : 11))
                            .foregroundColor(AppColors.secondaryText)
                    }
                    
                    Spacer()
                    
                    Button {
                        selectedImage = nil
                        selectedPhoto = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: isIPad ? 24 : 20))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                .padding(isIPad ? 14 : 12)
                .background(
                    RoundedRectangle(cornerRadius: isIPad ? 16 : 14)
                        .fill(AppColors.buttonSecondary)
                )
                .padding(.horizontal, isIPad ? 40 : 20)
            }
            
            // Zone de saisie avec design moderne
            HStack(spacing: isIPad ? 16 : 12) {
                // Bouton de sélection de photo
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: selectedImage != nil ? "photo.fill" : "photo")
                        .font(.system(size: isIPad ? 22 : 20, weight: .medium))
                        .foregroundColor(selectedImage != nil ? AppColors.buttonPrimary : AppColors.secondaryText)
                        .frame(width: isIPad ? 44 : 40, height: isIPad ? 44 : 40)
                        .background(
                            Circle()
                                .fill(selectedImage != nil ? AppColors.buttonPrimary.opacity(0.1) : AppColors.buttonSecondary)
                        )
                }
                
                // Champ de texte avec style épuré
                HStack(spacing: isIPad ? 14 : 12) {
                    Image(systemName: "text.bubble")
                        .font(.system(size: isIPad ? 18 : 16))
                        .foregroundColor(AppColors.secondaryText)
                        .frame(width: isIPad ? 24 : 20)
                    
                    TextField("Posez votre question...".localized, text: $inputText, axis: .vertical)
                        .textFieldStyle(.plain)
                        .font(.system(size: isIPad ? 17 : 15))
                        .foregroundColor(AppColors.primaryText)
                        .focused($isTextFieldFocused)
                        .lineLimit(1...5)
                        .onSubmit {
                            if !inputText.isEmpty && !isSending {
                                onSend()
                            }
                        }
                }
                .padding(.horizontal, isIPad ? 20 : 16)
                .padding(.vertical, isIPad ? 16 : 14)
                .background(
                    RoundedRectangle(cornerRadius: isIPad ? 24 : 20)
                        .fill(AppColors.cardBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: isIPad ? 24 : 20)
                                .stroke(
                                    isTextFieldFocused 
                                    ? AppColors.buttonPrimary.opacity(0.4)
                                    : AppColors.cardBorder.opacity(0.3),
                                    lineWidth: isTextFieldFocused ? 2 : 1
                                )
                        )
                )
                .shadow(
                    color: AppColors.shadow.opacity(isTextFieldFocused ? 0.15 : 0.08),
                    radius: isTextFieldFocused ? 12 : 8,
                    x: 0,
                    y: isTextFieldFocused ? 4 : 2
                )
                
                // Bouton d'envoi moderne
                Button(action: onSend) {
                    ZStack {
                        Circle()
                            .fill(
                                (inputText.isEmpty && selectedImage == nil) || isSending
                                ? AppColors.buttonSecondary
                                : AppColors.buttonPrimary
                            )
                            .frame(width: isIPad ? 52 : 44, height: isIPad ? 52 : 44)
                        
                        Image(systemName: "arrow.up")
                            .font(.system(size: isIPad ? 20 : 18, weight: .semibold))
                            .foregroundColor(
                                (inputText.isEmpty && selectedImage == nil) || isSending
                                ? AppColors.secondaryText
                                : AppColors.buttonPrimaryText
                            )
                    }
                    .shadow(
                        color: ((inputText.isEmpty && selectedImage == nil) || isSending)
                        ? Color.clear
                        : AppColors.shadow.opacity(0.2),
                        radius: (inputText.isEmpty && selectedImage == nil) ? 0 : 8,
                        x: 0,
                        y: (inputText.isEmpty && selectedImage == nil) ? 0 : 4
                    )
                }
                .disabled((inputText.isEmpty && selectedImage == nil) || isSending)
                .animation(.spring(response: 0.3), value: inputText.isEmpty)
                .animation(.spring(response: 0.3), value: selectedImage == nil)
            }
            .padding(.horizontal, isIPad ? 40 : 20)
            .padding(.vertical, isIPad ? 20 : 16)
            .background(
                Rectangle()
                    .fill(AppColors.background)
                    .shadow(color: AppColors.shadow.opacity(0.05), radius: 0, x: 0, y: -4)
            )
            .frame(maxWidth: maxWidth)
            .frame(maxWidth: .infinity)
        }
    }
}

struct LoadingIndicatorView: View {
    let isIPad: Bool
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(spacing: isIPad ? 14 : 12) {
            // Indicateur de chargement avec animation fluide
            HStack(spacing: isIPad ? 8 : 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(AppColors.buttonPrimary.opacity(0.5))
                        .frame(width: isIPad ? 9 : 7, height: isIPad ? 9 : 7)
                        .opacity(
                            (animationPhase + index) % 3 == 0 ? 1.0 : 0.3
                        )
                }
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 0.8).repeatForever()) {
                    animationPhase = 3
                }
            }
            
            Text("L'IA réfléchit...".localized)
                .font(.system(size: isIPad ? 17 : 15, weight: .medium))
                .foregroundColor(AppColors.secondaryText)
        }
        .padding(.horizontal, isIPad ? 22 : 16)
        .padding(.vertical, isIPad ? 14 : 12)
        .background(
            Capsule()
                .fill(AppColors.buttonSecondary)
                .overlay(
                    Capsule()
                        .stroke(AppColors.cardBorder.opacity(0.25), lineWidth: 1)
                )
        )
        .shadow(color: AppColors.shadow.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

struct ModernAIPicker: View {
    let availableModes: [ChatAIScreen.AIMode]
    @Binding var selectedMode: ChatAIScreen.AIMode
    let maxWidth: CGFloat
    
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(AppColors.separator)
                .frame(height: 0.5)
            
            HStack {
                Spacer()
                
                Picker("Mode IA", selection: $selectedMode) {
                    ForEach(availableModes, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: min(500, CGFloat(availableModes.count) * 120))
                
                Spacer()
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 40)
            .background(AppColors.background)
        }
    }
}

// MARK: - Message Suggestions View

struct MessageSuggestionsView: View {
    let suggestions: [String]
    let onSuggestionTapped: (String) -> Void
    let isIPad: Bool
    let maxWidth: CGFloat
    
    var body: some View {
        VStack(alignment: .leading, spacing: isIPad ? 12 : 10) {
            Text("Suggestions de questions".localized)
                .font(.system(size: isIPad ? 16 : 14, weight: .semibold))
                .foregroundColor(AppColors.secondaryText)
                .padding(.horizontal, isIPad ? 4 : 2)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: isIPad ? 14 : 12) {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Button(action: {
                            onSuggestionTapped(suggestion)
                        }) {
                            Text(suggestion.localized)
                                .font(.system(size: isIPad ? 15 : 13, weight: .medium))
                                .foregroundColor(AppColors.buttonPrimaryText)
                                .padding(.horizontal, isIPad ? 18 : 16)
                                .padding(.vertical, isIPad ? 12 : 10)
                                .background(
                                    RoundedRectangle(cornerRadius: isIPad ? 20 : 18)
                                        .fill(AppColors.buttonPrimary)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: isIPad ? 20 : 18)
                                        .stroke(AppColors.cardBorder.opacity(0.2), lineWidth: 0.5)
                                )
                        }
                        .shadow(color: AppColors.shadow.opacity(0.1), radius: 6, x: 0, y: 2)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(.horizontal, isIPad ? 4 : 2)
            }
        }
        .frame(maxWidth: maxWidth)
    }
}

#Preview {
    ChatAIScreen()
}

