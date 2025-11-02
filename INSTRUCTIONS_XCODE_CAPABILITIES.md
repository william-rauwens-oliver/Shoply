# Instructions pour désactiver Apple Sign In dans Xcode

## 🎯 Objectif

Désactiver complètement la capability "Sign in with Apple" dans Xcode pour éviter les erreurs de compilation avec un compte développeur gratuit.

## 📋 Étapes à suivre dans Xcode

### 1. Ouvrir le projet dans Xcode

1. Ouvrez `Shoply.xcodeproj` dans Xcode

### 2. Vérifier les Capabilities

1. **Sélectionnez le projet** "Shoply" (icône bleue en haut à gauche)
2. **Sélectionnez le target "Shoply"** (sous "TARGETS", pas le widget)
3. **Cliquez sur l'onglet "Signing & Capabilities"**

### 3. Supprimer "Sign in with Apple" si présent

**Si vous voyez "Sign in with Apple" dans la liste des Capabilities :**

1. Trouvez la ligne **"Sign in with Apple"**
2. **Cliquez sur le "X"** rouge à gauche du nom
3. Confirmez la suppression si Xcode vous le demande

**Si vous ne voyez PAS "Sign in with Apple" :**
- ✅ C'est bon, passez à l'étape suivante

### 4. Vérifier le fichier Entitlements

1. Dans le navigateur de projet (panneau gauche), ouvrez le fichier **`Shoply/Shoply.entitlements`**
2. **Vérifiez** que le fichier **NE contient PAS** cette section :
   ```xml
   <key>com.apple.developer.applesignin</key>
   <array>
       <string>Default</string>
   </array>
   ```
3. ✅ Le fichier actuel est correct (pas d'Apple Sign In)

### 5. Nettoyer le projet

1. Menu **Product** → **Clean Build Folder** (⇧⌘K)
2. Attendez que le nettoyage se termine

### 6. Recompiler

1. Menu **Product** → **Build** (⌘B)
2. Vérifiez qu'il n'y a plus d'erreurs liées à Apple Sign In

## ✅ Vérification finale

Après ces étapes, vous devriez avoir :

- ✅ Aucune capability "Sign in with Apple" dans Signing & Capabilities
- ✅ Le fichier `Shoply.entitlements` sans `com.apple.developer.applesignin`
- ✅ Le projet compile sans erreur
- ✅ Le flux de l'app : **RGPD → Onboarding → Application**

## 🔄 Si l'erreur persiste

Si Xcode continue de se plaindre, c'est qu'il y a un **profil de provisionnement en cache** :

### Option 1 : Supprimer les profils en cache

1. Dans Xcode : **Xcode → Settings → Accounts**
2. Sélectionnez votre compte
3. Cliquez sur votre **Team**
4. Cliquez sur **"Download Manual Profiles"**
5. Ou **supprimez les profils** et laissez Xcode les recréer

### Option 2 : Supprimer les Derived Data

Dans le Terminal :
```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/Shoply-*
```

Puis dans Xcode :
- **Product** → **Clean Build Folder** (⇧⌘K)
- **Product** → **Build** (⌘B)

### Option 3 : Retirer temporairement les entitlements

**ATTENTION : À faire seulement si rien d'autre ne fonctionne**

1. Dans Xcode → Target "Shoply" → **Build Settings**
2. Cherchez **"Code Signing Entitlements"**
3. **Double-cliquez** sur la valeur
4. **Supprimez** `Shoply/Shoply.entitlements` (laissez vide)
5. Cliquez ailleurs pour valider
6. Recompilez

**Note** : Remettez-le après si vous avez besoin d'autres entitlements (comme App Groups pour les widgets).

## 📱 Flux de l'application

Avec Apple Sign In désactivé, le flux est :

1. **RGPD** → Acceptation des conditions
2. **Onboarding** → Prénom / Âge / Genre
3. **Application** → Toutes les fonctionnalités disponibles

## ✨ Fonctionnalités disponibles

- ✅ Toutes les fonctionnalités de l'app
- ✅ Sauvegarde locale des données
- ✅ Synchronisation iCloud **manuelle** (depuis Paramètres → Synchronisation iCloud)
- ✅ Gestion de garde-robe
- ✅ Suggestions d'outfits
- ✅ Chat IA
- ✅ Historique et favoris
- ✅ Calendrier

L'application fonctionne **parfaitement** sans Apple Sign In ! 🎉

