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
    @State private var showingConversations = false
    @State private var showingMenu = false
    @Environment(\.dismiss) var dismiss
    
    enum AIMode: String, CaseIterable {
        case appleIntelligence = "Apple Intelligence"
        case gemini = "Gemini"
        case shoplyAI = "Shoply AI"
    }
    
    init(conversationId: UUID? = nil, initialMessages: [ChatMessage] = [], initialAIMode: AIMode? = nil) {
        self.initialMessages = initialMessages
        
        let defaultMode: AIMode
        if let providedMode = initialAIMode {
            self.initialAIMode = providedMode
            _aiMode = State(initialValue: providedMode)
            _conversationId = State(initialValue: conversationId ?? UUID())
            return
        }
        
        defaultMode = .shoplyAI
        self.initialAIMode = defaultMode
        _aiMode = State(initialValue: defaultMode)
        _conversationId = State(initialValue: conversationId ?? UUID())
    }
    
    private var availableAIModes: [AIMode] {
        var modes: [AIMode] = [.shoplyAI]
        
        if #available(iOS 18.0, *) {
            if appleIntelligenceWrapper.isEnabled {
                modes.insert(.appleIntelligence, at: 0)
            }
        }
        
        if geminiService.isEnabled {
            modes.append(.gemini)
        }
        
        return modes
    }
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private func modeIcon(_ mode: AIMode) -> String {
        switch mode {
        case .gemini:
            return "star.circle.fill"
        case .shoplyAI:
            return "sparkles"
        case .appleIntelligence:
            return "brain"
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Zone des messages
                    ScrollViewReader { proxy in
                        ScrollView {
                            if messages.isEmpty {
                                // Centrer le WelcomeView au milieu de l'écran
                                GeometryReader { geometry in
                                    VStack {
                                        Spacer()
                                        WelcomeView()
                                            .id("welcome")
                                        Spacer()
                                    }
                                    .frame(width: geometry.size.width, height: geometry.size.height)
                                }
                                .frame(height: UIScreen.main.bounds.height - 200)
                            } else {
                                LazyVStack(spacing: DesignSystem.Spacing.md) {
                                    ForEach(messages) { message in
                                        ChatMessageBubble(message: message, currentAIMode: aiMode)
                                            .id(message.id)
                                    }
                                    
                                    if isSending {
                                        LoadingView(aiMode: aiMode)
                                            .padding(.top, DesignSystem.Spacing.sm)
                                            .id("loading")
                                    }
                                    
                                    Color.clear
                                        .frame(height: 1)
                                        .id("bottom")
                                }
                                .padding(.horizontal, DesignSystem.Spacing.md)
                                .padding(.vertical, DesignSystem.Spacing.lg)
                            }
                        }
                        .scrollDismissesKeyboard(.interactively)
                        .defaultScrollAnchor(.bottom)
                        .onAppear {
                            scrollToBottom(proxy: proxy)
                        }
                        .onChange(of: messages.count) { oldValue, newValue in
                            if newValue > oldValue {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    scrollToBottom(proxy: proxy)
                                }
                            }
                        }
                        .onChange(of: isSending) { oldValue, newValue in
                            if newValue {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                                    withAnimation {
                                        proxy.scrollTo("loading", anchor: .bottom)
                                    }
                                }
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    scrollToBottom(proxy: proxy)
                                }
                            }
                        }
                    }
                    
                    // Suggestions
                    if messages.isEmpty || (messages.count <= 2 && messages.allSatisfy { !$0.isUser }) {
                        SuggestionsView(suggestions: getSuggestions()) { suggestion in
                            inputText = suggestion
                        }
                        .padding(.horizontal, DesignSystem.Spacing.md)
                        .padding(.vertical, DesignSystem.Spacing.sm)
                    }
                    
                    // Séparateur
                    Rectangle()
                        .fill(AppColors.separator)
                        .frame(height: 1)
                    
                    // Zone de saisie
                    ChatInputArea(
                        text: $inputText,
                        isSending: isSending,
                        selectedPhoto: $selectedPhoto,
                        selectedImage: $selectedImage,
                        onSend: sendMessage
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
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    VStack(spacing: DesignSystem.Spacing.xs) {
                        Text("Assistant Style".localized)
                            .font(DesignSystem.Typography.headline())
                            .foregroundColor(AppColors.primaryText)
                        
                        Picker("Mode", selection: $aiMode) {
                            ForEach(availableAIModes, id: \.self) { mode in
                                Text(mode.rawValue).tag(mode)
                            }
                        }
                        .pickerStyle(.segmented)
                        .frame(width: min(200, CGFloat(availableAIModes.count) * 90))
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingMenu = true
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(AppColors.primaryText)
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColors.primaryText)
                    }
                }
            }
        }
        .sheet(isPresented: $showingConversations) {
            NavigationStack {
                ChatConversationsScreen()
            }
        }
        .sheet(isPresented: $showingMenu) {
            ChatMenuView(
                onNewConversation: {
                    showingMenu = false
                    messages = []
                    conversationId = UUID()
                    inputText = ""
                },
                onShowHistory: {
                    showingMenu = false
                    showingConversations = true
                }
            )
            .presentationDetents([.height(140)])
            .presentationDragIndicator(.visible)
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
            // Ajouter ou remplacer un message système pour indiquer le changement de mode
            if oldValue != newValue {
                let modeMessage: String
                switch newValue {
                case .gemini:
                    modeMessage = "Mode changé : Gemini".localized
                case .shoplyAI:
                    modeMessage = "Mode changé : Shoply AI".localized
                case .appleIntelligence:
                    modeMessage = "Mode changé : Apple Intelligence".localized
                }
                
                // Vérifier si le dernier message est un message système de changement de mode
                // Si oui, le remplacer au lieu d'en ajouter un nouveau
                if let lastMessage = messages.last,
                   lastMessage.isSystemMessage,
                   lastMessage.content.contains("Mode changé") {
                    // Remplacer le dernier message système
                    if let lastIndex = messages.indices.last {
                        messages[lastIndex] = ChatMessage(
                            content: modeMessage,
                            isUser: false,
                            isSystemMessage: true
                        )
                    }
                } else {
                    // Ajouter un nouveau message système (il y a eu des messages entre les changements)
                    let systemMessage = ChatMessage(
                        content: modeMessage,
                        isUser: false,
                        isSystemMessage: true
                    )
                    messages.append(systemMessage)
                }
            }
            
            if messages.contains(where: { $0.isUser }) {
                saveConversation()
            }
        }
        .onDisappear {
            let hasUserMessages = messages.contains { $0.isUser }
            if hasUserMessages {
                saveConversation()
            } else {
                removeEmptyConversation()
            }
        }
    }
    
    private func sendMessage() {
        guard !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || selectedImage != nil else { return }
        
        let imageData = selectedImage?.jpegData(compressionQuality: 0.8)
        let userMessage = ChatMessage(
            content: inputText.isEmpty ? "Photo envoyée" : inputText,
            isUser: true,
            isSystemMessage: false,
            imageData: imageData
        )
        
        messages.append(userMessage)
        inputText = ""
        selectedImage = nil
        selectedPhoto = nil
        isSending = true
        
        Task {
            let response = await getAIResponse(for: userMessage)
            await MainActor.run {
                messages.append(response)
                isSending = false
            }
        }
    }
    
    private func getAIResponse(for message: ChatMessage) async -> ChatMessage {
        let questionText = message.content
        
        switch aiMode {
        case .appleIntelligence:
            if #available(iOS 18.0, *) {
                return await answerWithAppleIntelligence(question: questionText, image: message.image)
            }
            return ChatMessage(content: "Apple Intelligence non disponible".localized, isUser: false, aiModeString: AIMode.appleIntelligence.rawValue)
            
        case .gemini:
            if geminiService.isEnabled {
                return await answerWithGemini(question: questionText, image: message.image)
            }
            return ChatMessage(content: "Gemini non disponible".localized, isUser: false, aiModeString: AIMode.gemini.rawValue)
            
        case .shoplyAI:
            return await answerWithLocalAI(question: questionText, image: message.image)
        }
    }
    
    @available(iOS 18.0, *)
    private func answerWithAppleIntelligence(question: String, image: UIImage?) async -> ChatMessage {
        // Implémentation Apple Intelligence
        return ChatMessage(content: "Réponse Apple Intelligence".localized, isUser: false, aiModeString: AIMode.appleIntelligence.rawValue)
    }
    
    private func answerWithGemini(question: String, image: UIImage?) async -> ChatMessage {
        do {
            let userProfile = dataManager.loadUserProfile() ?? UserProfile()
            let currentWeather = weatherService.currentWeather
            let wardrobeItems = wardrobeService.items
            let conversationHistory = messages.filter { !$0.isSystemMessage }
            
            let response = try await geminiService.askAboutClothing(
                question: question,
                userProfile: userProfile,
                currentWeather: currentWeather,
                wardrobeItems: wardrobeItems,
                conversationHistory: conversationHistory
            )
            
            return ChatMessage(content: response, isUser: false, aiModeString: AIMode.gemini.rawValue)
        } catch {
            return ChatMessage(content: "Erreur: \(error.localizedDescription)".localized, isUser: false, aiModeString: AIMode.gemini.rawValue)
        }
    }
    
    private func answerWithLocalAI(question: String, image: UIImage?) async -> ChatMessage {
        let shoplyAI = ShoplyAIAdvancedLLM.shared
        let userProfile = dataManager.loadUserProfile()
        let currentWeather = weatherService.currentWeather
        let wardrobeItems = wardrobeService.items
        let conversationHistory = messages.filter { !$0.isSystemMessage }
        
        let response = await shoplyAI.generateResponse(
            input: question,
            userProfile: userProfile,
            currentWeather: currentWeather,
            wardrobeItems: wardrobeItems,
            conversationHistory: conversationHistory
        )
        
        return ChatMessage(content: response, isUser: false, aiModeString: AIMode.shoplyAI.rawValue)
    }
    
    private func scrollToBottom(proxy: ScrollViewProxy) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation {
                proxy.scrollTo("bottom", anchor: .bottom)
            }
        }
    }
    
    private func getSuggestions() -> [String] {
        let patternAnalyzer = UserMessagePatternAnalyzer.shared
        let patterns = patternAnalyzer.analyzeUserPatterns()
        let language = settingsManager.selectedLanguage.rawValue
        
        let personalizedSuggestions = patternAnalyzer.generatePersonalizedSuggestions(
            patterns: patterns,
            language: language
        )
        
        if personalizedSuggestions.isEmpty {
            return getDefaultSuggestions(language: language)
        }
        
        return personalizedSuggestions
    }
    
    private func getDefaultSuggestions(language: String) -> [String] {
        if language == "fr" {
            return [
                "Quel outfit me conseilles-tu ?",
                "Comment créer un look stylé ?",
                "Quelle tenue pour aujourd'hui ?"
            ]
        } else {
            return [
                "What outfit do you recommend?",
                "How to create a stylish look?",
                "What outfit for today?"
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
    }
    
    private func saveConversation() {
        let hasUserMessages = messages.contains { $0.isUser }
        guard hasUserMessages else {
            removeEmptyConversation()
            return
        }
        
        let firstUserMessage = messages.first { $0.isUser }
        let title = firstUserMessage?.content.prefix(30) ?? "Nouvelle conversation"
        let aiModeString = aiMode.rawValue
        
        var conversation = ChatConversation(
            id: conversationId,
            title: String(title),
            messages: messages,
            aiMode: aiModeString
        )
        conversation.lastMessageAt = messages.last?.timestamp ?? Date()
        
        var allConversations: [ChatConversation] = []
        if let data = UserDefaults.standard.data(forKey: "chatConversations"),
           let decoded = try? JSONDecoder().decode([ChatConversation].self, from: data) {
            allConversations = decoded
        }
        
        if let index = allConversations.firstIndex(where: { $0.id == conversationId }) {
            allConversations[index] = conversation
        } else {
            allConversations.append(conversation)
        }
        
        if let encoded = try? JSONEncoder().encode(allConversations) {
            UserDefaults.standard.set(encoded, forKey: "chatConversations")
        }
    }
    
    private func removeEmptyConversation() {
        var allConversations: [ChatConversation] = []
        if let data = UserDefaults.standard.data(forKey: "chatConversations"),
           let decoded = try? JSONDecoder().decode([ChatConversation].self, from: data) {
            allConversations = decoded
        }
        
        allConversations.removeAll { $0.id == conversationId }
        
        if let encoded = try? JSONEncoder().encode(allConversations) {
            UserDefaults.standard.set(encoded, forKey: "chatConversations")
        }
    }
}

// MARK: - Composants ChatAIScreen

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.md) {
            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(AppColors.secondaryText)
            
            Text("Comment puis-je vous aider ?".localized)
                .font(DesignSystem.Typography.title2())
                .foregroundColor(AppColors.primaryText)
                .multilineTextAlignment(.center)
        }
        .padding(DesignSystem.Spacing.xl)
    }
}

