//
//  ChatAIScreen.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import SwiftUI

struct ChatAIScreen: View {
    let initialMessages: [ChatMessage]
    let initialAIMode: AIMode
    
    @StateObject private var openAIService = OpenAIService.shared
    @StateObject private var geminiService = GeminiService.shared
    @StateObject private var dataManager = DataManager.shared
    @StateObject private var wardrobeService = WardrobeService()
    @StateObject private var weatherService = WeatherService.shared
    @StateObject private var settingsManager = AppSettingsManager.shared
    
    @State private var messages: [ChatMessage] = []
    @State private var inputText: String = ""
    @State private var isSending: Bool = false
    @State private var aiMode: AIMode
    @State private var conversationId: UUID
    @Environment(\.dismiss) var dismiss
    
    enum AIMode: String, CaseIterable {
        case advancedAI = "Advanced"
        case shoplyAI = "Shoply AI"
    }
    
    init(conversationId: UUID? = nil, initialMessages: [ChatMessage] = [], initialAIMode: AIMode = .advancedAI) {
        self.initialMessages = initialMessages
        self.initialAIMode = initialAIMode
        _aiMode = State(initialValue: initialAIMode)
        _conversationId = State(initialValue: conversationId ?? UUID())
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Zone des messages
                    ScrollViewReader { (proxy: ScrollViewProxy) in
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                // Message de bienvenue
                                if messages.isEmpty {
                                    VStack(spacing: 16) {
                                        // Logo IA avec design moderne
                                        ZStack {
                                            // Cercle externe avec gradient
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            AppColors.buttonPrimary.opacity(0.2),
                                                            AppColors.buttonPrimary.opacity(0.1)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 80, height: 80)
                                                .overlay(
                                                    Circle()
                                                        .stroke(
                                                            LinearGradient(
                                                                colors: [
                                                                    AppColors.buttonPrimary.opacity(0.4),
                                                                    AppColors.buttonPrimary.opacity(0.2)
                                                                ],
                                                                startPoint: .topLeading,
                                                                endPoint: .bottomTrailing
                                                            ),
                                                            lineWidth: 2
                                                        )
                                                )
                                            
                                            // Icône sparkles au centre
                                            Image(systemName: "sparkles")
                                                .font(.system(size: 40, weight: .semibold))
                                                .foregroundColor(AppColors.buttonPrimary)
                                                .symbolEffect(.pulse, options: .repeating.speed(0.6))
                                        }
                                        .shadow(color: AppColors.buttonPrimary.opacity(0.2), radius: 12, x: 0, y: 4)
                                        
                                        Text("Conseils de Style".localized)
                                            .font(.playfairDisplayBold(size: 24))
                                            .foregroundColor(AppColors.primaryText)
                                        
                                        Text("Posez-moi vos questions sur vos outfits, la météo, ou vos vêtements !".localized)
                                            .font(.system(size: 16))
                                            .foregroundColor(AppColors.secondaryText)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal)
                                    }
                                    .padding(.vertical, 40)
                                }
                                
                                // Messages
                                ForEach(messages) { message in
                                    MessageBubble(message: message)
                                }
                                
