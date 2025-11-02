//
//  IntelligentLocalAI.swift
//  Shoply
//
//  Intelligent Local AI Service avec traitement du langage naturel avancé
//

import Foundation
import UIKit
import NaturalLanguage

/// Shoply AI - Intelligence artificielle locale avec traitement du langage naturel
class IntelligentLocalAI {
    static let shared = IntelligentLocalAI()
    
    private init() {}
    
    // MARK: - Analyse de Question
    
    struct QuestionAnalysis {
        let intent: QuestionIntent
        let keywords: [String]
        let entities: [String]
        let sentiment: Sentiment
        let isQuestion: Bool
        let topic: Topic
    }
    
    enum QuestionIntent {
        case advice
        case comparison
        case recommendation
        case explanation
        case greeting
        case general
        case weather
        case colorMatching
        case outfitSuggestion
        case material
        case style
    }
    
    enum Sentiment {
        case positive
        case neutral
        case negative
        case question
    }
    
    enum Topic {
        case clothing
        case weather
        case colors
        case style
        case wardrobe
        case outfit
        case material
        case combination
        case general
    }
    
    // MARK: - Réponse Intelligente
    
    func generateIntelligentResponse(
        question: String,
        userProfile: UserProfile,
        currentWeather: WeatherData?,
        wardrobeItems: [WardrobeItem],
        conversationHistory: [ChatMessage] = [],
        image: UIImage? = nil
    ) -> String {
        // Analyser la question
        let analysis = analyzeQuestion(question)
        
        // Si une image est fournie, ajouter une note dans la réponse
        var imageNote = ""
        if image != nil {
            imageNote = " (Note: L'utilisateur a partagé une image avec cette question. Analysez l'image pour fournir des conseils précis.)"
        }
        
        let questionWithImage = question + imageNote
        
        // Générer une réponse contextuelle basée sur l'analyse
        switch analysis.intent {
        case .greeting:
            return generateGreetingResponse(userProfile: userProfile)
        case .advice:
            return generateAdviceResponse(question: questionWithImage, analysis: analysis, userProfile: userProfile, currentWeather: currentWeather, wardrobeItems: wardrobeItems)
        case .comparison:
            return generateComparisonResponse(question: questionWithImage, analysis: analysis, userProfile: userProfile, wardrobeItems: wardrobeItems)
        case .recommendation:
            return generateRecommendationResponse(question: questionWithImage, analysis: analysis, userProfile: userProfile, currentWeather: currentWeather, wardrobeItems: wardrobeItems)
        case .outfitSuggestion:
            return generateOutfitSuggestionResponse(question: questionWithImage, analysis: analysis, userProfile: userProfile, currentWeather: currentWeather, wardrobeItems: wardrobeItems)
        case .weather:
            return generateWeatherAdviceResponse(question: questionWithImage, analysis: analysis, userProfile: userProfile, currentWeather: currentWeather, wardrobeItems: wardrobeItems)
        case .colorMatching:
            return generateColorAdviceResponse(question: questionWithImage, analysis: analysis, userProfile: userProfile, wardrobeItems: wardrobeItems)
        case .style:
            return generateStyleAdviceResponse(question: questionWithImage, analysis: analysis, userProfile: userProfile, wardrobeItems: wardrobeItems)
        case .explanation:
            return generateExplanationResponse(question: questionWithImage, analysis: analysis, userProfile: userProfile, currentWeather: currentWeather, wardrobeItems: wardrobeItems)
        case .general:
            let response = generateGeneralResponse(question: questionWithImage, analysis: analysis, userProfile: userProfile, currentWeather: currentWeather, wardrobeItems: wardrobeItems)
            if image != nil {
                return response + "\n\n📸 J'ai reçu votre image. Pour une analyse plus précise de l'image, je recommande d'utiliser Gemini qui peut analyser les images en détail."
            }
            return response
        case .material:
            return generateMaterialAdviceResponse(question: questionWithImage, analysis: analysis, userProfile: userProfile, wardrobeItems: wardrobeItems)
        }
    }
    
    // MARK: - Analyse de Question
    
