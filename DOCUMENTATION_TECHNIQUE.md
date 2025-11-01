# Documentation Technique - Shoply

## 📐 Architecture du Projet

### Vue d'ensemble

L'application Shoply suit une **architecture multicouche** conforme aux standards de l'industrie et aux exigences de la certification "Concepteur Développeur d'Applications".

```
┌─────────────────────────────────────────────────────────┐
│                    COUCHE PRÉSENTATION                   │
│  (UI Layer - SwiftUI Views, Screens, Components)       │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                     COUCHE MÉTIER                        │
│  (BLL - Business Logic Layer - Services, ViewModels)      │
└────────────────────┬────────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────────┐
│                   COUCHE DONNÉES                         │
│  (DAL - Data Access Layer - Core Data, DataManager)     │
└─────────────────────────────────────────────────────────┘
```

### Détail des Couches

#### 1. Couche Présentation (UI)

**Responsabilité** : Affichage des données et interaction utilisateur

**Composants** :
- `Screens/` : Écrans principaux de l'application
  - `HomeScreen.swift` : Écran d'accueil
  - `MoodSelectionScreen.swift` : Sélection de l'humeur
  - `OutfitSelectionScreen.swift` : Liste des outfits
  - `OutfitDetailScreen.swift` : Détails d'un outfit
- `Views/` : Composants réutilisables
  - `DesignHelpers.swift` : Helpers de design adaptatif
  - `Accessibility/AccessibilityHelpers.swift` : Support accessibilité
  - `RGDP/PrivacyConsentView.swift` : Vue de consentement RGPD

**Technologies** :
- SwiftUI pour l'interface
- Combine pour la réactivité
- NavigationStack pour la navigation

#### 2. Couche Métier (BLL)

**Responsabilité** : Logique métier, règles de gestion, validation

**Composants** :
- `Services/OutfitService.swift` : Service métier pour les outfits
  - Filtrage par humeur et météo
  - Gestion des favoris
  - Recherche
  - Calcul des statistiques

**Principes** :
- Séparation des responsabilités
- Validation des données
- Gestion des erreurs
- Tests unitaires couvrant la logique métier

#### 3. Couche Données (DAL)

**Responsabilité** : Persistance et accès aux données

**Composants** :
- `Core/Data/DataManager.swift` : Gestionnaire centralisé des données
  - Gestion Core Data
  - CRUD operations
  - Export/Import RGPD
- `Core/Data/ShoplyDataModel.xcdatamodeld` : Modèle de données Core Data

**Technologies** :
- Core Data pour la persistance relationnelle
- UserDefaults pour les préférences simples
- Sérialisation JSON pour l'export RGPD

## 🔒 Sécurité

### Conformité RGPD

L'application respecte intégralement le Règlement Général sur la Protection des Données :

1. **Consentement explicite** (`RGDPManager`)
   - Affichage obligatoire au premier lancement
   - Acceptation/Refus explicite
   - Possibilité de révocation à tout moment

2. **Minimisation des données**
   - Collecte uniquement des données nécessaires
   - Pas de collecte de données personnelles identifiantes
   - Stockage local uniquement

3. **Droits de l'utilisateur**
   - Droit d'accès : Export des données
   - Droit à la portabilité : Export JSON
   - Droit à l'oubli : Suppression complète
   - Droit de rectification : Modifications possibles

4. **Sécurité technique**
   - Chiffrement des données sensibles
   - Pas de transmission à des serveurs externes
   - Validation des entrées utilisateur

### Recommandations ANSSI

- Validation stricte des entrées
- Gestion sécurisée des erreurs (pas d'exposition d'informations sensibles)
- Mise à jour régulière des dépendances
- Utilisation de technologies éprouvées

## ♿ Accessibilité (RGAA)

### Conformité WCAG 2.1 Niveau AA

1. **Support VoiceOver**
   - Labels d'accessibilité pour tous les éléments interactifs
   - Hints descriptifs pour les actions
   - Structure logique de navigation