struct ChatMessageBubble: View {
    let message: ChatMessage
    let currentAIMode: ChatAIScreen.AIMode?
    @StateObject private var dataManager = DataManager.shared
    
    // Utiliser le mode stocké dans le message, ou le mode actuel en fallback
    private var messageAIMode: ChatAIScreen.AIMode? {
        if let aiModeString = message.aiModeString {
            return ChatAIScreen.AIMode(rawValue: aiModeString)
        }
        // Pour les anciens messages sans mode stocké, utiliser le mode actuel
        return message.isUser ? nil : currentAIMode
    }
    
    private var aiModeIcon: String {
        guard let mode = messageAIMode else { return "sparkles" }
        switch mode {
        case .gemini:
            return "star.circle.fill"
        case .shoplyAI:
            return "sparkles"
        case .appleIntelligence:
            return "brain"
        }
    }
    
    private var aiModeColor: Color {
        guard let mode = messageAIMode else { return AppColors.buttonPrimary }
        switch mode {
        case .gemini:
            return Color.blue
        case .shoplyAI:
            return AppColors.buttonPrimary
        case .appleIntelligence:
            return Color.purple
        }
    }
    
    private func modeLabel(_ mode: ChatAIScreen.AIMode) -> String {
        switch mode {
        case .gemini:
            return "Gemini"
        case .shoplyAI:
            return "Shoply AI"
        case .appleIntelligence:
            return "Apple"
        }
    }
    