    private func analyzeQuestion(_ text: String) -> QuestionAnalysis {
        let lowercased = text.lowercased()
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Détecter si c'est une question
        let isQuestion = trimmed.hasSuffix("?") || 
                        trimmed.hasSuffix("?") ||
                        lowercased.contains("comment") ||
                        lowercased.contains("pourquoi") ||
                        lowercased.contains("quand") ||
                        lowercased.contains("quel") ||
                        lowercased.contains("quelle") ||
                        lowercased.contains("quoi") ||
                        lowercased.contains("est-ce") ||
                        lowercased.contains("dois")
        
        // Extraire les mots-clés
        let keywords = extractKeywords(from: lowercased)
        
        // Détecter l'intention
        let intent = detectIntent(from: lowercased, keywords: keywords, isQuestion: isQuestion)
        
        // Détecter le sujet
        let topic = detectTopic(from: lowercased, keywords: keywords)
        
        // Détecter le sentiment
        let sentiment = detectSentiment(from: lowercased)
        
        // Extraire les entités (vêtements, couleurs, etc.)
        let entities = extractEntities(from: lowercased, keywords: keywords)
        
        return QuestionAnalysis(
            intent: intent,
            keywords: keywords,
            entities: entities,
            sentiment: sentiment,
            isQuestion: isQuestion,
            topic: topic
        )
    }
    
    private func extractKeywords(from text: String) -> [String] {
        let allKeywords = [
            // Vêtements
            "jean", "jeans", "tshirt", "pull", "sweat", "veste", "manteau", "pantalon", "short", "robe",
            "chemise", "polo", "tee-shirt", "t-shirt", "chaussure", "basket", "botte", "sneaker",
            "chapeau", "casquette", "écharpe", "gants", "gants",
            // Couleurs
            "noir", "blanc", "rouge", "bleu", "vert", "jaune", "orange", "rose", "violet", "marron", "gris",
            "beige", "navy", "kaki", "bordeaux", "turquoise",
            // Matières
            "coton", "laine", "polyester", "denim", "cuir", "daim", "soie", "lin",
            // Météo
            "pluie", "pluvieux", "soleil", "ensoleillé", "froid", "chaud", "neige", "neigeux", "vent", "venteux",
            "température", "degré", "météo", "weather", "climate",
            // Style
            "décontracté", "casual", "formel", "chic", "élégant", "sport", "sportif", "élégant",
            // Actions
            "porter", "porterai", "porté", "mettre", "assortir", "matcher", "aller avec",
            "conseil", "recommandation", "suggestion", "mieux", "meilleur", "adapté"
        ]
        
        return allKeywords.filter { text.contains($0) }
    }
    
    private func detectIntent(from text: String, keywords: [String], isQuestion: Bool) -> QuestionIntent {
        // Salutations
        if text.contains("salut") || text.contains("bonjour") || text.contains("hello") || text.contains("hey") || text.contains("hi") {
            return .greeting
        }
        
        // Suggestions d'outfit
        if text.contains("outfit") || text.contains("tenue") || text.contains("porter") && (text.contains("aujourd") || text.contains("demain")) {
            return .outfitSuggestion
        }
        
        // Comparaisons
        if text.contains("mieux") || text.contains("meilleur") || text.contains("vs") || text.contains("ou") || text.contains("comparer") {
            return .comparison
        }
        
        // Recommandations
        if text.contains("recommand") || text.contains("suggest") || text.contains("conseil") {
            return .recommendation
        }
        
        // Météo
        if keywords.contains(where: { ["pluie", "soleil", "froid", "chaud", "neige", "météo", "température"].contains($0) }) {
            return .weather
        }
        
        // Couleurs
        if keywords.contains(where: { ["noir", "blanc", "rouge", "bleu", "vert", "couleur", "color"].contains($0) }) {
            return .colorMatching
        }
        
        // Style
        if keywords.contains(where: { ["décontracté", "formel", "chic", "sport", "style"].contains($0) }) {
            return .style
        }
        
        // Matières
        if keywords.contains(where: { ["coton", "laine", "denim", "cuir", "matière"].contains($0) }) {
            return .material
        }
        
        // Explications
        if text.contains("pourquoi") || text.contains("comment") || text.contains("explique") {
            return .explanation
        }
        
        // Par défaut, conseil
        return isQuestion ? .advice : .general
    }
    
    private func detectTopic(from text: String, keywords: [String]) -> Topic {
        if keywords.contains(where: { ["jean", "jeans", "pantalon", "robe", "chemise"].contains($0) }) {
            return .clothing
        }
        if keywords.contains(where: { ["pluie", "soleil", "froid", "chaud", "météo"].contains($0) }) {
            return .weather
        }
        if keywords.contains(where: { ["couleur", "color", "noir", "blanc"].contains($0) }) {
            return .colors
        }
        if text.contains("outfit") || text.contains("tenue") {
            return .outfit
        }
        if text.contains("garde-robe") || text.contains("wardrobe") {
            return .wardrobe
        }
        if keywords.contains(where: { ["style", "chic", "décontracté"].contains($0) }) {
            return .style
        }
        return .general
    }
    
