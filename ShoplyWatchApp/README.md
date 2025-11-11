# Shoply Watch App

Application Apple Watch pour Shoply - Assistant Style Intelligent

## 📱 Compatibilité

- **watchOS 10.0** et ultérieur
- Compatible avec watchOS 26 et versions futures
- Nécessite l'application iOS Shoply pour la synchronisation complète

## 🎯 Fonctionnalités

### 1. Accueil (Home)
- Affichage de la météo actuelle
- Suggestion d'outfit du jour
- Actions rapides (nouvelles suggestions, chat IA)

### 2. Suggestions d'Outfits
- Génération d'outfits personnalisés
- Filtrage par style (Décontracté, Professionnel, Sport, Soirée)
- Suggestions adaptées à la météo

### 3. Chat IA
- Interface de chat simplifiée avec Shoply IA
- Questions rapides sur le style et la mode
- Synchronisation avec l'application iOS

### 4. Garde-robe
- Consultation de votre garde-robe
- Filtrage par catégorie (Hauts, Bas, Chaussures, Accessoires)
- Synchronisation automatique avec l'app iOS

## 🔄 Synchronisation

L'application Watch utilise plusieurs méthodes de synchronisation :

1. **App Groups** : Partage de données via `group.com.william.shoply`
2. **WatchConnectivity** : Communication bidirectionnelle avec l'app iOS
3. **UserDefaults** : Stockage local des préférences

## 📦 Structure

```
ShoplyWatchApp/
├── ShoplyWatchApp.swift          # Point d'entrée de l'application
├── ContentView.swift             # Vue principale avec navigation
├── WatchHomeView.swift           # Écran d'accueil
├── WatchOutfitSuggestionsView.swift  # Suggestions d'outfits
├── WatchChatView.swift           # Interface de chat IA
├── WatchWardrobeView.swift       # Consultation de la garde-robe
├── Models/
│   └── WatchModels.swift        # Modèles de données
├── Services/
│   ├── WatchDataManager.swift   # Gestion des données et synchronisation
│   ├── WatchOutfitService.swift # Service de génération d'outfits
│   └── WatchWeatherService.swift # Service météo
└── Info.plist                    # Configuration de l'application
```

## 🛠️ Configuration

### App Groups

L'application nécessite la configuration d'un App Group partagé :
- Identifiant : `group.com.william.shoply`
- Doit être configuré dans les capabilities de l'app iOS et Watch

### WatchConnectivity

La communication avec l'app iOS utilise WatchConnectivity pour :
- Envoi de messages de chat
- Synchronisation de la garde-robe
- Mise à jour des suggestions

## 🚀 Installation

1. Ajouter la cible Watch App au projet Xcode
2. Configurer les App Groups dans les capabilities
3. Configurer WatchConnectivity
4. Compiler et installer sur l'Apple Watch

## 📝 Notes

- L'application Watch fonctionne de manière autonome mais bénéficie de la synchronisation avec l'app iOS
- Les fonctionnalités avancées nécessitent une connexion avec l'iPhone
- Les données sont mises en cache localement pour un accès rapide

## 🔮 Fonctionnalités Futures

- Complications pour l'affichage sur le cadran
- Notifications push pour les suggestions quotidiennes
- Intégration avec Siri Shortcuts
- Support des complications complexes