    var body: some View {
        if message.isSystemMessage {
            HStack {
                Spacer()
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(AppColors.buttonPrimary)
                    
                    Text(message.content)
                        .font(DesignSystem.Typography.footnote())
                        .foregroundColor(AppColors.buttonPrimary)
                }
                .padding(.horizontal, DesignSystem.Spacing.md)
                .padding(.vertical, DesignSystem.Spacing.sm)
                .background(AppColors.buttonPrimary.opacity(0.1))
                .clipShape(Capsule())
                Spacer()
            }
        } else {
            HStack(alignment: .top, spacing: DesignSystem.Spacing.md) {
                if !message.isUser {
                    VStack(alignment: .leading, spacing: DesignSystem.Spacing.xs) {
                        ZStack {
                            Circle()
                                .fill(aiModeColor.opacity(0.2))
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: aiModeIcon)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(aiModeColor)
                        }
                        
                        if let mode = messageAIMode {
                            Text(modeLabel(mode))
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(aiModeColor)
                                .padding(.horizontal, DesignSystem.Spacing.xs)
                                .padding(.vertical, 2)
                                .background(aiModeColor.opacity(0.15))
                                .clipShape(Capsule())
                        }
                    }
                }
                
                VStack(alignment: message.isUser ? .trailing : .leading, spacing: DesignSystem.Spacing.xs) {
                    // Badge AI supprimé - plus de label au-dessus du message
                    
                    if let image = message.image {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 200, maxHeight: 200)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
                    }
                    
                    if !message.content.isEmpty && message.content != "Photo envoyée" {
                        Text(message.content)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(message.isUser ? AppColors.buttonPrimaryText : AppColors.primaryText)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(message.isUser ? AppColors.buttonPrimary : AppColors.cardBackground)
                            .overlay {
                                if !message.isUser {
                                    RoundedRectangle(cornerRadius: DesignSystem.Radius.lg)
                                        .stroke(aiModeColor.opacity(0.3), lineWidth: 1.5)
                                }
                            }
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.lg))
                    }
                }
                .frame(maxWidth: .infinity, alignment: message.isUser ? .trailing : .leading)
                
                if message.isUser {
                    // Photo de profil de l'utilisateur
                    if let profile = dataManager.loadUserProfile(),
                       let photo = profile.profilePhoto {
                        Image(uiImage: photo)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 40, height: 40)
                            .clipShape(Circle())
                            .overlay {
                                Circle()
                                    .stroke(AppColors.cardBorder, lineWidth: 1.5)
                            }
                    } else {
                        Circle()
                            .fill(AppColors.buttonPrimary)
                            .frame(width: 40, height: 40)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(AppColors.buttonPrimaryText)
                            }
                    }
                }
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
        }
    }
}

