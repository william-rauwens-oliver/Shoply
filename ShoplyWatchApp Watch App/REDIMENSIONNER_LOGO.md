# Redimensionner le Logo 1080x1080 → 1024x1024

## 🎯 Option 1 : Redimensionner l'Image (Recommandé)

### Méthode A : Avec Preview (macOS)
1. Ouvrez votre image 1080x1084 dans **Preview**
2. Menu **Outils** > **Ajuster la taille...**
3. Décochez **"Conserver les proportions"** (ou gardez-le si vous voulez)
4. Changez la largeur à **1024** pixels
5. Changez la hauteur à **1024** pixels
6. Cliquez sur **"OK"**
7. Menu **Fichier** > **Exporter...**
8. Choisissez **PNG** comme format
9. Nommez-la : `Shoply-Watch-1024x1024.png`
10. Enregistrez

### Méthode B : Avec un outil en ligne
1. Allez sur https://www.iloveimg.com/resize-image
2. Téléversez votre image 1080x1080
3. Changez la taille à **1024x1024**
4. Téléchargez l'image redimensionnée

### Méthode C : Avec sips (Terminal)
```bash
sips -z 1024 1024 votre-image-1080x1080.png --out Shoply-Watch-1024x1024.png
```

## 🎯 Option 2 : Utiliser l'Image 1080x1080 Directement

Si vous voulez utiliser votre image 1080x1080 telle quelle (non recommandé mais possible) :

1. Renommez votre image en : `Shoply-Watch-1080x1080.png`
2. Placez-la dans : `ShoplyWatchApp Watch App/Assets.xcassets/AppIcon.appiconset/`
3. Je vais mettre à jour le fichier Contents.json pour accepter cette taille

**Note** : Apple recommande strictement 1024x1024 pour watchOS. L'image 1080x1080 pourrait être redimensionnée automatiquement par Xcode, ce qui peut dégrader la qualité.

## ✅ Recommandation

Je recommande fortement de **redimensionner à 1024x1024** pour :
- Meilleure qualité sur la Watch
- Conformité aux recommandations Apple
- Pas de dégradation lors du redimensionnement automatique