                                // Indicateur de chargement
                                if isSending {
                                    HStack {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                        Text("L'IA réfléchit...".localized)
                                            .font(.system(size: 14))
                                            .foregroundColor(AppColors.secondaryText)
                                    }
                                    .padding()
                                }
                            }
                            .padding()
                        }
                        .onChange(of: messages.count) { oldValue, newValue in
                            if let lastMessage = messages.last {
                                withAnimation {
                                    proxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                        .onChange(of: aiMode) { oldValue, newValue in
                            // Afficher un message lorsque l'utilisateur change de mode IA
                            if oldValue != newValue {
                                let modeName: String
                                if newValue == .advancedAI {
                                    modeName = settingsManager.aiProvider.displayName
                                } else {
                                    modeName = "Shoply AI"
                                }
                                
                                let switchMessage = ChatMessage(
                                    content: modeName,
                                    isUser: false,
                                    isSystemMessage: true
                                )
                                messages.append(switchMessage)
                                saveConversation()
                                
                                // Scroll vers le nouveau message
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    if let lastMessage = messages.last {
                                        withAnimation {
                                            // Scroll handled by the onChange of messages.count
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    Divider()
                        .background(AppColors.separator)
                    
                    // Zone de saisie
                    HStack(spacing: 12) {
                        TextField("Posez votre question...".localized, text: $inputText, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(AppColors.buttonSecondary)
                            .roundedCorner(16)
                            .lineLimit(1...4)
                            .onSubmit {
                                sendMessage()
                            }
                        
                        Button(action: sendMessage) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 32))
                                .foregroundColor(inputText.isEmpty || isSending ? AppColors.secondaryText : AppColors.buttonPrimary)
                        }
                        .disabled(inputText.isEmpty || isSending)
                    }
                    .padding()
                    .background(AppColors.background)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: 4) {
                        Text("Assistant Style".localized)
                            .font(.playfairDisplayBold(size: 20))
                            .foregroundColor(AppColors.primaryText)
                        
                        // Sélecteur IA
                        Picker("Mode IA".localized, selection: $aiMode) {
                            ForEach(AIMode.allCases, id: \.self) { mode in
                                if mode == .advancedAI {
                                    Text(settingsManager.aiProvider.displayName).tag(mode)
                                } else {
                                    Text("Shoply AI".localized).tag(mode)
                                }
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 180)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(AppColors.secondaryText)
                    }
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
        .onChange(of: aiMode) { oldValue, newValue in
            saveConversation()
        }
        .onDisappear {
            saveConversation()
        }
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespaces).isEmpty,
              !isSending else { return }
        
        let question = inputText.trimmingCharacters(in: .whitespaces)
        let userMessage = ChatMessage(content: question, isUser: true)
        messages.append(userMessage)
        saveConversation()
        
        inputText = ""
        isSending = true
        
        Task { @MainActor in
            do {
                // Obtenir le contexte
                let userProfile = dataManager.loadUserProfile() ?? UserProfile()
                let currentWeather = weatherService.currentWeather
                let wardrobeItems = wardrobeService.items
                
                // Envoyer la question à l'IA selon le mode sélectionné
                let response: String
                
                // Utiliser le mode sélectionné dans le picker
                if aiMode == .advancedAI {
                    // IA Avancée sélectionnée : utiliser le provider choisi dans les paramètres (ChatGPT ou Gemini)
                    let selectedProvider = settingsManager.aiProvider
                    
                    if selectedProvider == .gemini && geminiService.isEnabled {
                        // Utiliser Gemini
                        response = try await geminiService.askAboutClothing(
                            question: question,
                            userProfile: userProfile,
                            currentWeather: currentWeather,
                            wardrobeItems: wardrobeItems
                        )
                    } else if selectedProvider == .chatGPT && openAIService.isEnabled {
                        // Utiliser ChatGPT
                        response = try await openAIService.askAboutClothing(
                            question: question,
                            userProfile: userProfile,
                            currentWeather: currentWeather,
                            wardrobeItems: wardrobeItems
                        )
                    } else if selectedProvider == .gemini && !geminiService.isEnabled {
                        // Gemini sélectionné mais non disponible - utiliser Shoply AI sans message (silencieux)
                        response = await answerWithLocalAI(
                            question: question,
                            userProfile: userProfile,
                            currentWeather: currentWeather,
                            wardrobeItems: wardrobeItems
                        )
                    } else if selectedProvider == .chatGPT && !openAIService.isEnabled {
                        // ChatGPT sélectionné mais non disponible - utiliser Shoply AI sans message (silencieux)
                        response = await answerWithLocalAI(
                            question: question,
                            userProfile: userProfile,
                            currentWeather: currentWeather,
                            wardrobeItems: wardrobeItems
                        )
                    } else {
                        // Si aucun service IA avancé n'est disponible, utiliser Shoply AI sans message
                        response = await answerWithLocalAI(
                            question: question,
                            userProfile: userProfile,
                            currentWeather: currentWeather,
                            wardrobeItems: wardrobeItems
                        )
                    }
                } else {
                    // Shoply AI sélectionnée : utiliser avec restrictions
                    let isRelated = isClothingRelated(question) || isGeneralQuestion(question)
                    
                    if !isRelated && !isGreeting(question) {
                        await MainActor.run {
                            let responseMessage = ChatMessage(
                                content: "Je peux vous aider avec des conseils sur vos vêtements, outfits, la météo, le style et la mode. Posez-moi une question sur ces sujets !".localized,
                                isUser: false
                            )
                            messages.append(responseMessage)
                            saveConversation()
                            isSending = false
                        }
                        return
                    }
                    
                    // Pour les salutations avec Shoply AI, répondre poliment
                    if isGreeting(question) {
                        await MainActor.run {
                            let responseMessage = ChatMessage(
                                content: "Salut ! Je suis là pour vous aider avec vos questions sur la mode, les outfits et les vêtements. Que souhaitez-vous savoir ?".localized,
                                isUser: false
                            )
                            messages.append(responseMessage)
                            saveConversation()
                            isSending = false
                        }
                        return
                    }
                    
                    // Utiliser Shoply AI
                    response = await answerWithLocalAI(
                        question: question,
                        userProfile: userProfile,
                        currentWeather: currentWeather,
                        wardrobeItems: wardrobeItems
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
                    
                    // Gestion spécifique des erreurs OpenAI
                    if let openAIError = error as? OpenAIError {
                        switch openAIError {
                        case .apiKeyMissing:
                            errorMessage = "Clé API ChatGPT manquante. Veuillez la configurer dans les paramètres.".localized
                        case .apiKeyInvalid:
                            errorMessage = "Clé API ChatGPT invalide ou expirée. Veuillez la vérifier dans les paramètres.".localized
                        case .rateLimitExceeded:
                            errorMessage = "Limite de requêtes atteinte. Veuillez réessayer dans quelques instants.".localized
                        case .apiErrorWithMessage(let message):
                            // Traduire les erreurs courantes en français
                            var translatedMessage = message
                            if message.lowercased().contains("quota") || message.lowercased().contains("exceeded") {
                                translatedMessage = "Votre quota OpenAI a été dépassé. Veuillez vérifier votre plan et vos détails de facturation."
                            } else if message.lowercased().contains("invalid") || message.lowercased().contains("unauthorized") {
                                translatedMessage = "Clé API invalide ou non autorisée."
                            } else if message.lowercased().contains("rate limit") {
                                translatedMessage = "Limite de taux atteinte. Veuillez réessayer plus tard."
                            }
                            // Basculer automatiquement sur Shoply AI sans afficher de message d'erreur
                            let questionText = question
                            let userProfile = dataManager.loadUserProfile() ?? UserProfile()
                            let currentWeather = weatherService.currentWeather
                            let wardrobeItems = wardrobeService.items
                            
                            // Répondre directement avec Shoply AI sans message d'erreur
                            Task { @MainActor in
                                let localResponse = await answerWithLocalAI(
                                    question: questionText,
                                    userProfile: userProfile,
                                    currentWeather: currentWeather,
                                    wardrobeItems: wardrobeItems
                                )
                                let responseMessage = ChatMessage(content: localResponse, isUser: false)
                                messages.append(responseMessage)
                                saveConversation()
                                isSending = false
                            }
                            return
                        default:
                            let providerName = settingsManager.aiProvider.displayName
                            errorMessage = "Erreur de connexion à \(providerName). Essayez de réessayer.".localized
                        }
                    } else if let geminiError = error as? GeminiError {
                        switch geminiError {
                        case .apiKeyMissing:
                            errorMessage = "Clé API Gemini manquante. Veuillez la configurer dans les paramètres.".localized
                        case .apiErrorWithMessage(let message):
                            // Basculer automatiquement sur Shoply AI sans afficher de message d'erreur
                            let questionText = question
                            let userProfile = dataManager.loadUserProfile() ?? UserProfile()
                            let currentWeather = weatherService.currentWeather
                            let wardrobeItems = wardrobeService.items
                            
                            // Répondre directement avec Shoply AI sans message d'erreur
                            Task { @MainActor in
                                let localResponse = await answerWithLocalAI(
                                    question: questionText,
                                    userProfile: userProfile,
                                    currentWeather: currentWeather,
                                    wardrobeItems: wardrobeItems
                                )
                                let responseMessage = ChatMessage(content: localResponse, isUser: false)
                                messages.append(responseMessage)
                                saveConversation()
                                isSending = false
                            }
                            return
                        case .apiError:
                            // Basculer automatiquement sur Shoply AI sans afficher de message d'erreur
                            let questionText = question
                            let userProfile = dataManager.loadUserProfile() ?? UserProfile()
                            let currentWeather = weatherService.currentWeather
                            let wardrobeItems = wardrobeService.items
                            
                            // Répondre directement avec Shoply AI sans message d'erreur
                            Task { @MainActor in
                                let localResponse = await answerWithLocalAI(
                                    question: questionText,
                                    userProfile: userProfile,
                                    currentWeather: currentWeather,
                                    wardrobeItems: wardrobeItems
                                )
                                let responseMessage = ChatMessage(content: localResponse, isUser: false)
                                messages.append(responseMessage)
                                saveConversation()
                                isSending = false
                            }
                            return
                        case .invalidURL:
                            errorMessage = "Erreur de configuration Gemini. Veuillez vérifier vos paramètres.".localized
                        case .noResponse:
                            errorMessage = "Gemini n'a pas renvoyé de réponse. Veuillez réessayer.".localized
                        case .noItems:
                            errorMessage = "Votre garde-robe est vide. Ajoutez des vêtements d'abord.".localized
                        }
                    } else if aiMode == .advancedAI && !openAIService.isEnabled && !geminiService.isEnabled {
                        // Basculer automatiquement sur Shoply AI sans message d'erreur
                        let questionText = question
                        let userProfile = dataManager.loadUserProfile() ?? UserProfile()
                        let currentWeather = weatherService.currentWeather
                        let wardrobeItems = wardrobeService.items
                        
                        Task { @MainActor in
                            let localResponse = await answerWithLocalAI(
                                question: questionText,
                                userProfile: userProfile,
                                currentWeather: currentWeather,
                                wardrobeItems: wardrobeItems
                            )
                            let responseMessage = ChatMessage(content: localResponse, isUser: false)
                            messages.append(responseMessage)
                            saveConversation()
                            isSending = false
                        }
                        return
                    } else {
                        // En cas d'erreur avec l'IA avancée, essayer automatiquement de basculer sur Shoply AI
                        let providerName = settingsManager.aiProvider.displayName
                        print("⚠️ Erreur avec \(providerName), basculement automatique sur Shoply AI")
                        let questionText = question // Capturer la question avant le Task
                        let userProfile = dataManager.loadUserProfile() ?? UserProfile()
                        let currentWeather = weatherService.currentWeather
                        let wardrobeItems = wardrobeService.items
                        
                        Task { @MainActor in
                            let localResponse = await answerWithLocalAI(
                                question: questionText,
                                userProfile: userProfile,
                                currentWeather: currentWeather,
                                wardrobeItems: wardrobeItems
                            )
                            let responseMessage = ChatMessage(content: localResponse, isUser: false)
                            messages.append(responseMessage)
                            saveConversation()
                            isSending = false
                        }
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
        guard !messages.isEmpty else { return }
        
        // Générer un titre à partir du premier message
        let title = messages.first?.content.prefix(30) ?? "Nouvelle conversation"
        
        // Déterminer le nom du mode IA pour la sauvegarde
        let aiModeString: String
        if aiMode == .advancedAI {
            aiModeString = settingsManager.aiProvider.displayName
        } else {
            aiModeString = "Shoply AI"
        }
        
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
    
    private func loadMessages() {
        guard let data = UserDefaults.standard.data(forKey: "chatConversations"),
              let allConversations = try? JSONDecoder().decode([ChatConversation].self, from: data),
              let conversation = allConversations.first(where: { $0.id == conversationId }) else {
            return
        }
        
        messages = conversation.messages
        // Déterminer le mode IA depuis la conversation sauvegardée
        if conversation.aiMode == "Shoply AI" {
            aiMode = .shoplyAI
        } else {
            // Pour les anciennes conversations avec "ChatGPT" ou nouvelles avec provider name
            aiMode = .advancedAI
        }
    }
    
    // MARK: - Shoply AI
    
    private let intelligentAI = IntelligentLocalAI.shared
    
    private func answerWithLocalAI(
        question: String,
        userProfile: UserProfile,
        currentWeather: WeatherData?,
        wardrobeItems: [WardrobeItem]
    ) async -> String {
        // Utiliser la nouvelle IA intelligente
        return intelligentAI.generateIntelligentResponse(
            question: question,
            userProfile: userProfile,
            currentWeather: currentWeather,
            wardrobeItems: wardrobeItems,
            conversationHistory: messages.filter { !$0.isUser }
        )
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    @StateObject private var settingsManager = AppSettingsManager.shared
    
    var body: some View {
        // Message système (changement d'IA)
        if message.isSystemMessage {
            HStack {
                Spacer()
                
                HStack(spacing: 8) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColors.buttonPrimary)
                        .symbolEffect(.pulse, options: .repeating)
                    
                    Text(message.content)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.buttonPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(AppColors.buttonPrimary.opacity(0.1))
                        .overlay(
                            Capsule()
                                .stroke(AppColors.buttonPrimary.opacity(0.3), lineWidth: 1)
                        )
                )
                
                Spacer()
            }
            .padding(.vertical, 8)
        } else {
            // Message normal
            HStack(alignment: .top, spacing: 12) {
                if !message.isUser {
                    // Logo IA avec design amélioré pour mode sombre
                    ZStack {
                        // Fond avec gradient adaptatif
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
                        
                        // Icône sparkles avec effet brillant
                        Image(systemName: "sparkles")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(AppColors.buttonPrimary)
                            .symbolEffect(.pulse, options: .repeating)
                    }
                    .frame(width: 36, height: 36)
                }
                
                VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                    Text(message.content)
                        .font(.system(size: 16))
                        .foregroundColor(message.isUser ? AppColors.background : AppColors.primaryText)
                        .padding(12)
                        .background(message.isUser ? AppColors.buttonPrimary : AppColors.buttonSecondary)
                        .roundedCorner(16)
                }
                
                if message.isUser {
                    Image(systemName: "person.fill")
                        .font(.system(size: 20))
                        .foregroundColor(AppColors.background)
                        .frame(width: 32, height: 32)
                        .background(AppColors.buttonPrimary)
                        .clipShape(Circle())
                }
            }
            .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
            .padding(.horizontal, message.isUser ? 20 : 0)
        }
    }
}

#Preview {
    ChatAIScreen()
}

