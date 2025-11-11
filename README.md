# Shoply - Assistant Style Intelligent

Application iOS moderne pour la gestion de garde-robe et la sélection intelligente d'outfits avec IA avancée.

## 🎯 Fonctionnalités Principales

### Gestion de Garde-robe
- **Gestion complète** : Ajoutez, modifiez et organisez vos vêtements
- **Collections** : Créez des collections thématiques pour organiser vos vêtements
- **Photos** : Ajoutez des photos à vos vêtements
- **Catégories** : Organisation par catégories (hauts, bas, chaussures, accessoires)

### Sélection Intelligente d'Outfits
- **IA Avancée** : Sélection intelligente basée sur plusieurs algorithmes
- **Météo** : Suggestions adaptées à la météo actuelle
- **Styles** : Sélection par style vestimentaire ou collection
- **Calendrier** : Planification d'outfits pour vos événements

### Intelligence Artificielle
- **Shoply AI** : LLM local avec 500 000 paramètres créé par William RAUWENS OLIVER
- **Google Gemini** : Intégration pour enrichir les réponses
- **Chat Intelligent** : Interface de chat avec historique des conversations
- **Suggestions Contextuelles** : Suggestions personnalisées basées sur votre historique

### Nouvelles Fonctionnalités

#### 📊 Statistiques & Analytics
- **Statistiques de style** : Analyse de vos préférences vestimentaires
- **Fréquence de port** : Suivi de vos vêtements les plus portés
- **Impact environnemental** : Calcul de l'impact écologique
- **Coût par port** : Analyse économique de votre garde-robe

#### 🎮 Gamification
- **Niveaux de style** : Progression avec système de niveaux
- **Badges** : 11 badges à débloquer
- **Achievements** : Réalisations et défis
- **Streaks** : Suivi de vos jours consécutifs

#### ✈️ Mode Voyage
- **Planification de voyages** : Créez des plans de voyage avec dates
- **Checklist** : Liste de vérification pour vos voyages
- **Conseils Gemini** : Suggestions d'outfits basées sur la destination
- **Outfits planifiés** : Organisation d'outfits par jour de voyage

#### 🛍️ Shopping & Comparaison
- **Wishlist** : Liste de souhaits pour vos vêtements désirés
- **Comparateur de prix** : Comparez les prix entre différents magasins
- **Scanner de code-barres** : Recherche de produits en ligne
- **Recherche multi-magasins** : Intégration avec plusieurs boutiques en ligne

#### 💼 Mode Professionnel
- **Suggestions professionnelles** : Outfits adaptés aux occasions professionnelles
- **Entretiens d'embauche** : Recommandations pour les entretiens
- **Présentations** : Suggestions pour les présentations importantes
- **Conseils Gemini** : Recommandations personnalisées par occasion

#### 📅 Événements Calendrier
- **Intégration calendrier** : Synchronisation avec votre calendrier iOS
- **Suggestions d'événements** : Outfits adaptés à vos événements
- **Analyse automatique** : Détection du type d'événement
- **Recommandations Gemini** : Suggestions basées sur l'événement

#### 📈 Tendances Mode
- **Analyse de tendances** : Tendances basées sur votre localisation et âge
- **Recommandations Gemini** : Analyse des tendances actuelles
- **Suggestions personnalisées** : Adaptées à votre profil

#### 📚 Lookbooks
- **Création de lookbooks** : Créez des lookbooks PDF de vos meilleurs outfits
- **Génération Gemini** : Descriptions générées par IA
- **Export PDF** : Exportez vos lookbooks en PDF
- **Thèmes** : Plusieurs thèmes de présentation

#### 🤝 Partage Social
- **Export JSON** : Exportez vos outfits portés
- **Import JSON** : Importez des outfits partagés
- **Outfits partagés** : Gestion de vos outfits partagés
- **Outfits reçus** : Gestion des outfits importés

