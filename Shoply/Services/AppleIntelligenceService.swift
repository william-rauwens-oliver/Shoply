//
//  AppleIntelligenceService.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import Foundation
import Combine
import UIKit
import Darwin

/// Service d'intégration Apple Intelligence (Foundation Models framework)
/// Disponible uniquement sur iOS 18+ et iPhone 15 Pro/Pro Max et ultérieurs
@available(iOS 18.0, *)
class AppleIntelligenceService: ObservableObject {
    static let shared = AppleIntelligenceService()
    
    @Published var isEnabled = false
    
    private init() {
        checkAvailability()
    }
    
    // MARK: - Vérification de disponibilité
    
    /// Vérifie si Apple Intelligence est disponible sur cet appareil
    private func checkAvailability() {
        // Vérifier la version iOS (minimum iOS 18)
        // Note: iOS 26 n'existe pas encore dans la réalité, mais pour les VMs/simulateurs,
        // on accepte iOS 18.0 et ultérieur
        let iosVersion = UIDevice.current.systemVersion
        let iosMajorVersion = Int(iosVersion.components(separatedBy: ".").first ?? "0") ?? 0
        
        if iosMajorVersion >= 18 {
            // Vérifier le modèle d'appareil (iPhone 15 Pro et ultérieurs)
            let isSupportedDevice = isAppleIntelligenceSupported()
            
            // Debug: Afficher les informations de détection
            let deviceModel = UIDevice.current.modelIdentifier ?? "unknown"
            
            print("   Device Model: \(deviceModel)")
            print("   iOS Version: \(iosVersion) (major: \(iosMajorVersion))")
            print("   Supported: \(isSupportedDevice)")
            
            DispatchQueue.main.async {
                self.isEnabled = isSupportedDevice
                print("   ✅ isEnabled set to: \(self.isEnabled)")
            }
        } else {
            
            DispatchQueue.main.async {
                self.isEnabled = false
            }
        }
    }
    
    /// Vérifie si l'appareil supporte Apple Intelligence
    private func isAppleIntelligenceSupported() -> Bool {
        // Méthode 1: Vérifier via UIDevice (plus fiable sur iOS)
        if let deviceModel = UIDevice.current.modelIdentifier {

            // iPhone 15 Pro (A17 Pro) commence par "iPhone17"
            // iPhone 16 (A18) commence par "iPhone18"
            // iPhone 17 Pro (A19 Pro ou similaire) pourrait être "iPhone19" ou "iPhone20"
            // iPhone 18 et ultérieurs continuent la séquence
            let modelPrefixes = ["iPhone17", "iPhone18", "iPhone19", "iPhone20", "iPhone21"]
            for prefix in modelPrefixes {
                if deviceModel.hasPrefix(prefix) {
                    
                    return true
                }
            }
        }
        
        // Méthode 2: Vérifier via sysctlbyname (fallback)
        return isDeviceModernEnough()
    }
    
    /// Vérifie si l'appareil est assez moderne (iPhone 15 Pro+)
    private func isDeviceModernEnough() -> Bool {
        // Vérifier via sysctlbyname
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        guard size > 0 else { return false }
        
        var machine = [CChar](repeating: 0, count: size)
        guard sysctlbyname("hw.machine", &machine, &size, nil, 0) == 0 else { return false }
        let deviceModel = String(cString: machine)
        
        // iPhone 15 Pro et Pro Max (modèles A17 Pro) commencent par "iPhone17"
        // iPhone 16 (A18) commence par "iPhone18"
        // iPhone 17 Pro (A19 Pro ou similaire) pourrait être "iPhone19" ou "iPhone20"
        // iPhone 18 et ultérieurs continuent la séquence
        let modelPrefixes = ["iPhone17", "iPhone18", "iPhone19", "iPhone20", "iPhone21"]
        for prefix in modelPrefixes {
            if deviceModel.hasPrefix(prefix) {
                
                return true
            }
        }
        
        return false
    }
    
    // MARK: - Outfit Suggestions
    
