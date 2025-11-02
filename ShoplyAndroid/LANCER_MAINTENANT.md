# 🚀 Lancer Shoply Android - Instructions Rapides

## ✅ Méthode 1 : Depuis Android Studio (Recommandé)

1. **Android Studio est maintenant ouvert** ✅
2. **Attendre que Gradle se synchronise** (en bas de l'écran)
3. **Ouvrir Device Manager** : `Tools → Device Manager`
4. **Lancer un émulateur** :
   - Si vous n'en avez pas, cliquez `Create Device`
   - Sinon, cliquez `Play ▶️` sur un émulateur existant
5. **Une fois l'émulateur lancé** :
   - Cliquez sur le bouton **Run ▶️** en haut à droite
   - Ou utilisez `Shift + F10` (Windows/Linux) ou `Ctrl + R` (Mac)
6. **Sélectionner l'appareil** dans la liste
7. **L'app va se compiler et se lancer automatiquement !** ✅

## ✅ Méthode 2 : Depuis le Terminal

```bash
cd "/Users/williamrauwensoliver/Projet SWIFT/Shoply/ShoplyAndroid"

# Configurer les variables
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH

# Compiler
./gradlew assembleDebug

# Vérifier qu'un appareil est connecté
adb devices

# Installer et lancer
adb install -r app/build/outputs/apk/debug/app-debug.apk
adb shell am start -n com.shoply.app/.MainActivity
```

## 📋 Checklist Avant de Lancer

- ✅ Android Studio installé
- ✅ Gradle synchronisé (voir la barre en bas d'Android Studio)
- ✅ Émulateur ou appareil physique connecté
- ✅ APK compilé (se fait automatiquement au premier lancement)

## 🎯 Ce qui va se passer

1. **Compilation** : Gradle va compiler le code Kotlin et les ressources
2. **Installation** : L'APK sera installé sur l'appareil
3. **Lancement** : L'app va s'ouvrir automatiquement
4. **SwiftUI** : L'app utilisera le code Swift compilé (quand disponible)

## ⚠️ Note Importante

Pour l'instant, l'app utilise un minimum de Kotlin (juste le container). 
Quand le Swift SDK Android supportera SwiftUI directement, l'app utilisera 100% Swift !

## 🐛 En cas de Problème

1. **Gradle ne compile pas** :
   - Vérifiez que Java 21 est bien utilisé : `File → Project Structure → SDK Location`
   - Synchronisez Gradle : `File → Sync Project with Gradle Files`

2. **Aucun appareil** :
   - Créez un émulateur : `Tools → Device Manager → Create Device`
   - Ou connectez un appareil physique avec USB debugging activé

3. **Erreurs de compilation** :
   - Vérifiez les logs dans Android Studio (onglet `Build` en bas)
   - Les erreurs seront affichées en rouge

**Android Studio est maintenant ouvert !** 🚀
