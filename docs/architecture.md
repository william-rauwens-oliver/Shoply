# Architecture de Shoply

## Vue d’ensemble
Shoply suit une architecture en couches claire, orientée MVVM avec SwiftUI.

- Couche Présentation (UI): `Screens/`, `Views/`
- Couche Métier (Services): `Services/`
- Couche Données (Persistance): `Core/Data/`, `Services/DatabaseService.swift`
- Modèles: `Models/`
- Utilitaires et Design System: `Utils/`, `Views/DesignSystem.swift`

```
UI (SwiftUI Views)
   ↓  (Combine @Published / @StateObject)
Services (Business logic, orchestration)
   ↓  (Data mappers / DTO)
Persistance (SQLite + Core Data + CloudKit)
```

## Principes
- Séparation des responsabilités
- Données immuables côté modèles
- Services Singletons observables (ObservableObject)
- Thread-safe via MainActor quand nécessaire

## Couche Présentation
- SwiftUI, `NavigationStack`, `Toolbar`, `fullScreenCover`
- Composants réutilisables (cards, boutons, filtres)
- Accessibilité (RGAA): `Views/Accessibility/AccessibilityHelpers.swift`

## Couche Métier (Services clés)
- `WardrobeService`: gestion des vêtements
- `OutfitService`: génération/évaluation des outfits
- `GamificationService`: badges/niveaux/streaks
- `TravelModeService`: plans de voyage
- `WishlistService`: wishlist et pièces désirées
- `WeatherService`: localisation + météo
- IA:
  - `ShoplyAIAdvancedLLM`: LLM local optimisé CPU
  - `GeminiService`: enrichissement (backend, UI masquée)

## Persistance
- SQL (SQLite) via `SQLDatabaseService` (CRUD, jointures)
- NoSQL (CloudKit) via `NoSQLDatabaseService` (documents)
- Core Data (optionnel, DataManager)
- UserDefaults pour préférences rapides

## Sécurité
- Auth Apple (`AppleSignInService`)
- RGPD (`RGDPManager`)
- Chiffrement iCloud via CloudKit
- Nettoyage/suppression des données depuis `SettingsScreen`

## Internationalisation
- `Utils/Localization.swift` (11 langues incluant DE et IT)
- `AppSettingsManager` gère le choix de langue

## Tests et CI/CD
- Tests Unit/UI (`ShoplyTests`, `Shoply_appUITests`)
- GitHub Actions: tests + build

## Décisions architecturales (extraits)
- MVVM avec SwiftUI pour la vitesse et la lisibilité
- SQLite pour la portabilité offline, CloudKit pour sync
- IA hybride: local (privacy/perf) + backend (qualité)