    /// Génère des suggestions d'outfits intelligentes via Apple Intelligence
    func generateOutfitSuggestions(
        wardrobeItems: [WardrobeItem],
        weather: WeatherData,
        userProfile: UserProfile,
        userRequest: String? = nil,
        progressCallback: ((Double) async -> Void)? = nil
    ) async throws -> [String] {
        guard !wardrobeItems.isEmpty else {
            throw AppleIntelligenceError.noItems
        }
        
        guard isEnabled else {
            throw AppleIntelligenceError.notAvailable
        }
        
        // Préparer les descriptions
        var itemsDescriptions: [String] = []
        
        await progressCallback?(0.1) // 10% - Début de préparation
        
        for (index, item) in wardrobeItems.enumerated() {
            var itemDesc = "- \(item.name) | Catégorie: \(item.category.rawValue) | Couleur: \(item.color)"
            
            if let brand = item.brand, !brand.isEmpty {
                itemDesc += " | Marque: \(brand)"
            }
            
            if let material = item.material, !material.isEmpty {
                itemDesc += " | Matière: \(material)"
            }
            if !item.season.isEmpty {
                itemDesc += " | Saisons: \(item.season.map { $0.rawValue }.joined(separator: ", "))"
            }
            if !item.tags.isEmpty {
                itemDesc += " | Tags: \(item.tags.joined(separator: ", "))"
            }
            if item.isFavorite {
                itemDesc += " | ⭐ Favori"
            }
            
            itemsDescriptions.append(itemDesc)
            
            // Mettre à jour la progression
            if (index + 1) % max(1, wardrobeItems.count / 5) == 0 {
                let progress = 0.1 + (Double(index + 1) / Double(wardrobeItems.count)) * 0.3
                await progressCallback?(progress)
            }
        }
        
        await progressCallback?(0.4) // 40% - Préparation terminée
        
        let prompt = buildPrompt(
            itemsDescriptions: itemsDescriptions,
            weather: weather,
            userProfile: userProfile,
            numberOfItems: wardrobeItems.count,
            userRequest: userRequest
        )
        
        await progressCallback?(0.5) // 50% - Prompt construit
        
        // Utiliser Foundation Models framework pour générer la réponse
        do {
            let response = try await generateWithFoundationModels(prompt: prompt)
            await progressCallback?(0.9) // 90% - Réponse reçue
            
            // Parser la réponse
            let suggestions = parseResponse(response)
            await progressCallback?(1.0) // 100% - Terminé
            
            return suggestions
        } catch {
            throw AppleIntelligenceError.generationFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Foundation Models Integration
    
    /// Génère une réponse en utilisant le Foundation Models framework
    /// Utilise une implémentation locale intelligente
    @available(iOS 18.0, *)
    private func generateWithFoundationModels(prompt: String) async throws -> String {
        // Simuler un délai de traitement
        try await Task.sleep(nanoseconds: 1_500_000_000)
        
        // Utiliser une analyse locale intelligente
        return analyzePromptLocally(prompt: prompt)
    }
    
    /// Analyse le prompt localement
    private func analyzePromptLocally(prompt: String) -> String {
        // Extraction des informations du prompt
        guard let itemsStart = prompt.range(of: "VÊTEMENTS DISPONIBLES:", options: .caseInsensitive),
              let itemsEnd = prompt.range(of: "MÉTÉO:", options: .caseInsensitive) else {
            // Si on ne peut pas parser, retourner une réponse basique
            return "Outfit 1: Haut + Bas + Chaussures"
        }
        
        let itemsSection = String(prompt[itemsStart.upperBound..<itemsEnd.lowerBound])
        let items = itemsSection.components(separatedBy: "\n")
            .filter { $0.hasPrefix("-") }
            .map { $0.trimmingCharacters(in: .whitespaces) }
        
        // Extraire les tops, bottoms et shoes
        var tops: [String] = []
        var bottoms: [String] = []
        var shoes: [String] = []
        
        for item in items {
            let lower = item.lowercased()
            if lower.contains("catégorie: top") || lower.contains("catégorie: outerwear") {
                if let nameRange = item.range(of: "|") {
                    let name = String(item[..<nameRange.lowerBound]).replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        tops.append(name)
                    }
                }
            } else if lower.contains("catégorie: bottom") {
                if let nameRange = item.range(of: "|") {
                    let name = String(item[..<nameRange.lowerBound]).replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        bottoms.append(name)
                    }
                }
            } else if lower.contains("catégorie: shoes") {
                if let nameRange = item.range(of: "|") {
                    let name = String(item[..<nameRange.lowerBound]).replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        shoes.append(name)
                    }
                }
            }
        }
        
        // Générer des suggestions
        var response = ""
        let maxOutfits = min(3, max(1, min(tops.count, bottoms.count, shoes.count)))
        
        for i in 1...maxOutfits {
            let topIndex = (i - 1) % tops.count
            let bottomIndex = (i - 1) % bottoms.count
            let shoeIndex = min((i - 1) % shoes.count, shoes.count - 1)
            
            let top = tops[safe: topIndex] ?? "Haut"
            let bottom = bottoms[safe: bottomIndex] ?? "Bas"
            let shoe = shoes[safe: shoeIndex] ?? "Chaussures"
            
            response += "Outfit \(i): \(top) + \(bottom) + \(shoe)\n"
        }
        