    private func detectSentiment(from text: String) -> Sentiment {
        let positiveWords = ["super", "génial", "parfait", "excellent", "j'adore", "j'aime"]
        let negativeWords = ["pas", "non", "déteste", "horrible", "mauvais"]
        let questionWords = ["comment", "pourquoi", "quel", "quelle", "?", "?"]
        
        if questionWords.contains(where: { text.contains($0) }) {
            return .question
        }
        if positiveWords.contains(where: { text.contains($0) }) {
            return .positive
        }
        if negativeWords.contains(where: { text.contains($0) }) {
            return .negative
        }
        return .neutral
    }
    
    private func extractEntities(from text: String, keywords: [String]) -> [String] {
        return keywords.filter { keyword in
            let clothingItems = ["jean", "jeans", "pantalon", "robe", "chemise", "veste", "manteau"]
            let colors = ["noir", "blanc", "rouge", "bleu"]
            return clothingItems.contains(keyword) || colors.contains(keyword)
        }
    }
    
    // MARK: - Génération de Réponses
    
    private func generateGreetingResponse(userProfile: UserProfile) -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        let name = userProfile.firstName.isEmpty ? "" : " \(userProfile.firstName)"
        
        var greeting = ""
        if hour < 12 {
            greeting = "Bonjour"
        } else if hour < 18 {
            greeting = "Bon après-midi"
        } else {
            greeting = "Bonsoir"
        }
        
        let responses = [
            "\(greeting)\(name) ! 😊 Je suis là pour vous aider avec vos questions sur la mode, les outfits et les vêtements. Que souhaitez-vous savoir ?",
            "\(greeting)\(name) ! 👋 Comment puis-je vous aider aujourd'hui avec vos choix vestimentaires ?",
            "\(greeting) ! ✨ Posez-moi vos questions sur la mode, les couleurs, la météo, ou vos outfits - je suis là pour vous conseiller !"
        ]
        
