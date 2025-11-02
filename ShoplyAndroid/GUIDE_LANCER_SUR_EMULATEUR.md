# 🚀 Guide : Lancer Shoply Android sur un Émulateur/VM

Ce guide vous explique comment lancer l'application Shoply Android sur un émulateur Android (VM).

## 📋 Prérequis

- ✅ Android Studio installé
- ✅ Android SDK installé (via Android Studio)
- ✅ ADB configuré dans le PATH
- ✅ Projet Shoply Android configuré

## 🎯 Méthode 1 : Android Studio (Recommandé)

### Étape 1 : Ouvrir le Projet

```bash
cd ShoplyAndroid
open -a "Android Studio" .
```

Ou depuis Android Studio :
- File → Open → Sélectionner le dossier `ShoplyAndroid`

### Étape 2 : Créer un Émulateur Android

1. **Ouvrir Device Manager** :
   - Tools → Device Manager
   - Ou cliquer sur l'icône 📱 dans la barre d'outils

2. **Créer un Appareil Virtuel** :
   - Cliquer sur **"Create Device"**
   - Choisir un appareil (ex: **Pixel 6** ou **Pixel 7**)
   - Cliquer **Next**

3. **Télécharger une Image Système** :
   - Sélectionner une image système (ex: **API 33** ou **API 34**)
   - Si nécessaire, cliquer **Download** pour télécharger l'image
   - Cliquer **Next**

4. **Configurer l'Émulateur** :
   - Nom : "Pixel_6_API_33" (par exemple)
   - Cliquer **Finish**

### Étape 3 : Lancer l'Émulateur

1. Dans **Device Manager**, trouver votre émulateur créé
2. Cliquer sur le bouton **▶️ Play** à côté de l'émulateur
3. Attendre que l'émulateur démarre (peut prendre 1-2 minutes)

### Étape 4 : Installer et Lancer l'App

#### Option A : Via Android Studio
1. Sélectionner votre émulateur dans la liste déroulante en haut
2. Cliquer sur **Run ▶️** (ou appuyer sur `⌘R` sur macOS)
3. L'app se compile et s'installe automatiquement

#### Option B : Via Ligne de Commande
```bash
# Vérifier que l'émulateur est connecté
adb devices

# Compiler l'app
cd ShoplyAndroid
./scripts/build-android-app.sh debug

# Installer l'APK
adb install app/build/outputs/apk/debug/app-debug.apk

# Lancer l'app
adb shell am start -n com.shoply.app/.MainActivity
```

## 🎯 Méthode 2 : Émulateur via Ligne de Commande

### Créer un Émulateur avec AVD Manager

```bash
# Lister les images système disponibles
sdkmanager --list | grep "system-images"

# Installer une image système (ex: Android 13, API 33)
sdkmanager "system-images;android-33;google_apis;arm64-v8a"

# Créer l'AVD
avdmanager create avd -n Pixel_6_API_33 -k "system-images;android-33;google_apis;arm64-v8a" -d "pixel_6"
```

### Lancer l'Émulateur

```bash
# Lancer l'émulateur
emulator -avd Pixel_6_API_33 &

# Ou en mode accéléré (plus rapide)
emulator -avd Pixel_6_API_33 -accel on &

# Attendre que l'émulateur démarre
adb wait-for-device

# Vérifier la connexion
adb devices
```

### Installer l'App

```bash
cd ShoplyAndroid

# Compiler
./scripts/build-android-app.sh debug

# Installer
adb install app/build/outputs/apk/debug/app-debug.apk

# Lancer
adb shell am start -n com.shoply.app/.MainActivity
```

## 🎯 Méthode 3 : Utiliser un Appareil Physique

Si vous avez un téléphone Android :

### Activer le Mode Développeur

1. **Paramètres** → **À propos du téléphone**
2. Taper 7 fois sur **"Numéro de build"**
3. Message : "Vous êtes maintenant développeur !"

### Activer le Débogage USB

1. **Paramètres** → **Options développeur**
2. Activer **"Débogage USB"**
3. Connecter le téléphone en USB
4. Accepter la popup de confiance sur le téléphone

### Installer l'App

```bash
# Vérifier la connexion
adb devices

# Installer
adb install ShoplyAndroid/app/build/outputs/apk/debug/app-debug.apk
```

## 🔧 Dépannage

### L'émulateur ne démarre pas

```bash
# Vérifier les variables d'environnement
echo $ANDROID_HOME
echo $ANDROID_SDK_ROOT

# Si non définies, les ajouter à ~/.zshrc
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
```

### ADB ne trouve pas l'appareil

```bash
# Redémarrer ADB
adb kill-server
adb start-server

# Lister les appareils
adb devices

# Si vide, vérifier que l'émulateur tourne
ps aux | grep emulator
```

### Erreur "device offline"

```bash
# Redémarrer l'émulateur
adb kill-server
adb start-server
# Redémarrer l'émulateur depuis Android Studio
```

### L'app crash au lancement

```bash
# Voir les logs en temps réel
adb logcat | grep Shoply

# Voir les erreurs spécifiques
adb logcat *:E

# Nettoyer et réinstaller
adb uninstall com.shoply.app
adb install app/build/outputs/apk/debug/app-debug.apk
```

### L'émulateur est trop lent

1. **Activer l'accélération matérielle** :
   - Dans AVD Manager → Edit → Advanced Settings
   - Graphics : "Hardware - GLES 2.0"

2. **Augmenter la RAM** :
   - RAM : 4096 MB (au lieu de 2048)

3. **Utiliser x86_64** :
   - Préférer les images x86_64 plutôt qu'ARM

## 📱 Commandes Utiles ADB

```bash
# Lister les appareils
adb devices

# Voir les logs en temps réel
adb logcat

# Filtrer les logs par tag
adb logcat -s Shoply:D MainActivity:D

# Redémarrer l'app
adb shell am force-stop com.shoply.app
adb shell am start -n com.shoply.app/.MainActivity

# Prendre une capture d'écran
adb shell screencap -p /sdcard/screenshot.png
adb pull /sdcard/screenshot.png

# Enregistrer une vidéo
adb shell screenrecord /sdcard/recording.mp4
# Ctrl+C pour arrêter
adb pull /sdcard/recording.mp4

# Installer l'APK
adb install app-debug.apk

# Désinstaller l'app
adb uninstall com.shoply.app

# Voir les informations de l'appareil
adb shell getprop ro.product.model
adb shell getprop ro.build.version.release
```

## 🎯 Quick Start (Résumé Rapide)

```bash
# 1. Ouvrir Android Studio
cd ShoplyAndroid
open -a "Android Studio" .

# 2. Créer un émulateur (Device Manager → Create Device)

# 3. Lancer l'émulateur (bouton Play)

# 4. Dans Android Studio, cliquer Run ▶️

# Ou via ligne de commande :
./scripts/build-android-app.sh debug
adb install app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.shoply.app/.MainActivity
```

## ✅ Checklist

- [ ] Android Studio installé
- [ ] Émulateur créé dans Device Manager
- [ ] Émulateur lancé et visible dans `adb devices`
- [ ] Projet compilé avec succès
- [ ] App installée sur l'émulateur
- [ ] App lancée et fonctionnelle

## 📚 Ressources

- **Android Studio** : https://developer.android.com/studio
- **AVD Manager** : https://developer.android.com/studio/run/managing-avds
- **ADB Documentation** : https://developer.android.com/studio/command-line/adb

---

**💡 Astuce** : Si l'émulateur est lent, utilisez un appareil physique Android via USB - c'est beaucoup plus rapide !