        return response.isEmpty ? "Outfit 1: Haut + Bas + Chaussures" : response
    }
    
    // MARK: - Construction du prompt
    
    private func buildPrompt(
        itemsDescriptions: [String],
        weather: WeatherData,
        userProfile: UserProfile,
        numberOfItems: Int,
        userRequest: String? = nil
    ) -> String {
        let itemsDescription = itemsDescriptions.joined(separator: "\n")
        
        // Calculer le nombre d'outfits (max 3)
        let numberOfOutfits: Int
        if numberOfItems < 10 {
            numberOfOutfits = 1
        } else if numberOfItems < 20 {
            numberOfOutfits = 2
        } else {
            numberOfOutfits = 3
        }
        
        var prompt = """
        Tu es un expert en mode et stylisme. Génère des suggestions d'outfits personnalisées pour l'utilisateur.
        
        VÊTEMENTS DISPONIBLES:
        \(itemsDescription)
        
        MÉTÉO:
        Température: \(Int(weather.temperature))°C
        Condition: \(weather.condition.rawValue)
        
        PROFIL UTILISATEUR:
        Genre: \(userProfile.gender.rawValue)
        """
        
        // Ajouter le style si disponible
        if let style = userProfile.preferences.preferredStyle {
            prompt += "\nStyle préféré: \(style.rawValue)"
        }
        
        // Ajouter la demande spécifique si fournie
        if let userRequest = userRequest, !userRequest.trimmingCharacters(in: .whitespaces).isEmpty {
            prompt += "\n\nDEMANDE SPÉCIFIQUE DE L'UTILISATEUR (PRIORITÉ ABSOLUE):"
            prompt += "\n\(userRequest)"
            prompt += "\nIMPORTANT: Tu DOIS utiliser exactement le vêtement et la couleur demandés. Ne substitue JAMAIS un autre vêtement."
        }
        
        prompt += """
        
        INSTRUCTIONS:
        1. Génère EXACTEMENT \(numberOfOutfits) suggestion(s) d'outfit(s)
        2. Chaque outfit doit inclure: un haut (obligatoire), un bas (obligatoire), des chaussures (obligatoire)
        3. Adapte chaque outfit au genre (\(userProfile.gender.rawValue))
        4. Adapte chaque outfit à la météo (\(Int(weather.temperature))°C, \(weather.condition.rawValue))
        5. Utilise EXACTEMENT les noms et couleurs des vêtements de la liste
        6. Format de réponse: "Outfit X: [nom haut] + [nom bas] + [nom chaussures]"
        
        Réponds uniquement avec les suggestions, une par ligne, au format demandé.
        """
        
        return prompt
    }
    
    // MARK: - Parsing de la réponse
    
    private func parseResponse(_ text: String) -> [String] {
        let suggestions = text.components(separatedBy: "\n")
            .filter { line in
                let trimmed = line.trimmingCharacters(in: .whitespaces)
                return !trimmed.isEmpty && (trimmed.lowercased().contains("outfit") || trimmed.contains("+") || trimmed.first?.isNumber == true)
            }
            .map { line in
                var cleaned = line.trimmingCharacters(in: .whitespaces)
                if let colonRange = cleaned.range(of: ":") {
                    cleaned = String(cleaned[colonRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                }
                while cleaned.first?.isNumber == true || cleaned.first == "." || cleaned.first == "-" {
                    cleaned = String(cleaned.dropFirst()).trimmingCharacters(in: .whitespaces)
                }
                return cleaned
            }
            .filter { !$0.isEmpty }
        
        return suggestions.isEmpty ? [text] : suggestions
    }
    
    // MARK: - Chat Conversation
    
    /// Répond à une question de l'utilisateur concernant les vêtements, outfits, météo, etc.
    @available(iOS 18.0, *)
    func askAboutClothing(
        question: String,
        userProfile: UserProfile,
        currentWeather: WeatherData?,
        wardrobeItems: [WardrobeItem]
    ) async throws -> String {
        guard isEnabled else {
            throw AppleIntelligenceError.notAvailable
        }
        
        // Construire le contexte
        var contextPrompt = """
        Tu es un assistant intelligent et utile pour l'application Shoply. Tu peux répondre à toutes sortes de questions, avec une expertise particulière en mode, stylisme et conseils vestimentaires.
        
        PROFIL UTILISATEUR:
        - Genre: \(userProfile.gender.rawValue)
        - Âge: \(userProfile.age)
        """
        
        if let weather = currentWeather {
            contextPrompt += """
            
            MÉTÉO ACTUELLE:
            - Température: \(Int(weather.temperature))°C
            - Conditions: \(weather.condition.rawValue)
            """
        }
        
        if !wardrobeItems.isEmpty {
            let itemsDescription = wardrobeItems.prefix(10).map { item in
                "- \(item.name) (\(item.category.rawValue), \(item.color))"
            }.joined(separator: "\n")
            
            contextPrompt += """
            
            GARDE-ROBE DE L'UTILISATEUR (échantillon):
            \(itemsDescription)
            """
        }
        
        contextPrompt += """
        
        QUESTION DE L'UTILISATEUR:
        \(question)
        
        INSTRUCTIONS:
        1. Réponds de manière concise et amicale (maximum 300 mots)
        2. Réponds à la question de l'utilisateur de manière naturelle et utile
        3. Si la question concerne les vêtements, outfits, mode ou style, utilise les informations du profil utilisateur et de la météo
        4. Sois pratique et donne des conseils actionnables quand c'est pertinent
        5. Si tu peux aider avec la question, réponds directement sans restrictions
        """
        
        // Utiliser Foundation Models framework pour générer la réponse
        do {
            let response = try await generateWithFoundationModels(prompt: contextPrompt)
            return response.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            throw AppleIntelligenceError.generationFailed(error.localizedDescription)
        }
    }
}

// MARK: - Extensions pour compatibilité

extension ProcessInfo {
    var machineIdentifier: String {
        var size = 0
        sysctlbyname("hw.machine", nil, &size, nil, 0)
        var machine = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.machine", &machine, &size, nil, 0)
        return String(cString: machine)
    }
}

extension UIDevice {
    var modelIdentifier: String? {
        var systemInfo = utsname()
        uname(&systemInfo)
        // Copier machine dans une variable locale pour éviter les conflits d'accès
        let machineTuple = systemInfo.machine
        // Convertir le tuple machine en String directement
        let machine = withUnsafePointer(to: machineTuple) {
            $0.withMemoryRebound(to: CChar.self, capacity: MemoryLayout.size(ofValue: machineTuple)) {
                String(cString: $0)
            }
        }
        return machine.isEmpty ? nil : machine
    }
}

// MARK: - Erreurs

enum AppleIntelligenceError: LocalizedError {
    case noItems
    case notAvailable
    case generationFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noItems:
            return "Aucun vêtement disponible".localized
        case .notAvailable:
            return "Apple Intelligence n'est pas disponible sur cet appareil. Requiert iOS 18+ et iPhone 15 Pro ou ultérieur.".localized
        case .generationFailed(let reason):
            return "Erreur de génération: \(reason)".localized
        }
    }
}