### Autres Fonctionnalités
- **Historique** : Consultez tous vos outfits précédents
- **Favoris** : Marquez vos outfits préférés
- **Calendrier d'outfits** : Planifiez vos tenues à l'avance
- **Profil utilisateur** : Gestion complète du profil avec photo
- **Multilingue** : Support de 10 langues
- **Thèmes** : Mode sombre et clair avec design minimaliste noir et blanc

## 🛠️ Technologies

### Framework & Langages
- **SwiftUI** : Interface utilisateur moderne et déclarative
- **Swift** : Langage de programmation principal
- **Combine** : Programmation réactive

### Persistance & Données
- **UserDefaults** : Stockage local des préférences
- **Codable** : Sérialisation JSON
- **Core Data** : Gestion de données complexes (si nécessaire)

### Intelligence Artificielle
- **Shoply AI** : LLM local avec 500 000 paramètres
  - Architecture hybride (LSTM + NLP + Knowledge Base)
  - Optimisation avec Accelerate Framework
  - Recherche web intégrée
  - Support multilingue
- **Google Gemini API** : Enrichissement des réponses IA
- **Apple Intelligence** : Support natif iOS

### Services Externes
- **Weather API** : Données météorologiques
- **Google Custom Search** : Recherche web pour l'IA
- **EventKit** : Intégration calendrier iOS
- **PhotosPicker** : Sélection de photos

### Design System
- **DesignSystem** : Système de design centralisé
  - Palette noir et blanc minimaliste
  - Typographie cohérente
  - Espacements standardisés
  - Composants réutilisables

## 📱 Structure du Projet

```
Shoply/
├── Screens/              # Écrans de l'application
│   ├── HomeScreen.swift
│   ├── ChatAIScreen.swift
│   ├── ProfileScreen.swift
│   ├── SmartOutfitSelectionScreen.swift
│   ├── CollectionsScreen.swift
│   ├── WishlistScreen.swift
│   ├── TravelModeScreen.swift
│   ├── GamificationScreen.swift
│   ├── BarcodeScannerScreen.swift
│   ├── PriceComparisonScreen.swift
│   ├── ProfessionalModeScreen.swift
│   ├── LookbooksScreen.swift
│   ├── TrendAnalysisScreen.swift
│   ├── CalendarEventsScreen.swift
│   ├── SocialShareScreen.swift
│   └── StatisticsScreen.swift
│
├── Services/             # Services métier
│   ├── ShoplyAIAdvancedLLM.swift      # LLM principal
│   ├── ShoplyAITextGenerator.swift    # Générateur de texte
│   ├── GeminiService.swift            # Service Gemini
│   ├── OutfitService.swift            # Service outfits
│   ├── WardrobeService.swift          # Service garde-robe
│   ├── WeatherService.swift           # Service météo
│   ├── GamificationService.swift     # Service gamification
│   ├── TravelModeService.swift        # Service voyage
│   ├── WishlistService.swift          # Service wishlist
│   ├── ProductSearchService.swift     # Service recherche produits
│   ├── OutfitShareService.swift       # Service partage
│   └── ...
│
├── Models/              # Modèles de données
│   ├── UserProfile.swift
│   ├── WardrobeItem.swift
│   ├── Outfit.swift
│   ├── ChatModels.swift
│   ├── Gamification.swift
│   ├── TravelMode.swift
│   ├── WishlistItem.swift
│   ├── WardrobeCollection.swift
│   └── ...
│
├── Views/               # Composants UI réutilisables
│   ├── DesignSystem.swift            # Système de design
│   ├── ImageCropView.swift           # Vue de recadrage
│   ├── DesignHelpers.swift          # Helpers UI
│   └── ...
│
├── Utils/               # Utilitaires
│   ├── Localization.swift            # Localisation
│   ├── EmailValidation.swift         # Validation email
│   └── ...
│
└── Core/                # Données et sécurité
    ├── Data/             # Gestion des données
    └── Security/         # Sécurité
```

## 🚀 Installation

### Prérequis
- Xcode 15.0 ou supérieur
- iOS 16.0 ou supérieur
- Swift 5.9 ou supérieur

### Configuration

1. **Cloner le dépôt**
   ```bash
   git clone https://github.com/william-rauwens-oliver/Shoply.git
   cd Shoply
   ```

