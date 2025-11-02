# ⚡ Quick Start : Lancer Shoply sur un Émulateur

## 🎯 Méthode la Plus Simple (Android Studio)

### 1. Ouvrir le Projet
```bash
cd ShoplyAndroid
open -a "Android Studio" .
```

### 2. Créer un Émulateur
1. Dans Android Studio : **Tools → Device Manager**
2. Cliquer **Create Device**
3. Choisir **Pixel 6**
4. Télécharger **API 33** (Android 13) si nécessaire
5. Cliquer **Finish**

### 3. Lancer l'Émulateur
1. Dans Device Manager, cliquer sur **▶️ Play** à côté de l'émulateur
2. Attendre le démarrage (~1-2 minutes)

### 4. Lancer l'App
1. Dans Android Studio, sélectionner l'émulateur en haut
2. Cliquer sur **Run ▶️** (ou `⌘R`)
3. L'app se compile et s'installe automatiquement !

## 🚀 Méthode Rapide (Ligne de Commande)

### Si vous avez déjà un émulateur lancé :

```bash
cd ShoplyAndroid

# Option 1 : Script automatique
./scripts/launch-on-emulator.sh

# Option 2 : Manuellement
./scripts/build-android-app.sh debug
adb install app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.shoply.app/.MainActivity
```

## ✅ Vérifier que l'Émulateur est Connecté

```bash
adb devices
# Doit afficher quelque chose comme :
# List of devices attached
# emulator-5554   device
```

## 🔧 Si Problème : Configurer le PATH

Ajoutez à `~/.zshrc` :

```bash
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools
export PATH=$PATH:$ANDROID_HOME/emulator
export PATH=$PATH:$ANDROID_HOME/tools
export PATH=$PATH:$ANDROID_HOME/tools/bin
```

Puis :
```bash
source ~/.zshrc
```

## 📱 Alternative : Appareil Physique

Si vous avez un téléphone Android :

1. **Activer Options développeur** : Paramètres → À propos → Taper 7x sur "Numéro de build"
2. **Activer Débogage USB** : Options développeur → Débogage USB
3. **Connecter en USB** et accepter la popup
4. Lancer le script : `./scripts/launch-on-emulator.sh`

---

**💡 Astuce** : Android Studio est la méthode la plus simple - il gère tout automatiquement !