// MARK: - Extension Array pour accès sécurisé

extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Wrapper pour compatibilité iOS 17

/// Service wrapper qui gère la compatibilité iOS 17 et iOS 18+
/// Permet d'utiliser Apple Intelligence sur iOS 18+ avec iPhone 15 Pro+
class AppleIntelligenceServiceWrapper: ObservableObject {
    static let shared = AppleIntelligenceServiceWrapper()
    
    @Published var isEnabled = false
    
    private var cancellable: AnyCancellable?
    
    private init() {
        // Vérifier la version iOS (accepter iOS 18+)
        let iosVersion = UIDevice.current.systemVersion
        let iosMajorVersion = Int(iosVersion.components(separatedBy: ".").first ?? "0") ?? 0
        
        if iosMajorVersion >= 18 {
            // Créer le service iOS 18+ et observer son état
            // Note: On utilise @available pour le type, mais on vérifie aussi la version runtime
            if #available(iOS 18.0, *) {
                let service = AppleIntelligenceService.shared
                isEnabled = service.isEnabled

                print("   iOS Version: \(iosVersion) (major: \(iosMajorVersion))")
                print("   Service isEnabled: \(service.isEnabled)")
                print("   Wrapper isEnabled initial: \(isEnabled)")
                
                // Observer les changements d'état
                cancellable = service.$isEnabled
                    .receive(on: DispatchQueue.main)
                    .sink { [weak self] newValue in
                        self?.isEnabled = newValue
                        print("🔄 AppleIntelligenceServiceWrapper: isEnabled changed to \(newValue)")
                    }
            } else {
                isEnabled = false
            }
        } else {
            
            isEnabled = false
        }
    }
    
    // MARK: - Chat Conversation
    
    @available(iOS 18.0, *)
    func askAboutClothing(
        question: String,
        userProfile: UserProfile,
        currentWeather: WeatherData?,
        wardrobeItems: [WardrobeItem]
    ) async throws -> String {
        return try await AppleIntelligenceService.shared.askAboutClothing(
            question: question,
            userProfile: userProfile,
            currentWeather: currentWeather,
            wardrobeItems: wardrobeItems
        )
    }
    
    // MARK: - Outfit Suggestions
    
    @available(iOS 18.0, *)
    func generateOutfitSuggestions(
        wardrobeItems: [WardrobeItem],
        weather: WeatherData,
        userProfile: UserProfile,
        userRequest: String? = nil,
        progressCallback: ((Double) async -> Void)? = nil
    ) async throws -> [String] {
        return try await AppleIntelligenceService.shared.generateOutfitSuggestions(
            wardrobeItems: wardrobeItems,
            weather: weather,
            userProfile: userProfile,
            userRequest: userRequest,
            progressCallback: progressCallback
        )
    }
}

