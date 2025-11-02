# 🚀 Guide : Lancer l'App Shoply Android

## 📱 Méthode Simple (Depuis Android Studio)

### Étape 1 : Ouvrir le Projet
✅ Android Studio devrait déjà être ouvert avec le projet ShoplyAndroid

Si ce n'est pas le cas :
```bash
cd "/Users/williamrauwensoliver/Projet SWIFT/Shoply/ShoplyAndroid"
open -a "Android Studio" .
```

### Étape 2 : Attendre la Synchronisation Gradle
- Android Studio va automatiquement synchroniser le projet
- Attendre que la barre en bas affiche "Gradle sync completed"
- Si erreur, cliquer sur "Sync Project with Gradle Files" (🔄 en haut)

### Étape 3 : Créer un Émulateur (si pas déjà fait)

1. **Ouvrir Device Manager** :
   - Cliquer sur l'icône 📱 dans la barre latérale droite
   - Ou : **Tools → Device Manager**

2. **Créer un Appareil** :
   - Cliquer **Create Device**
   - Choisir **Pixel 6** (ou Pixel 7)
   - Cliquer **Next**

3. **Choisir une Image Système** :
   - Sélectionner **API 33** (Android 13) ou **API 34**
   - Si pas installé, cliquer **Download** et attendre
   - Cliquer **Next**

4. **Configurer** :
   - Nom : "Pixel_6_API_33" (par défaut)
   - Cliquer **Finish**

### Étape 4 : Lancer l'Émulateur

1. Dans **Device Manager**, trouver votre émulateur
2. Cliquer sur le bouton **▶️ Play** à côté
3. Attendre que l'émulateur démarre (1-2 minutes)

### Étape 5 : Lancer l'Application

1. En haut de Android Studio, dans la barre d'outils :
   - Vérifier que l'émulateur est sélectionné (ex: "Pixel_6_API_33")
   - Si pas, cliquer sur la liste déroulante et sélectionner l'émulateur

2. **Lancer l'app** :
   - Cliquer sur le bouton vert **▶️ Run** (ou appuyer `⌘R`)
   - Android Studio va :
     - Compiler l'application
     - Installer l'APK sur l'émulateur
     - Lancer l'app automatiquement

3. **L'app devrait apparaître sur l'émulateur** ! 🎉

## 🔧 Si Problème de Compilation

### Erreur "Gradle sync failed"

1. **Vérifier la connexion internet** (Gradle télécharge des dépendances)
2. **Sync manuel** : 
   - File → Sync Project with Gradle Files
3. **Nettoyer** :
   - Build → Clean Project
   - Puis Build → Rebuild Project

### Erreur "SDK not found"

1. **Vérifier local.properties** :
   - Le fichier doit contenir : `sdk.dir=/Users/williamrauwensoliver/Library/Android/sdk`
   - Si pas, ajoutez cette ligne

2. **Configurer SDK dans Android Studio** :
   - Android Studio → Preferences → Appearance & Behavior → System Settings → Android SDK
   - Vérifier que le SDK est bien configuré

### L'émulateur ne démarre pas

1. **Vérifier que HAXM est installé** (pour accélération matérielle)
2. **Essayer sans accélération** :
   - Dans Device Manager → Edit → Advanced Settings
   - Graphics : "Software - GLES 2.0"

## 📋 Commandes Utiles dans Android Studio

- **⌘R** : Run (lancer l'app)
- **⌘. (Ctrl+.)** : Stop (arrêter l'app)
- **⌘B** : Build (compiler)
- **⌘F9** : Rebuild Project

## 🔍 Vérifier que ça Marche

Une fois l'app lancée, vous devriez voir :
- ✅ L'écran d'accueil Shoply
- ✅ Navigation fonctionnelle
- ✅ Tous les écrans accessibles

## 📱 Alternative : Appareil Physique

Si l'émulateur est trop lent, utilisez un téléphone Android :

1. **Activer le mode développeur** :
   - Paramètres → À propos → Taper 7x sur "Numéro de build"

2. **Activer débogage USB** :
   - Options développeur → Débogage USB ✅

3. **Connecter le téléphone en USB**

4. **Dans Android Studio** :
   - Sélectionner le téléphone dans la liste des appareils
   - Cliquer Run ▶️

---

**💡 Astuce** : La première fois, Android Studio peut prendre du temps pour télécharger les dépendances et compiler. Soyez patient ! 😊

