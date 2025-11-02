# 🚀 Comment Lancer l'App Shoply Android

## Méthode 1 : Via Android Studio (Recommandé)

1. **Ouvrir Android Studio**
   ```bash
   cd "/Users/williamrauwensoliver/Projet SWIFT/Shoply/ShoplyAndroid"
   open -a "Android Studio" .
   ```

2. **Lancer un émulateur** :
   - Dans Android Studio : **Tools → Device Manager**
   - Cliquez **Play ▶️** sur un émulateur (ou créez-en un si besoin)

3. **Compiler et lancer** :
   - Cliquez sur **Run ▶️** en haut (ou `⌘R`)
   - L'app se compile, s'installe et se lance automatiquement !

## Méthode 2 : Via Terminal (une fois l'émulateur lancé)

```bash
cd "/Users/williamrauwensoliver/Projet SWIFT/Shoply/ShoplyAndroid"

# 1. Compiler l'APK
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_HOME=$HOME/Library/Android/sdk
./gradlew assembleDebug --no-daemon

# 2. Installer sur l'émulateur
export PATH=$PATH:$ANDROID_HOME/platform-tools
adb install -r app/build/outputs/apk/debug/app-debug.apk

# 3. Lancer l'app
adb shell am start -n com.shoply.app/.MainActivity
```

## Méthode 3 : Script Automatique

```bash
cd "/Users/williamrauwensoliver/Projet SWIFT/Shoply/ShoplyAndroid"
./scripts/lancer-app.sh
```

## ⚠️ Si l'émulateur n'est pas lancé

1. Ouvrir Android Studio
2. **Tools → Device Manager**
3. **Create Device** (si premier) ou **Play ▶️** (si existe)
4. Attendre que l'émulateur démarre
5. Relancer la compilation/installation

## 🔧 Dépannage

### Erreur : "Gradle not found"
```bash
chmod +x gradlew
./gradlew --version
```

### Erreur : "Java not found"
```bash
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export PATH=$JAVA_HOME/bin:$PATH
```

### Erreur : "No devices found"
- Vérifier qu'un émulateur est lancé : `adb devices`
- Si aucun : Lancer depuis Android Studio (Device Manager)

### Erreur de compilation
```bash
./gradlew clean assembleDebug --stacktrace
```

## ✅ Vérification

- **APK compilé** : `app/build/outputs/apk/debug/app-debug.apk` (devrait exister)
- **Émulateur lancé** : `adb devices` (doit montrer un device)
- **App installée** : Vérifier dans le launcher de l'émulateur

