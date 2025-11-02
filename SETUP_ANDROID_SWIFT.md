# Guide Pratique : Configuration Shoply pour Android avec Swift SDK

Ce guide vous permet de configurer Shoply pour fonctionner sur Android en utilisant le Swift SDK pour Android, suivant le [guide officiel](https://www.swift.org/documentation/articles/swift-sdk-for-android-getting-started.html).

## 📋 Prérequis

- macOS ou Linux (recommandé : macOS)
- Terminal avec accès aux commandes
- Environ 5-10 Go d'espace disque libre

## 🚀 Étape 1 : Installer Swiftly (Gestionnaire de Toolchains Swift)

Swiftly est le moyen recommandé pour gérer les versions de Swift.

```bash
# Installer swiftly sur macOS
curl -L https://swift.org/getting-started/swiftly/install.sh | bash

# Recharger le shell
source ~/.swiftly/env.sh

# Vérifier l'installation
swiftly --version
```

## 🔧 Étape 2 : Installer le Host Toolchain Swift

Vous devez installer une version spécifique de Swift qui correspond au SDK Android.

```bash
# Installer la version snapshot du 16 octobre 2025 (exemple)
swiftly install main-snapshot-2025-10-16

# Définir comme version par défaut
swiftly use main-snapshot-2025-10-16

# Vérifier
swiftly run swift --version
```

**Note** : Utilisez la version snapshot la plus récente disponible avec support Android. Consultez https://swift.org/download/ pour les dernières versions.

## 📦 Étape 3 : Installer le Swift SDK pour Android

Le SDK Android doit correspondre à la version du toolchain Swift installé.

```bash
# Installer le Swift SDK pour Android
swiftly run swift sdk install https://download.swift.org/development/android-sdk/swift-DEVELOPMENT-SNAPSHOT-2025-10-16-a/swift-DEVELOPMENT-SNAPSHOT-2025-10-16-a_android-0.1.artifactbundle.tar.gz --checksum 451844c232cf1fa02c52431084ed3dc27a42d103635c6fa71bae8d66adba2500

# Vérifier que le SDK est installé
swiftly run swift sdk list
# Vous devriez voir : swift-DEVELOPMENT-SNAPSHOT-2025-10-16-a-android-0.1.artifactbundle
```

**Important** : Vérifiez le guide officiel pour obtenir l'URL et le checksum de la version la plus récente du SDK.

## 🛠️ Étape 4 : Installer l'Android NDK

L'Android NDK (version 27d) est requis pour la compilation croisée.

```bash
# Créer un répertoire pour le NDK
mkdir -p ~/android-ndk
cd ~/android-ndk

# Télécharger le NDK (pour macOS)
curl -fSLO https://dl.google.com/android/repository/android-ndk-r27d-Darwin.zip

# Pour Linux, utilisez :
# curl -fSLO https://dl.google.com/android/repository/android-ndk-r27d-linux.zip

# Extraire l'archive
unzip -q android-ndk-r27d-*.zip

# Définir la variable d'environnement
export ANDROID_NDK_HOME=$PWD/android-ndk-r27d

# Ajouter à votre ~/.zshrc ou ~/.bash_profile pour la rendre permanente
echo 'export ANDROID_NDK_HOME=~/android-ndk/android-ndk-r27d' >> ~/.zshrc
source ~/.zshrc
```

## 🔗 Étape 5 : Configurer le SDK Android avec le NDK

Lier le NDK au Swift SDK pour Android.

```bash
# Aller dans le répertoire des SDKs Swift
cd ~/Library/org.swift.swiftpm || cd ~/.swiftpm

# Exécuter le script de configuration
./swift-sdks/swift-DEVELOPMENT-SNAPSHOT-2025-10-16-a-android-0.1.artifactbundle/swift-android/scripts/setup-android-sdk.sh

# Si le NDK est dans un autre emplacement, définissez ANDROIDNDKHOME :
# export ANDROIDNDKHOME=/chemin/vers/votre/ndk
# ./setup-android-sdk.sh
```

Vous devriez voir : `setup-android-sdk.sh: success: ndk-sysroot linked...`

## 📱 Étape 6 : Installer Android Studio et Configurer l'Émulateur

1. **Télécharger Android Studio** : https://developer.android.com/studio
2. **Installer Android Studio** avec tous les composants par défaut
3. **Configurer un émulateur Android** :
   - Ouvrir Android Studio
   - Tools → Device Manager → Create Device
   - Choisir un appareil (ex: Pixel 6)
   - Télécharger une image système (API 28 ou supérieur recommandé)
   - Créer l'émulateur

4. **Vérifier que ADB fonctionne** :
```bash
# Vérifier que adb est dans le PATH
adb devices

# Si adb n'est pas trouvé, ajoutez-le :
export PATH=$PATH:$HOME/Library/Android/sdk/platform-tools
```

## ✅ Étape 7 : Tester avec Hello World

Avant de compiler Shoply, testons que tout fonctionne avec un exemple simple.

```bash
# Créer un dossier de test
cd /tmp
mkdir swift-android-test
cd swift-android-test

# Créer un package Swift
swiftly run swift package init --type executable

# Compiler pour macOS (test local)
swiftly run swift build
.build/debug/swift-android-test
# Devrait afficher : Hello, world!

# Compiler pour Android (ARM64)
swiftly run swift build --swift-sdk aarch64-unknown-linux-android28 --static-swift-stdlib

# Compiler pour Android (x86_64)
swiftly run swift build --swift-sdk x86_64-unknown-linux-android28 --static-swift-stdlib
```

## 🔨 Étape 8 : Compiler Shoply pour Android

Maintenant, compilons votre projet Shoply pour Android.

```bash
# Retourner dans le dossier du projet Shoply
cd "/Users/williamrauwensoliver/Projet SWIFT/Shoply"

# Créer un dossier pour les builds Android
mkdir -p ShoplyAndroid/build

# Compiler pour ARM64 (appareils Android récents)
swiftly run swift build \
  --swift-sdk aarch64-unknown-linux-android28 \
  --static-swift-stdlib \
  -c release

# Compiler pour x86_64 (émulateurs)
swiftly run swift build \
  --swift-sdk x86_64-unknown-linux-android28 \
  --static-swift-stdlib \
  -c release
```

**Note** : Pour Shoply, vous devrez adapter le projet car il utilise SwiftUI (spécifique à iOS). La logique métier (Models, Services) peut être compilée, mais l'UI devra être refaite en Jetpack Compose pour Android.

## 📦 Étape 9 : Créer la Structure du Projet Android

Pour intégrer votre code Swift dans une app Android, vous devez créer un projet Android standard et y inclure les bibliothèques Swift compilées.

Utilisez les scripts fournis dans le dossier `ShoplyAndroid/` :

- `setup-android-project.sh` : Crée la structure de base
- `build-swift-libs.sh` : Compile les bibliothèques Swift
- `build-android-app.sh` : Compile l'app Android complète

## 🚀 Prochaines Étapes

1. ✅ Installation terminée - Votre environnement est prêt !
2. 📝 Consultez `ShoplyAndroid/README.md` pour les détails du projet Android
3. 🔧 Utilisez les scripts dans `ShoplyAndroid/scripts/` pour automatiser le build
4. 📖 Consultez les [exemples Swift Android](https://github.com/apple/swift-android-examples) pour voir comment intégrer Swift dans une app Android

## 🆘 Dépannage

### Erreur : "swift sdk list" ne montre pas le SDK Android
- Vérifiez que vous avez bien installé le SDK avec la bonne version
- Vérifiez que la version du toolchain Swift correspond au SDK

### Erreur : "NDK not found"
- Vérifiez que `ANDROID_NDK_HOME` est bien défini
- Exécutez à nouveau le script `setup-android-sdk.sh`

### Erreur lors de la compilation
- Vérifiez que vous utilisez `swiftly run swift` et non juste `swift`
- Assurez-vous que toutes les dépendances sont installées

### SwiftUI n'est pas disponible
- SwiftUI est spécifique à Apple et ne fonctionne pas sur Android
- Vous devrez créer l'UI Android avec Jetpack Compose ou XML
- La logique métier Swift (Models, Services) peut être utilisée telle quelle

## 📚 Ressources

- **Guide Officiel** : https://www.swift.org/documentation/articles/swift-sdk-for-android-getting-started.html
- **Exemples de Projets** : https://github.com/apple/swift-android-examples
- **Swift Forums Android** : https://forums.swift.org/c/android/
- **Android NDK Documentation** : https://developer.android.com/ndk