struct ChatMenuView: View {
    let onNewConversation: () -> Void
    let onShowHistory: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Options".localized)
                    .font(DesignSystem.Typography.headline())
                    .foregroundColor(AppColors.primaryText)
                Spacer()
            }
            .padding(.horizontal, DesignSystem.Spacing.lg)
            .padding(.vertical, DesignSystem.Spacing.md)
            
            Divider()
                .background(AppColors.separator)
            
            // Options
            VStack(spacing: 0) {
                Button(action: onNewConversation) {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(AppColors.buttonSecondary)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppColors.primaryText)
                        }
                        
                        Text("Nouvelle conversation".localized)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(AppColors.primaryText)
                        
                        Spacer()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
                
                Divider()
                    .background(AppColors.separator)
                    .padding(.leading, DesignSystem.Spacing.lg + 40 + DesignSystem.Spacing.md)
                
                Button(action: onShowHistory) {
                    HStack(spacing: DesignSystem.Spacing.md) {
                        ZStack {
                            Circle()
                                .fill(AppColors.buttonSecondary)
                                .frame(width: 40, height: 40)
                            
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(AppColors.primaryText)
                        }
                        
                        Text("Historique".localized)
                            .font(DesignSystem.Typography.body())
                            .foregroundColor(AppColors.primaryText)
                        
                        Spacer()
                    }
                    .padding(.horizontal, DesignSystem.Spacing.lg)
                    .padding(.vertical, DesignSystem.Spacing.md)
                    .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .background(AppColors.background)
    }
}

