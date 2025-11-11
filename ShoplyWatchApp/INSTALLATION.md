# Guide d'Installation - Shoply Watch App

## 📋 Prérequis

- Xcode 15.0 ou ultérieur
- watchOS 10.0 SDK ou ultérieur
- Apple Watch connecté (pour les tests)
- Compte développeur Apple configuré

## 🔧 Étapes d'Installation

### 1. Ajouter la Cible Watch App dans Xcode

1. Ouvrir le projet `Shoply.xcodeproj` dans Xcode
2. Aller dans **File > New > Target...**
3. Sélectionner **watchOS > App**
4. Cliquer sur **Next**
5. Configurer :
   - **Product Name**: `ShoplyWatchApp`
   - **Bundle Identifier**: `William.Shoply.watchkitapp`
   - **Language**: Swift
   - **Interface**: SwiftUI
   - **Include Notification Scene**: Optionnel
6. Cliquer sur **Finish**

### 2. Configurer les App Groups

1. Sélectionner la cible **ShoplyWatchApp** dans le projet
2. Aller dans l'onglet **Signing & Capabilities**
3. Cliquer sur **+ Capability**
4. Ajouter **App Groups**
5. Cocher `group.com.william.shoply`
6. Répéter pour la cible **Shoply** (app iOS principale)

### 3. Configurer WatchConnectivity

1. Dans la cible **ShoplyWatchApp**, aller dans **Signing & Capabilities**
2. Vérifier que **Background Modes** est activé
3. Cocher **Background fetch** et **Remote notifications**

### 4. Ajouter les Fichiers au Projet

1. Dans Xcode, cliquer droit sur le dossier **ShoplyWatchApp**
2. Sélectionner **Add Files to "Shoply"...**
3. Sélectionner tous les fichiers du dossier `ShoplyWatchApp/`
4. Vérifier que la cible **ShoplyWatchApp** est cochée
5. Cliquer sur **Add**

### 5. Configuration du Build Settings

1. Sélectionner la cible **ShoplyWatchApp**
2. Aller dans **Build Settings**
3. Configurer :
   - **Deployment Target**: watchOS 10.0
   - **Swift Language Version**: Swift 5
   - **Product Bundle Identifier**: `William.Shoply.watchkitapp`

### 6. Configuration de l'Info.plist

Vérifier que le fichier `Info.plist` contient :
- `WKApplication`: `true`
- `WKCompanionAppBundleIdentifier`: `William.Shoply`
- `WKWatchOnly`: `false`

### 7. Mettre à jour l'App iOS pour la Synchronisation

Dans l'application iOS principale, ajouter le code de synchronisation dans `DataManager.swift` :

```swift
// Synchroniser avec l'Apple Watch
func syncToWatch() {
    guard let sharedDefaults = UserDefaults(suiteName: "group.com.william.shoply") else {
        return
    }
    
    // Synchroniser la garde-robe
    if let wardrobeData = try? JSONEncoder().encode(getWardrobeItems()) {
        sharedDefaults.set(wardrobeData, forKey: "wardrobe_items")
    }
    
    // Synchroniser la météo
    // ... code de synchronisation météo
}
```

### 8. Tester l'Application

1. Connecter un Apple Watch à votre Mac
2. Sélectionner le schéma **ShoplyWatchApp** dans Xcode
3. Choisir votre Apple Watch comme destination
4. Appuyer sur **Run** (⌘R)

## ⚠️ Dépannage

### Erreur : "App Groups not configured"
- Vérifier que l'App Group est configuré dans les deux cibles (iOS et Watch)
- Vérifier que l'identifiant est exactement `group.com.william.shoply`

### Erreur : "WatchConnectivity not working"
- Vérifier que les deux applications (iOS et Watch) sont installées
- Vérifier que l'Apple Watch est connecté à l'iPhone
- Redémarrer les deux applications

### Erreur : "Cannot find module"
- Vérifier que tous les fichiers sont ajoutés à la cible Watch
- Nettoyer le build (⌘⇧K) et reconstruire

## 📱 Compatibilité

- **watchOS minimum**: 10.0
- **watchOS cible**: 10.0 et ultérieur
- **Compatibilité future**: watchOS 26 et versions ultérieures

## 🔗 Ressources

- [Documentation Apple Watch](https://developer.apple.com/watchos/)
- [WatchConnectivity Guide](https://developer.apple.com/documentation/watchconnectivity)
- [App Groups Guide](https://developer.apple.com/documentation/xcode/configuring-app-groups)

