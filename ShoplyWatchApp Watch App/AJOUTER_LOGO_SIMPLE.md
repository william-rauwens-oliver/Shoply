# Ajouter le Logo selon la Documentation Xcode

## 📱 Méthode 1 : Glisser-Déposer (Le Plus Simple)

### Étape 1 : Préparer votre image
- Votre image doit être en PNG
- Taille : 1024x1024 pixels (ou 1080x1080 que vous pouvez redimensionner)
- Nommez-la : `Shoply-Watch-1024x1024.png`

### Étape 2 : Glisser depuis le Finder
1. Ouvrez **Finder** et trouvez votre image `Shoply-Watch-1024x1024.png`
2. Dans **Xcode**, dans le navigateur de gauche :
   - Allez dans : `ShoplyWatchApp Watch App > Assets.xcassets > AppIcon.appiconset`
3. **Glissez votre image** depuis Finder et **déposez-la** dans le dossier `AppIcon.appiconset` dans Xcode
4. Xcode va automatiquement :
   - Copier l'image dans le projet
   - Mettre à jour la configuration

## 📱 Méthode 2 : Menu File > Add Files

### Selon la documentation Xcode :

1. Dans le navigateur, **sélectionnez** le dossier `AppIcon.appiconset`
2. Menu **File** > **Add Files to "Shoply"**
3. Dans la fenêtre qui s'ouvre :
   - **Sélectionnez** votre image `Shoply-Watch-1024x1024.png`
   - **Cochez** "Copy items if needed" (pour copier l'image dans le projet)
   - **Sélectionnez** le target "ShoplyWatchApp Watch App"
   - Cliquez sur **"Add"**

## 📱 Méthode 3 : Remplacer l'Image Existante

Si vous avez déjà une image dans `AppIcon.appiconset` :

1. Dans le navigateur, trouvez l'image existante dans :
   ```
   ShoplyWatchApp Watch App > Assets.xcassets > AppIcon.appiconset
   ```
2. **Clic droit** sur l'image existante
3. Sélectionnez **"Show in Finder"**
4. **Remplacez** l'image dans Finder par votre nouvelle image (même nom)
5. Revenez dans Xcode
6. L'image devrait se mettre à jour automatiquement

## ✅ Vérification

Après avoir ajouté l'image :
1. **Nettoyez le build** : Menu **Product** > **Clean Build Folder** (⇧⌘K)
2. **Recompilez** : Menu **Product** > **Build** (⌘B)
3. **Lancez l'app** sur le simulateur Watch
4. Le nouveau logo devrait apparaître !

## 🎯 Option Recommandée

**La méthode la plus simple** : Glisser-déposer depuis Finder directement dans le dossier `AppIcon.appiconset` dans le navigateur Xcode.