struct LoadingView: View {
    let aiMode: ChatAIScreen.AIMode?
    
    init(aiMode: ChatAIScreen.AIMode? = nil) {
        self.aiMode = aiMode
    }
    
    private var aiModeLabel: String {
        guard let mode = aiMode else { return "Shoply AI" }
        switch mode {
        case .gemini:
            return "Gemini"
        case .shoplyAI:
            return "Shoply AI"
        case .appleIntelligence:
            return "Apple"
        }
    }
    
    var body: some View {
        HStack(spacing: DesignSystem.Spacing.sm) {
            ProgressView()
                .scaleEffect(0.8)
            Text("\(aiModeLabel) réfléchit...".localized)
                .font(DesignSystem.Typography.footnote())
                .foregroundColor(AppColors.secondaryText)
        }
        .padding(DesignSystem.Spacing.md)
    }
}

struct SuggestionsView: View {
    let suggestions: [String]
    let onTap: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DesignSystem.Spacing.sm) {
                ForEach(suggestions, id: \.self) { suggestion in
                    Button(action: { onTap(suggestion) }) {
                        Text(suggestion)
                            .font(DesignSystem.Typography.footnote())
                            .foregroundColor(AppColors.primaryText)
                            .padding(.horizontal, DesignSystem.Spacing.md)
                            .padding(.vertical, DesignSystem.Spacing.sm)
                            .background(AppColors.cardBackground)
                            .overlay {
                                RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                                    .stroke(AppColors.cardBorder, lineWidth: 1)
                            }
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
                    }
                }
            }
        }
    }
}

struct ChatInputArea: View {
    @Binding var text: String
    let isSending: Bool
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var selectedImage: UIImage?
    let onSend: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        VStack(spacing: DesignSystem.Spacing.sm) {
            if let image = selectedImage {
                HStack(spacing: DesignSystem.Spacing.sm) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.sm))
                    
                    Text("Photo sélectionnée".localized)
                        .font(DesignSystem.Typography.footnote())
                        .foregroundColor(AppColors.secondaryText)
                    
                    Spacer()
                    
                    Button {
                        selectedImage = nil
                        selectedPhoto = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(AppColors.secondaryText)
                    }
                }
                .padding(DesignSystem.Spacing.sm)
                .background(AppColors.cardBackground)
                .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
                .padding(.horizontal, DesignSystem.Spacing.md)
            }
            
            HStack(spacing: DesignSystem.Spacing.sm) {
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    Image(systemName: "photo")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(AppColors.primaryText)
                        .frame(width: 36, height: 36)
                }
                
                TextField("Tapez votre message...".localized, text: $text, axis: .vertical)
                    .font(DesignSystem.Typography.body())
                    .foregroundColor(AppColors.primaryText)
                    .focused($isFocused)
                    .lineLimit(1...5)
                    .padding(.horizontal, DesignSystem.Spacing.md)
                    .padding(.vertical, DesignSystem.Spacing.sm)
                    .background(AppColors.cardBackground)
                    .overlay {
                        RoundedRectangle(cornerRadius: DesignSystem.Radius.md)
                            .stroke(AppColors.cardBorder, lineWidth: 1)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: DesignSystem.Radius.md))
                
                Button(action: onSend) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(text.isEmpty && selectedImage == nil ? AppColors.secondaryText : AppColors.buttonPrimary)
                }
                .disabled(text.isEmpty && selectedImage == nil || isSending)
            }
            .padding(.horizontal, DesignSystem.Spacing.md)
            .padding(.vertical, DesignSystem.Spacing.sm)
            .background(AppColors.background)
        }
    }
}
