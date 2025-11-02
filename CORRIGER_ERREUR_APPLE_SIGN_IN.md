# 🔧 Corriger l'erreur Apple Sign In avec compte gratuit

## ❌ Erreur actuelle

```
Cannot create a iOS App Development provisioning profile for "William.Shoply".
Personal development teams do not support the Sign in with Apple capability.
```

## ✅ Solution étape par étape

### Étape 1 : Vérifier dans Xcode

1. **Ouvrez Xcode**
2. **Sélectionnez le projet** "Shoply" (icône bleue en haut)
3. **Sélectionnez le target "Shoply"** (pas le widget)
4. **Allez dans l'onglet "Signing & Capabilities"**
5. **Vérifiez si "Sign in with Apple" apparaît dans la liste des Capabilities**

### Étape 2 : Supprimer la capability Apple Sign In (si présente)

Si vous voyez "Sign in with Apple" dans la liste :

1. **Cliquez sur le "X"** à côté de "Sign in with Apple"
2. Confirmez la suppression si demandé
3. La capability disparaîtra de la liste

### Étape 3 : Vérifier le fichier Entitlements

Le fichier `Shoply/Shoply.entitlements` doit **NE PAS contenir** cette ligne :
```xml
<key>com.apple.developer.applesignin</key>
```

✅ Le fichier actuel est correct (sans Apple Sign In)

### Étape 4 : Nettoyer les profils de provisionnement

1. Dans Xcode, allez dans **Xcode → Settings → Accounts**
2. Sélectionnez votre compte Apple
3. Cliquez sur **"Download Manual Profiles"** puis **"Download All Profiles"**
4. Ou supprimez les profils existants et laissez Xcode les recréer

### Étape 5 : Nettoyer complètement le projet

**Dans Xcode :**
1. Menu **Product** → **Clean Build Folder** (⇧⌘K)
2. Menu **File** → **Close Project**
3. **Fermez Xcode complètement**

**Dans le Terminal (optionnel mais recommandé) :**
```bash
cd "/Users/williamrauwensoliver/Projet SWIFT/Shoply"
rm -rf ~/Library/Developer/Xcode/DerivedData/Shoply-*
rm -rf build/
```

### Étape 6 : Rouvrir et recompiler

1. **Rouvrez Xcode**
2. **Ouvrez le projet** `Shoply.xcodeproj`
3. **Vérifiez** que "Sign in with Apple" n'apparaît PAS dans Signing & Capabilities
4. Menu **Product** → **Build** (⌘B)

### Étape 7 : Si l'erreur persiste

Si l'erreur persiste, il y a peut-être une capability activée au niveau du Bundle Identifier :

1. Allez sur [developer.apple.com](https://developer.apple.com)
2. Connectez-vous avec votre compte
3. Allez dans **Certificates, Identifiers & Profiles**
4. Sélectionnez **Identifiers**
5. Trouvez **"William.Shoply"**
6. Cliquez dessus
7. **Décochez "Sign In with Apple"** si elle est cochée
8. Cliquez sur **Save**
9. Retournez dans Xcode et nettoyez/reconstruisez

## 🎯 Résultat attendu

Après ces étapes :
- ✅ L'application compile sans erreur
- ✅ Le flux est : **RGPD → Onboarding → Application**
- ✅ Apple Sign In est complètement désactivé
- ✅ Toutes les fonctionnalités fonctionnent normalement

## 📝 Note importante

**Apple Sign In nécessite un compte développeur payant** (99$/an). Pour un compte gratuit :
- ✅ L'application fonctionne parfaitement sans Apple Sign In
- ✅ Toutes les fonctionnalités sont disponibles
- ✅ La synchronisation iCloud manuelle fonctionne (depuis Paramètres)

## ⚠️ Si rien ne fonctionne

Comme dernière option, vous pouvez temporairement retirer la référence aux entitlements dans le projet :

1. Dans Xcode → Target "Shoply" → Build Settings
2. Cherchez "Code Signing Entitlements"
3. **Supprimez** `Shoply/Shoply.entitlements` (laissez vide)
4. Recompilez

Puis remettez-le après si nécessaire pour d'autres fonctionnalités.