2. **Contraste des couleurs**
   - Ratio minimum 4.5:1 pour le texte normal
   - Ratio minimum 3:1 pour le texte large
   - Alternatives pour les informations transmises uniquement par la couleur

3. **Tailles et espacements**
   - Taille de police minimum 16pt
   - Zones tactiles minimum 44x44pt
   - Espacement suffisant entre les éléments

4. **Navigation**
   - Navigation au clavier complète
   - Ordre de focus logique
   - Focus visible

## 🧪 Tests

### Stratégie de Tests

#### Tests Unitaires
- **Localisation** : `Shoply_appTests/`
- **Couverture** :
  - Logique métier (OutfitService)
  - Gestion RGPD (RGDPManager)
  - Validation des données
  - Calculs et transformations

#### Tests d'Intégration
- Interaction entre les couches
- Persistance des données
- Flux complets utilisateur

#### Tests UI
- **Localisation** : `Shoply_appUITests/`
- **Couverture** :
  - Navigation entre écrans
  - Interactions utilisateur
  - Accessibilité
  - Affichage correct des données

### Exécution des Tests

```bash
# Tous les tests
xcodebuild test -scheme Shoply -destination 'platform=iOS Simulator,name=iPhone 15'

# Tests unitaires uniquement
xcodebuild test -scheme Shoply -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:Shoply_appTests

# Tests UI uniquement
xcodebuild test -scheme Shoply -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:Shoply_appUITests
```

## 📊 Persistance des Données

### Core Data

**Modèle** : `ShoplyDataModel.xcdatamodeld`

**Entités** :
- `FavoriteOutfit` : Favoris de l'utilisateur
  - `id` : UUID de l'outfit
  - `createdAt` : Date de création
  - `isSynced` : Statut de synchronisation (pour futures extensions)

### UserDefaults

**Utilisation** : Préférences simples
- Dernière humeur sélectionnée
- Dernière météo sélectionnée
- Consentement RGPD

## 🚀 Déploiement

### Configuration Build

1. **Development** :
   - Configuration : Debug
   - Code signing : Auto
   - Optimisations : Désactivées

2. **Production** :
   - Configuration : Release
   - Code signing : Distribution certificate
   - Optimisations : Activées

### Processus de Déploiement

1. **Versioning** : Gestion via Git tags
2. **Build** : Archive Xcode
3. **Validation** : App Store Connect
4. **Distribution** : TestFlight ou App Store

### CI/CD

Workflow GitHub Actions configuré :
- Tests automatiques à chaque push
- Build automatique
- Upload optionnel vers TestFlight

## 📈 Métriques et Performance

### Objectifs de Performance

- Temps de lancement : < 2 secondes
- Fluidité : 60 FPS
- Consommation mémoire : < 50 MB
- Taille de l'application : < 20 MB

### Monitoring

- Instruments pour le profiling
- Crashlytics pour les erreurs (si intégré)
- Analytics utilisateur (si intégré, avec consentement)

## 🔄 Évolutivité

### Points d'Extension

1. **Synchronisation Cloud** :
   - Extension Core Data avec CloudKit
   - Synchronisation des favoris entre appareils

2. **Personnalisation** :
   - Création d'outfits personnalisés
   - Upload de photos

3. **Social** :
   - Partage d'outfits
   - Recommandations communautaires

4. **IA** :
   - Suggestions intelligentes basées sur l'historique
   - Analyse de tendances

## 📚 Bibliothèques et Dépendances

### Frameworks iOS Natifs

- **SwiftUI** : Interface utilisateur
- **Combine** : Programmation réactive
- **Core Data** : Persistance
- **Foundation** : Utilitaires de base

### Aucune dépendance externe

L'application n'utilise que des frameworks Apple natifs pour :
- Réduire la taille
- Améliorer la sécurité
- Faciliter la maintenance
- Éviter les problèmes de compatibilité

---

**Version** : 1.0.0  
**Dernière mise à jour** : 01/11/2025  
**Auteur** : William

