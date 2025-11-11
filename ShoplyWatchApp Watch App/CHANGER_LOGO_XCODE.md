# Comment Changer le Logo sur Xcode (watchOS 26)

## 📱 Méthode Simple dans Xcode

### Étape 1 : Trouver AppIcon dans le Navigateur

1. Dans le **navigateur de gauche** (panneau de fichiers)
2. Développez : `ShoplyWatchApp Watch App`
3. Développez : `Assets.xcassets`
4. Cliquez sur : **`AppIcon`**

### Étape 2 : Ajouter votre Image

1. Vous devriez voir une zone avec "AppIcon" et des emplacements pour les images
2. **Glissez-déposez** votre image `Shoply-Watch-1024x1024.png` dans la zone "AppIcon"
3. Xcode va automatiquement :
   - Copier l'image dans le bon dossier
   - Mettre à jour le fichier `Contents.json`

### Étape 3 : Vérifier

1. Dans le navigateur, vérifiez que votre image apparaît dans :
   ```
   ShoplyWatchApp Watch App > Assets.xcassets > AppIcon.appiconset
   ```
2. Vous devriez voir votre fichier `Shoply-Watch-1024x1024.png`

### Étape 4 : Nettoyer et Recompiler

1. Menu **Product** > **Clean Build Folder** (ou **⇧⌘K**)
2. Menu **Product** > **Build** (ou **⌘B**)
3. Lancez l'app sur le simulateur Watch
4. Le nouveau logo devrait apparaître !

## 🎯 Si vous ne voyez pas la zone AppIcon

### Alternative : Ajouter manuellement

1. Dans le navigateur, allez dans :
   ```
   ShoplyWatchApp Watch App > Assets.xcassets > AppIcon.appiconset
   ```

2. **Clic droit** sur `AppIcon.appiconset`
3. Sélectionnez **"Show in Finder"**
4. Copiez votre image `Shoply-Watch-1024x1024.png` dans ce dossier
5. Revenez dans Xcode
6. L'image devrait apparaître automatiquement

## 📝 Vérification Rapide

Après avoir ajouté l'image, vérifiez que :
- ✅ L'image est dans `AppIcon.appiconset`
- ✅ Le fichier `Contents.json` contient le bon nom de fichier
- ✅ Vous avez nettoyé le build (⇧⌘K)
- ✅ Vous avez recompilé (⌘B)

## ⚠️ Si le logo ne change pas

1. **Supprimez l'app** du simulateur Watch
2. **Nettoyez le build** : ⇧⌘K
3. **Recompilez** : ⌘B
4. **Relancez** l'app

Le logo devrait maintenant apparaître !