2. **Ouvrir le projet**
   ```bash
   open Shoply.xcodeproj
   ```

3. **Configurer les capabilities**
   - CloudKit (si nécessaire)
   - Sign in with Apple (si nécessaire)
   - Calendrier (pour les événements)
   - Photos (pour les photos de profil)

4. **Configurer les clés API**
   - Google Gemini API : Ajoutez votre clé dans les paramètres de l'application
   - Google Custom Search API : Configurée dans `WebSearchService.swift`

5. **Compiler et exécuter**
   - Sélectionnez votre simulateur ou appareil
   - Appuyez sur `Cmd + R` pour compiler et exécuter

## 🎨 Design System

Le projet utilise un design system minimaliste noir et blanc :

- **Couleurs** : Palette strictement noir et blanc
- **Typographie** : Système de typographie cohérent
- **Espacements** : Espacements standardisés (xs, sm, md, lg, xl, xxl)
- **Composants** : Cartes, boutons, en-têtes réutilisables

## 🤖 Intelligence Artificielle

### Shoply AI
- **LLM Local** : 500 000 paramètres
- **Créateur** : William RAUWENS OLIVER
- **Architecture** : Hybride (LSTM + NLP + Knowledge Base)
- **Optimisation** : Accelerate Framework pour performance CPU/RAM
- **Recherche Web** : Intégration Google Custom Search
- **Multilingue** : Support de 10 langues

### Google Gemini
- **Enrichissement** : Enrichit les réponses de Shoply AI
- **Suggestions** : Recommandations pour outfits, voyages, tendances
- **Analyse** : Analyse de tendances et événements

## 📝 Fonctionnalités Détaillées
## 📚 Documentation
- Architecture: `docs/architecture.md`
- Éco‑conception: `docs/ecoconception.md`
- Sécurité: `docs/securite.md`
- RGPD: `docs/rgpd.md`
- Déploiement: `docs/deploiement.md`
- Plan de tests: `docs/plan_de_tests.md`
- Diagrammes UML: `docs/uml.md`


### Collections
Organisez vos vêtements en collections thématiques avec icônes et couleurs personnalisables.

### Wishlist
Créez une liste de souhaits pour vos vêtements désirés avec prix, priorité et liens vers les boutiques.

### Mode Voyage
Planifiez vos voyages avec checklist, conseils Gemini et organisation d'outfits par jour.

### Gamification
Système de niveaux, badges et achievements pour rendre l'utilisation de l'app ludique.

### Scanner de Code-barres
Scannez des codes-barres pour rechercher des produits dans plusieurs magasins en ligne.

### Comparateur de Prix
Comparez les prix d'un même produit entre différents magasins pour trouver le meilleur prix.

### Mode Professionnel
Obtenez des suggestions d'outfits adaptées aux occasions professionnelles (entretiens, présentations, etc.).

### Lookbooks
Créez des lookbooks PDF de vos meilleurs outfits avec descriptions générées par Gemini.

### Tendances Mode
Découvrez les tendances d'outfits basées sur votre localisation et votre âge.

### Événements Calendrier
Synchronisez avec votre calendrier iOS pour obtenir des suggestions d'outfits adaptées à vos événements.

### Partage Social
Exportez et importez vos outfits en JSON pour les partager avec d'autres utilisateurs.

## 👤 Créateur

**William RAUWENS OLIVER**
- Développeur et créateur de Shoply AI
- Créateur de l'application Shoply

## 📄 Licence

Propriétaire - Tous droits réservés

## 🔄 Statut du Projet

Le projet est actuellement en développement actif. Les fonctionnalités existantes sont stables et prêtes à être améliorées. Aucune nouvelle fonctionnalité majeure n'est prévue pour le moment - l'objectif est d'améliorer et d'optimiser les fonctionnalités existantes.

## 🤝 Contribution

Ce projet est privé et ne accepte pas de contributions externes pour le moment.

## 📞 Contact

Pour toute question ou suggestion, contactez le créateur via GitHub.

---

**Shoply** - Votre assistant style intelligent pour iOS
