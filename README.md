# Shoply - Application de Sélection d'Outfits

## 📋 Description du Projet

Shoply est une application iOS permettant aux utilisateurs de choisir leur tenue du jour en fonction de leur humeur et des conditions météorologiques. L'application respecte les standards de qualité professionnels et est conforme au RGPD et aux recommandations d'accessibilité (RGAA).

## 🏗️ Architecture

L'application suit une **architecture multicouche** conforme aux bonnes pratiques :

### 1. Couche Présentation (UI)
- **Localisation** : `Shoply/Screens/`, `Shoply/Views/`
- **Responsabilité** : Interface utilisateur, navigation, affichage des données
- **Technologies** : SwiftUI, Combine

### 2. Couche Métier (BLL)
- **Localisation** : `Shoply/Services/`
- **Responsabilité** : Logique métier, règles de gestion, validation des données
- **Classes principales** :
  - `OutfitService` : Gestion de la logique des outfits
  - `RGDPManager` : Gestion du consentement et de la conformité RGPD

### 3. Couche Données (DAL)
- **Localisation** : `Shoply/Core/Data/`
- **Responsabilité** : Persistance des données, accès aux données
- **Technologies** : Core Data, UserDefaults
- **Classes principales** :
  - `DataManager` : Gestionnaire de données centralisé

### 4. Couche Modèles
- **Localisation** : `Shoply/Models/`
- **Responsabilité** : Structures de données, enums, modèles métier

## 🔒 Sécurité et Conformité

### RGPD
- ✅ Consentement explicite de l'utilisateur avant collecte de données
- ✅ Politique de confidentialité complète
- ✅ Droit à l'export des données
- ✅ Droit à la suppression des données
- ✅ Droit à la révocation du consentement
- ✅ Stockage local uniquement (pas de transmission à des serveurs externes)

### Recommandations ANSSI
- ✅ Chiffrement des données sensibles
- ✅ Validation des entrées utilisateur
- ✅ Gestion sécurisée des erreurs

## ♿ Accessibilité (RGAA)

L'application est conforme au Référentiel Général d'Amélioration de l'Accessibilité :

- ✅ **VoiceOver** : Labels d'accessibilité complets pour tous les éléments
- ✅ **Contraste** : Respect du ratio 4.5:1 minimum (WCAG AA)
- ✅ **Taille de police** : Minimum 16pt pour une lecture confortable
- ✅ **Navigation au clavier** : Support complet de la navigation
- ✅ **Alternatives textuelles** : Descriptions pour toutes les images

## 📱 Fonctionnalités

### Fonctionnalités Principales
1. **Sélection par humeur** : Choisissez votre humeur du jour
2. **Sélection par météo** : Adaptez votre tenue à la météo
3. **Favoris** : Sauvegardez vos outfits préférés
4. **Recherche** : Recherchez parmi tous les outfits disponibles
5. **Statistiques** : Consultez vos statistiques d'utilisation

### Fonctionnalités Techniques
- Architecture multicouche
- Persistance avec Core Data
- Gestion du consentement RGPD
- Accessibilité complète
- Tests unitaires et UI

## 🧪 Tests

### Tests Unitaires
- **Localisation** : `Shoply/Shoply_appTests/`
- **Couverture** :
  - Logique métier (`OutfitServiceTests`)
  - Gestion RGPD (`RGDPManagerTests`)
  - Validation des données

### Tests UI
- **Localisation** : `Shoply/Shoply_appUITests/`
- **Couverture** :
  - Navigation
  - Accessibilité
  - Flux utilisateur

### Exécution des Tests
```bash
# Tests unitaires
xcodebuild test -scheme Shoply -destination 'platform=iOS Simulator,name=iPhone 15'

# Tests UI
xcodebuild test -scheme Shoply -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:Shoply_appUITests
```

## 📦 Installation

### Prérequis
- Xcode 15.0 ou supérieur
- iOS 18.0 ou supérieur
- Swift 5.9 ou supérieur

### Configuration
1. Cloner le repository
2. Ouvrir `Shoply.xcodeproj` dans Xcode
3. Configurer le développement team dans les paramètres du projet
4. Exécuter l'application (⌘R)

## 🚀 Déploiement

### Configuration pour la Production
1. **App Store Connect** :
   - Créer une nouvelle app dans App Store Connect
   - Configurer les métadonnées (description, captures d'écran)
   - Ajouter la politique de confidentialité

2. **Certificats et Profils** :
   - Générer les certificats de distribution
   - Créer les profils de provisionnement

3. **Build de Production** :
   ```bash
   xcodebuild archive -scheme Shoply -configuration Release
   ```

4. **Upload vers App Store** :
   - Utiliser Xcode Organizer (⌘⇧⌥O)
   - Ou utiliser `altool` / `xcrun altool`

### CI/CD (GitHub Actions)
Un workflow GitHub Actions peut être configuré pour :
- Exécution automatique des tests
- Build automatique à chaque push
- Upload automatique vers TestFlight

## 📚 Documentation Technique

### Architecture Détaillée

```
Shoply/
├── Core/                    # Cœur de l'application
│   ├── Data/                # Couche d'accès aux données
│   │   ├── DataManager.swift
│   │   └── ShoplyDataModel.xcdatamodeld
│   └── Security/            # Sécurité et RGPD
│       └── RGDPManager.swift
├── Models/                  # Modèles de données
│   └── Outfit.swift
├── Services/                # Services métier
│   └── OutfitService.swift
├── Screens/                 # Écrans (Présentation)
│   ├── HomeScreen.swift
│   ├── MoodSelectionScreen.swift
│   ├── OutfitSelectionScreen.swift
│   └── OutfitDetailScreen.swift
└── Views/                   # Composants réutilisables
    ├── DesignHelpers.swift
    ├── Accessibility/
    │   └── AccessibilityHelpers.swift
    └── RGDP/
        └── PrivacyConsentView.swift
```

## 👥 Équipe et Contribution

**Développeur** : William  
**Date de création** : 01/11/2025  
**Version** : 1.0.0

## 📄 Licence

Propriétaire - Tous droits réservés

## 🔗 Ressources

- [Documentation SwiftUI](https://developer.apple.com/documentation/swiftui)
- [RGPD - CNIL](https://www.cnil.fr/fr/rgpd-de-quoi-parle-t-on)
- [RGAA - Accessibilité](https://www.numerique.gouv.fr/publications/rgaa-accessibilite/)
- [Recommandations ANSSI](https://www.ssi.gouv.fr/)

## 📞 Contact

Pour toute question ou problème, contactez l'équipe de développement via les paramètres de l'application.

---

**Note** : Cette application a été développée dans le cadre de la certification "Concepteur Développeur d'Applications" et respecte toutes les exigences de qualité et de sécurité requises.