        return responses.randomElement() ?? responses[0]
    }
    
    private func generateAdviceResponse(
        question: String,
        analysis: QuestionAnalysis,
        userProfile: UserProfile,
        currentWeather: WeatherData?,
        wardrobeItems: [WardrobeItem]
    ) -> String {
        let lowercased = question.lowercased()
        
        // Conseils spécifiques selon les entités détectées
        if lowercased.contains("jean") && (lowercased.contains("pluie") || lowercased.contains("pluvieux")) {
            return generateJeansRainAdvice()
        }
        
        if lowercased.contains("sport") {
            return generateSportAdvice(currentWeather: currentWeather, wardrobeItems: wardrobeItems)
        }
        
        if lowercased.contains("couleur") || analysis.topic == .colors {
            return generateColorMatchingAdvice(question: question, wardrobeItems: wardrobeItems)
        }
        
        // Réponse générique intelligente basée sur le contexte
        return generateContextualAdvice(question: question, analysis: analysis, userProfile: userProfile, currentWeather: currentWeather, wardrobeItems: wardrobeItems)
    }
    
    private func generateJeansRainAdvice() -> String {
        let responses = [
            "Les jeans sous la pluie peuvent fonctionner, mais cela dépend du type de jean ! 👖💧\n\n✅ **Jeans épais/dark wash** : Ils résistent mieux à l'humidité et mettent plus de temps à sécher.\n❌ **Jeans clairs/élastiques** : Ils peuvent montrer des taches d'eau et être inconfortables mouillés.\n\n💡 **Conseil** : Si vous prévoyez de sortir sous la pluie, optez pour un jean sombre et épais, ou portez plutôt un pantalon en tissu technique imperméable.",
            "Pour les jeans sous la pluie, tout dépend ! 🌧️\n\n✨ **Jeans sombres épais**** : Supportent mieux l'humidité\n\n💧 **Jeans clairs** : Risquent de montrer les taches d'eau\n\n🎯 **Alternative** : Un pantalon cargo ou en tissu technique serait plus adapté pour la pluie.",
            "Les jeans peuvent être portés sous la pluie, mais attention :\n\n• Les jeans épais (denim brut) mettent du temps à sécher mais sont plus résistants\n• Les jeans clairs ou avec stretch montrent souvent les traces d'eau\n• Après la pluie, ils peuvent rester humides et froids\n\n💡 Si vous savez qu'il va pleuvoir, un pantalon imperméable serait plus confortable !"
        ]
        return responses.randomElement() ?? responses[0]
    }
    
    private func generateSportAdvice(currentWeather: WeatherData?, wardrobeItems: [WardrobeItem]) -> String {
        var advice = "Pour le sport, voici mes conseils :\n\n"
        
        if let weather = currentWeather {
            if weather.temperature < 10 {
                advice += "🧊 **Par temps froid** : Portez plusieurs couches (sous-vêtements techniques + couche intermédiaire + veste légère). Vous pourrez retirer des couches si vous avez chaud.\n\n"
            } else if weather.temperature > 20 {
                advice += "☀️ **Par temps chaud** : Privilégiez des vêtements légers en matière respirante (coton technique, polyester). Portez des couleurs claires qui réfléchissent la chaleur.\n\n"
            }
            
            if weather.condition == .rainy {
                advice += "🌧️ **S'il pleut** : Portez une veste imperméable et des vêtements qui sèchent vite (évitez le coton qui reste humide).\n\n"
            }
        }
        
        advice += "✅ **Conseils généraux** :\n• Chaussures adaptées à votre activité\n• Vêtements respirants qui évacuent la transpiration\n• Évitez le coton qui reste humide\n• Portez des couches que vous pouvez retirer facilement"
        
        return advice
    }
    
    private func generateColorMatchingAdvice(question: String, wardrobeItems: [WardrobeItem]) -> String {
        let lowercased = question.lowercased()
        
        // Extraire les couleurs mentionnées
        let colors = ["noir", "blanc", "rouge", "bleu", "vert", "jaune", "orange", "rose", "violet", "marron", "gris", "beige"]
        let mentionedColors = colors.filter { lowercased.contains($0) }
        
        if !mentionedColors.isEmpty {
            return generateSpecificColorAdvice(colors: mentionedColors, wardrobeItems: wardrobeItems)
        }
        
        return """
        🎨 **Conseils d'assortiment de couleurs** :
        
        **Combinaisons classiques** :
        • Noir + Blanc = Élégant et intemporel
        • Bleu + Blanc = Frais et décontracté
        • Gris + Une couleur vive = Équilibre parfait
        
        **Combinaisons audacieuses** :
        • Rouge + Bleu = Contraste moderne
        • Jaune + Bleu = Énergique et joyeux
        • Vert + Marron = Naturel et apaisant
        
        **Règle du 60-30-10** :
        • 60% couleur principale (ex: pantalon/noir)
        • 30% couleur secondaire (ex: veste/bleu)
        • 10% couleur d'accent (ex: accessoires/rouge)
        
        Quelle couleur souhaitez-vous assortir ? Je peux vous donner des conseils plus précis ! 😊
        """
    }
    
    private func generateSpecificColorAdvice(colors: [String], wardrobeItems: [WardrobeItem]) -> String {
        guard let firstColor = colors.first else {
            return generateColorMatchingAdvice(question: "", wardrobeItems: wardrobeItems)
        }
        
        var advice = "🎨 **Assortiment avec \(firstColor.capitalized)** :\n\n"
        
        switch firstColor.lowercased() {
        case "noir":
            advice += "✅ S'assortit avec TOUT ! Noir est la couleur la plus versatile.\n• Noir + Blanc = Classique\n• Noir + Rouge = Audacieux\n• Noir + Gris = Sophistiqué\n• Noir + Une couleur vive = Équilibre parfait\n\n💡 Conseil : Utilisez le noir comme base et ajoutez une couleur d'accent."
        case "blanc":
            advice += "✅ Le blanc s'assortit facilement :\n• Blanc + Noir = Contrasté\n• Blanc + Bleu = Frais et marin\n• Blanc + Pastel = Doux et élégant\n• Blanc + Couleur vive = Énergique\n\n💡 Évitez le blanc pur sous la pluie si possible."
        case "bleu":
            advice += "✅ Le bleu se marie bien avec :\n• Bleu + Blanc = Nautique et frais\n• Bleu + Gris = Profesionnel\n• Bleu + Jaune = Contraste joyeux\n• Bleu + Marron = Casual chic\n\n💡 Le bleu marine est très versatile pour le quotidien."
        case "rouge":
            advice += "✅ Le rouge crée des looks audacieux :\n• Rouge + Noir = Élégant et moderne\n• Rouge + Blanc = Frappant\n• Rouge + Bleu = Contraste intéressant\n• Rouge + Neutres = Mise en valeur du rouge\n\n💡 Utilisez le rouge en accent sur une base neutre."
        default:
            advice += "✅ Cette couleur s'assortit bien avec des couleurs neutres (noir, blanc, gris, beige). Pour un look audacieux, essayez avec des couleurs complémentaires !"
        }
        
        return advice
    }
    
    private func generateContextualAdvice(
        question: String,
        analysis: QuestionAnalysis,
        userProfile: UserProfile,
        currentWeather: WeatherData?,
        wardrobeItems: [WardrobeItem]
    ) -> String {
        var advice = ""
        
        // Intégrer le contexte météo si disponible
        if let weather = currentWeather {
            let temp = Int(weather.temperature)
            
            if temp < 10 {
                advice += "🌨️ Par temps froid (\(temp)°C), je recommande :\n• Plusieurs couches (sous-vêtements + pull + manteau)\n• Matières chaudes (laine, polaire)\n• Évitez les matières trop fines\n\n"
            } else if temp > 25 {
                advice += "☀️ Par temps chaud (\(temp)°C), optez pour :\n• Vêtements légers et respirants\n• Couleurs claires\n• Matières naturelles (coton, lin)\n• Évitez les matières synthétiques qui collent\n\n"
            }
            
            if weather.condition == .rainy {
                advice += "🌧️ Il pleut aujourd'hui :\n• Privilégiez un manteau imperméable\n• Chaussures fermées et résistantes à l'eau\n• Évitez les matières qui marquent (jeans clairs, cuir)\n\n"
            }
        }
        
        // Conseils basés sur la garde-robe
        if !wardrobeItems.isEmpty {
            let tops = wardrobeItems.filter { $0.category == .top }
            let bottoms = wardrobeItems.filter { $0.category == .bottom }
            
            if !tops.isEmpty && !bottoms.isEmpty {
                advice += "💡 **Idée d'outfit pour vous** :\n"
                if let top = tops.randomElement(), let bottom = bottoms.randomElement() {
                    advice += "• \(top.name) + \(bottom.name)\n"
                    
                    // Ajouter des chaussures si disponibles
                    if let shoes = wardrobeItems.filter({ $0.category == .shoes }).randomElement() {
                        advice += "• Avec vos \(shoes.name)\n"
                    }
                }
                advice += "\n"
            }
        }
        
        // Ajouter un conseil général si la réponse est courte
        if advice.isEmpty || advice.count < 50 {
            advice += "✨ Pour répondre précisément à votre question, pouvez-vous donner plus de détails ? (couleur préférée, occasion, style recherché...)"
        }
        
        return advice.isEmpty ? "Je peux vous aider ! Pourriez-vous préciser votre question ? 😊" : advice
    }
    
    private func generateComparisonResponse(
        question: String,
        analysis: QuestionAnalysis,
        userProfile: UserProfile,
        wardrobeItems: [WardrobeItem]
    ) -> String {
        let lowercased = question.lowercased()
        
        if lowercased.contains("vs") || lowercased.contains("ou") {
            return """
            Pour comparer des options, voici ce que je recommande :
            
            📊 **Critères de comparaison** :
            1. **Confort** : Quelle option est plus confortable ?
            2. **Occasion** : Pour quel événement/moment ?
            3. **Météo** : S'adapte-t-elle aux conditions ?
            4. **Style** : Quelle correspond à votre style ?
            5. **Versatilité** : Avec quoi pouvez-vous l'assortir ?
            
            Quelles options comparez-vous exactement ? Je peux vous aider à choisir ! 😊
            """
        }
        
        return generateContextualAdvice(question: question, analysis: analysis, userProfile: userProfile, currentWeather: nil, wardrobeItems: wardrobeItems)
    }
    
    private func generateRecommendationResponse(
        question: String,
        analysis: QuestionAnalysis,
        userProfile: UserProfile,
        currentWeather: WeatherData?,
        wardrobeItems: [WardrobeItem]
    ) -> String {
        // Générer des recommandations basées sur le contexte
        var recommendations: [String] = []
        
        if let weather = currentWeather {
            let temp = Int(weather.temperature)
            
            if temp < 10 {
                recommendations.append("• Un manteau chaud (doudoune ou laine)")
                recommendations.append("• Un pull épais ou une polaire")
                recommendations.append("• Des chaussures fermées et imperméables")
            } else if temp > 20 {
                recommendations.append("• Des vêtements légers en coton ou lin")
                recommendations.append("• Des couleurs claires")
                recommendations.append("• Des chaussures ouvertes ou baskets légères")
            }
        }
        
        // Recommandations basées sur la garde-robe
        if !wardrobeItems.isEmpty {
            let favorites = wardrobeItems.filter { $0.isFavorite }
            if !favorites.isEmpty {
                recommendations.append("• Commencez par vos favoris : " + favorites.prefix(3).map { $0.name }.joined(separator: ", "))
            }
        }
        
        if recommendations.isEmpty {
            return generateContextualAdvice(question: question, analysis: analysis, userProfile: userProfile, currentWeather: currentWeather, wardrobeItems: wardrobeItems)
        }
        
        return "✨ **Mes recommandations pour vous** :\n\n" + recommendations.joined(separator: "\n") + "\n\n💡 Besoin de conseils plus précis ? Dites-moi votre style préféré ou l'occasion !"
    }
    
    private func generateOutfitSuggestionResponse(
        question: String,
        analysis: QuestionAnalysis,
        userProfile: UserProfile,
        currentWeather: WeatherData?,
        wardrobeItems: [WardrobeItem]
    ) -> String {
        guard !wardrobeItems.isEmpty else {
            return "Je peux vous suggérer des outfits ! Mais d'abord, ajoutez quelques vêtements à votre garde-robe. 😊"
        }
        
        let tops = wardrobeItems.filter { $0.category == .top }
        let bottoms = wardrobeItems.filter { $0.category == .bottom }
        let shoes = wardrobeItems.filter { $0.category == .shoes }
        
        guard !tops.isEmpty && !bottoms.isEmpty else {
            return "Ajoutez au moins un haut et un bas à votre garde-robe pour que je puisse vous suggérer des outfits ! 👕👖"
        }
        
        var suggestions: [String] = []
        
        // Générer 2-3 suggestions d'outfits
        for i in 1...min(3, max(1, min(tops.count, bottoms.count))) {
            if let top = tops.randomElement(), let bottom = bottoms.randomElement() {
                var outfit = "**Outfit \(i)** : \(top.name)"
                
                // Vérifier la cohérence des couleurs
                if top.color == bottom.color {
                    outfit += " (monochrome élégant)"
                }
                
                outfit += " + \(bottom.name)"
                
                if let shoe = shoes.randomElement() {
                    outfit += " + \(shoe.name)"
                }
                
                suggestions.append(outfit)
            }
        }
        
        var response = "✨ **Suggestions d'outfits pour vous** :\n\n"
        response += suggestions.joined(separator: "\n")
        
        if let weather = currentWeather {
            let temp = Int(weather.temperature)
            response += "\n\n🌡️ **Adapté à \(temp)°C** - "
            
            if temp < 10 {
                response += "Pensez à ajouter une couche supplémentaire si besoin !"
            } else if temp > 25 {
                response += "Parfait pour ce temps chaud !"
            }
        }
        
        return response
    }
    
    private func generateWeatherAdviceResponse(
        question: String,
        analysis: QuestionAnalysis,
        userProfile: UserProfile,
        currentWeather: WeatherData?,
        wardrobeItems: [WardrobeItem]
    ) -> String {
        guard let weather = currentWeather else {
            return "Je peux vous conseiller selon la météo ! Pour l'instant, je n'ai pas les informations météo. Ajoutez-les dans les paramètres de l'app ! 🌤️"
        }
        
        let temp = Int(weather.temperature)
        let condition = weather.condition
        
        var advice = "🌡️ **Météo actuelle : \(temp)°C, \(condition.rawValue)**\n\n"
        
        // Conseils selon la température
        if temp < 5 {
            advice += "🧊 **Très froid** :\n• Manteau épais obligatoire (doudoune, laine épaisse)\n• Plusieurs couches (sous-vêtements + pull + manteau)\n• Gants, écharpe, bonnet\n• Chaussures fermées et isolantes\n\n"
        } else if temp < 10 {
            advice += "❄️ **Froid** :\n• Manteau chaud (laine, polaire)\n• Pull ou cardigan\n• Chaussures fermées\n• Accessoires (gants, écharpe) optionnels\n\n"
        } else if temp < 15 {
            advice += "🍂 **Frais** :\n• Veste ou blazer\n• Pull léger ou cardigan\n• Pantalon long\n• Chaussures fermées ou baskets\n\n"
        } else if temp < 20 {
            advice += "🌤️ **Doux** :\n• Veste légère ou cardigan\n• Pantalon long ou jean\n• Baskets ou chaussures fermées\n• Vous pouvez retirer la veste si vous avez chaud\n\n"
        } else if temp < 25 {
            advice += "☀️ **Agréable** :\n• T-shirt ou chemise légère\n• Pantalon ou jean\n• Baskets ou chaussures ouvertes\n• Veste légère au cas où\n\n"
        } else {
            advice += "🔥 **Chaud** :\n• Vêtements légers (coton, lin)\n• Couleurs claires\n• Shorts ou jupes légères\n• Chaussures ouvertes\n• Évitez les matières synthétiques\n\n"
        }
        
        // Conseils selon les conditions
        switch condition {
        case .rainy:
            advice += "🌧️ **Il pleut** :\n• Manteau imperméable ou parapluie\n• Chaussures résistantes à l'eau (évitez les baskets en toile)\n• Évitez les matières qui marquent (jeans clairs, cuir)\n• Pantalon qui sèche vite\n\n"
        case .snowy:
            advice += "❄️ **Il neige** :\n• Manteau imperméable et isolant\n• Bottes ou chaussures à semelle antidérapante\n• Gants épais\n• Pantalon qui ne colle pas à la neige\n\n"
        case .windy:
            advice += "💨 **Venteux** :\n• Veste qui coupe le vent\n• Évitez les vêtements trop amples qui volent\n• Accessoires bien attachés (écharpe, casquette)\n\n"
        default:
            break
        }
        
        // Suggestions depuis la garde-robe
        if !wardrobeItems.isEmpty {
            let suitableItems = wardrobeItems.filter { item in
                if temp < 15 {
                    return item.category == .outerwear || item.material?.lowercased().contains("laine") == true
                } else if temp > 20 {
                    return item.material?.lowercased().contains("coton") == true || item.material?.lowercased().contains("lin") == true
                }
                return true
            }
            
            if !suitableItems.isEmpty {
                advice += "💡 **Dans votre garde-robe, je recommande** :\n"
                advice += suitableItems.prefix(3).map { "• \($0.name)" }.joined(separator: "\n")
            }
        }
        
        return advice
    }
    
    private func generateColorAdviceResponse(
        question: String,
        analysis: QuestionAnalysis,
        userProfile: UserProfile,
        wardrobeItems: [WardrobeItem]
    ) -> String {
        return generateColorMatchingAdvice(question: question, wardrobeItems: wardrobeItems)
    }
    
    private func generateStyleAdviceResponse(
        question: String,
        analysis: QuestionAnalysis,
        userProfile: UserProfile,
        wardrobeItems: [WardrobeItem]
    ) -> String {
        let lowercased = question.lowercased()
        
        if lowercased.contains("décontracté") || lowercased.contains("casual") {
            return """
            👕 **Style décontracté** :
            
            **Essentiels** :
            • Jeans ou chinos
            • T-shirts basiques
            • Sweats ou pulls confortables
            • Baskets ou sneakers
            • Veste en jean ou blouson
            
            **Conseils** :
            • Privilégiez le confort
            • Coupes relaxées mais pas trop larges
            • Matières douces (coton, jersey)
            • Couleurs neutres faciles à assortir
            
            **Exemple d'outfit** :
            T-shirt blanc + Jeans + Baskets blanches + Blouson en jean = Look casual parfait ! 😊
            """
        }
        
        if lowercased.contains("formel") || lowercased.contains("professionnel") {
            return """
            👔 **Style formel/professionnel** :
            
            **Essentiels** :
            • Costume ou veste + pantalon assorti
            • Chemises bien repassées
            • Chaussures de ville
            • Cravate (selon le contexte)
            
            **Conseils** :
            • Privilégiez les coupes ajustées
            • Couleurs sobres (navy, gris, noir)
            • Matières de qualité (laine, coton)
            • Accessoires discrets mais soignés
            
            **Exemple d'outfit** :
            Costume navy + Chemise blanche + Chaussures noires = Professionnel et élégant ! 💼
            """
        }
        
        if lowercased.contains("chic") || lowercased.contains("élégant") {
            return """
            ✨ **Style chic/élégant** :
            
            **Caractéristiques** :
            • Pièces de qualité
            • Coupes bien ajustées
            • Matières nobles (soie, laine, cuir)
            • Couleurs sophistiquées
            
            **Conseils** :
            • Moins mais mieux (qualité > quantité)
            • Accessoires soignés
            • Silhouette équilibrée
            • Attention aux détails
            
            **Exemple d'outfit** :
            Blazer noir + Pantalon large + Escarpins = Chic et moderne ! 👗
            """
        }
        
        return """
        🎨 **Styles disponibles** :
        
        • **Décontracté** : Confortable et détendu
        • **Formel** : Professionnel et soigné
        • **Chic** : Élégant et raffiné
        • **Sport** : Actif et pratique
        
        Quel style vous intéresse ? Je peux vous donner des conseils détaillés ! 😊
        """
    }
    
    private func generateExplanationResponse(
        question: String,
        analysis: QuestionAnalysis,
        userProfile: UserProfile,
        currentWeather: WeatherData?,
        wardrobeItems: [WardrobeItem]
    ) -> String {
        let lowercased = question.lowercased()
        
        if lowercased.contains("pourquoi") {
            return """
            Pour bien répondre à votre "pourquoi", j'aurais besoin de plus de contexte ! 😊
            
            Voici des exemples de questions que je peux expliquer :
            • Pourquoi porter certaines couleurs ensemble ?
            • Pourquoi adapter ses vêtements à la météo ?
            • Pourquoi choisir certaines matières ?
            • Pourquoi certains styles fonctionnent mieux que d'autres ?
            
            Reformulez votre question avec plus de détails et je vous expliquerai ! ✨
            """
        }
        
        if lowercased.contains("comment") {
            return """
            Je peux vous expliquer comment faire beaucoup de choses ! 😊
            
            Par exemple :
            • Comment assortir les couleurs
            • Comment créer un outfit équilibré
            • Comment adapter sa tenue à la météo
            • Comment choisir les bonnes matières
            • Comment créer différents styles
            
            Quelle technique souhaitez-vous apprendre ? Donnez-moi plus de détails ! ✨
            """
        }
        
        return generateContextualAdvice(question: question, analysis: analysis, userProfile: userProfile, currentWeather: currentWeather, wardrobeItems: wardrobeItems)
    }
    
    private func generateGeneralResponse(
        question: String,
        analysis: QuestionAnalysis,
        userProfile: UserProfile,
        currentWeather: WeatherData?,
        wardrobeItems: [WardrobeItem]
    ) -> String {
        // Réponse générale intelligente qui essaie de comprendre l'intention
        let responses = [
            "Je comprends votre question ! Pour vous donner une réponse précise, pourriez-vous donner plus de détails ? (style recherché, occasion, couleurs préférées, etc.) 😊",
            "Intéressant ! Pour mieux vous conseiller, dites-moi :\n• Quel style vous plaît ?\n• Pour quelle occasion ?\n• Quelles sont vos préférences de couleurs ?\n\nAvec ces infos, je pourrai vous aider plus précisément ! ✨",
            "Je peux vous aider avec ça ! Pour une réponse vraiment adaptée, précisez :\n• Le contexte (quotidien, événement, sport...)\n• Vos goûts personnels\n• Les contraintes (météo, dress code...)\n\nPlus vous me donnez d'infos, mieux je peux vous conseiller ! 💡"
        ]
        
        return responses.randomElement() ?? responses[0]
    }
    
    private func generateMaterialAdviceResponse(
        question: String,
        analysis: QuestionAnalysis,
        userProfile: UserProfile,
        wardrobeItems: [WardrobeItem]
    ) -> String {
        let lowercased = question.lowercased()
        
        var advice = "🧵 **Conseils sur les matières** :\n\n"
        
        if lowercased.contains("coton") {
            advice += "**Coton** :\n✅ Respirant, confortable, facile à entretenir\n❌ Peut rétrécir, sèche lentement\n💡 Idéal pour le quotidien et la chaleur\n\n"
        }
        
        if lowercased.contains("laine") {
            advice += "**Laine** :\n✅ Chaleureuse, isolante, naturelle\n❌ Peut démanger, nécessite un entretien délicat\n💡 Parfait pour l'hiver et les pulls\n\n"
        }
        
        if lowercased.contains("denim") || lowercased.contains("jean") {
            advice += "**Denim** :\n✅ Résistant, durable, intemporel\n❌ Peut être rigide au début\n💡 Classique pour les jeans, s'assouplit avec le temps\n\n"
        }
        
        if lowercased.contains("polyester") {
            advice += "**Polyester** :\n✅ Sèche vite, léger, peu coûteux\n❌ Peut être moins respirant, peut coller\n💡 Bon pour le sport, évitez pour le quotidien si possible\n\n"
        }
        
        if advice.count < 100 {
            advice += """
            **Matières courantes** :
            • **Coton** : Confortable, respirant
            • **Laine** : Chaude, naturelle
            • **Denim** : Résistant, durable
            • **Lin** : Frais, léger (été)
            • **Soie** : Luxueux, doux
            • **Cuir** : Résistant, classe
            
            Quelle matière vous intéresse ? Je peux détailler ! 😊
            """
        }
        
        return advice
    }
}

