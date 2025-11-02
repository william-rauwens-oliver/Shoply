# Shoply Android - Projet Android avec Swift SDK

Ce dossier contient le projet Android pour Shoply, utilisant le Swift SDK pour Android.

## 📁 Structure du Projet

```
ShoplyAndroid/
├── app/                      # Application Android principale
│   ├── src/
│   │   ├── main/
│   │   │   ├── java/        # Code Java/Kotlin (UI Android)
│   │   │   ├── jniLibs/     # Bibliothèques Swift compilées (.so)
│   │   │   └── res/         # Ressources Android (layouts, drawables, etc.)
│   │   └── test/            # Tests Android
│   ├── build.gradle          # Configuration Gradle pour l'app
│   └── proguard-rules.pro    # Règles ProGuard
├── swift/                    # Code Swift partagé (logique métier)
│   ├── Sources/
│   │   ├── Models/          # Modèles de données
│   │   ├── Services/        # Services métier
│   │   └── Core/            # Code core (DataManager, etc.)
│   └── Package.swift        # Dépendances Swift
├── scripts/                 # Scripts d'automatisation
│   ├── setup-android-project.sh
│   ├── build-swift-libs.sh
│   └── build-android-app.sh
└── build/                   # Dossiers de build
    ├── swift/               # Bibliothèques Swift compilées
    └── android/             # APK/AAB générés
```

## 🎯 Architecture

L'architecture sépare la logique métier (Swift) de l'interface utilisateur (Android) :

```
┌─────────────────────────────────────┐
│   UI Android (Kotlin/Java)          │
│   - Jetpack Compose ou XML          │
│   - Activities, Fragments             │
└───────────────┬─────────────────────┘
                │ JNI
┌───────────────▼─────────────────────┐
│   Logique Métier Swift               │
│   - Models, Services                 │
│   - Business Logic                  │
│   - Core Data Access                │
└─────────────────────────────────────┘
```

## 🚀 Quick Start

### Prérequis

1. Avoir suivi le guide `SETUP_ANDROID_SWIFT.md`
2. Android Studio installé
3. Émulateur Android configuré

### Lancer sur un Émulateur/VM

📖 **Guide Complet** : Voir `GUIDE_LANCER_SUR_EMULATEUR.md`

**Méthode Rapide** :
1. Ouvrir le projet dans Android Studio
2. Tools → Device Manager → Create Device → Pixel 6 → API 33
3. Lancer l'émulateur (bouton Play ▶️)
4. Dans Android Studio, cliquer Run ▶️

Ou via ligne de commande :
```bash
./scripts/launch-on-emulator.sh
```

### Étapes

1. **Initialiser le projet Android** :
```bash
cd ShoplyAndroid
./scripts/setup-android-project.sh
```

2. **Compiler les bibliothèques Swift** :
```bash
./scripts/build-swift-libs.sh
```

3. **Compiler l'app Android** :
```bash
./scripts/build-android-app.sh
```

4. **Lancer sur l'émulateur** :
```bash
adb install build/android/app-debug.apk
adb shell am start -n com.shoply.app/.MainActivity
```

## 🔄 Processus de Développement

1. **Modifier le code Swift** dans `swift/Sources/`
2. **Recompiler les bibliothèques** avec `build-swift-libs.sh`
3. **Modifier l'UI Android** dans `app/src/main/java/`
4. **Compiler et tester** avec Android Studio ou `build-android-app.sh`

## 📝 Notes Importantes

- **SwiftUI n'existe pas sur Android** : Vous devez créer l'UI avec Jetpack Compose ou XML
- **Seule la logique métier** est partagée entre iOS et Android
- **L'authentification** : Utilisez Google Sign In au lieu d'Apple Sign In
- **Le stockage** : Utilisez Android SharedPreferences au lieu de UserDefaults

## 🛠️ Commandes Utiles

```bash
# Compiler Swift pour ARM64
swift build --swift-sdk aarch64-unknown-linux-android28 --static-swift-stdlib

# Compiler Swift pour x86_64 (émulateur)
swift build --swift-sdk x86_64-unknown-linux-android28 --static-swift-stdlib

# Voir les appareils connectés
adb devices

# Installer l'APK
adb install app-debug.apk

# Voir les logs
adb logcat | grep Shoply

# Déboguer avec Android Studio
# Ouvrir ShoplyAndroid dans Android Studio
# Run → Run 'app'
```

## 📚 Documentation

- **Guide de Setup** : Voir `../SETUP_ANDROID_SWIFT.md`
- **Exemples Swift Android** : https://github.com/apple/swift-android-examples
- **Swift-Java Interop** : Documentation sur swift-java pour l'interopérabilité

