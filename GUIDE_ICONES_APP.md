# Guide : Ajouter un Logo/Icone pour iOS, iPadOS et watchOS

Ce guide explique comment ajouter un logo personnalisé pour votre application Shoply sur iOS, iPadOS et Apple Watch.

## 📋 Prérequis

Avant de commencer, vous devez avoir :
- Un logo/image en **1024x1024 pixels** minimum (format PNG recommandé)
- Le logo doit être :
  - **Carré** (ratio 1:1)
  - **Sans transparence** (fond opaque)
  - **Haute résolution** (1024x1024 minimum pour iOS, 1024x1024 pour watchOS)

## 🎨 Format du Logo

Pour les applications iOS et iPadOS modernes (iOS 18+), vous avez besoin :
- **1 icône principale** : 1024x1024 pixels (universelle pour iPhone/iPad)
- **Optionnel** : Version dark mode et tinted si vous voulez des variantes

Pour Apple Watch (watchOS 11+), vous avez besoin :
- **Icône principale** : 1024x1024 pixels

## 📝 Étapes pour iOS et iPadOS

### 1. Préparer votre logo

Créez ou exportez votre logo en **1024x1024 pixels** en PNG. Assurez-vous que :
- Le logo est centré
- Il y a un padding autour (le logo ne doit pas toucher les bords)
- Le fond est opaque (pas de transparence)

### 2. Ajouter l'icône dans Xcode

1. **Ouvrez votre projet** dans Xcode
2. **Dans le navigateur de projet**, trouvez `Shoply/Assets.xcassets`
3. **Cliquez sur `AppIcon`** (ou créez-le s'il n'existe pas)
4. **Dans la vue de l'icône**, vous verrez des emplacements vides avec des dimensions
5. **Glissez-déposez** votre image 1024x1024 dans l'emplacement :
   - **iOS App Icon - Universal** (1024x1024)
   - **iOS App Icon - Dark** (1024x1024) - optionnel
   - **iOS App Icon - Tinted** (1024x1024) - optionnel si vous voulez une version teintée)

### 3. Vérifier la configuration

Le fichier `Contents.json` dans `AppIcon.appiconset` devrait ressembler à ceci :

```json
{
  "images" : [
    {
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

## ⌚ Étapes pour Apple Watch

### 1. Localiser les Assets pour Watch

Si vous avez un target Apple Watch (`ShoplyWatchExtension`), vous devez :

1. **Créer un Assets.xcassets** dans le dossier `ShoplyWatchExtension/` s'il n'existe pas
2. **Créer un AppIcon.appiconset** dans ce dossier Assets

### 2. Structure de fichiers

Créez la structure suivante :
```
ShoplyWatchExtension/
  └── Assets.xcassets/
      └── AppIcon.appiconset/
          ├── Contents.json
          └── [votre icône 1024x1024].png
```

### 3. Contenu de Contents.json pour Watch

Créez un fichier `Contents.json` dans `ShoplyWatchExtension/Assets.xcassets/AppIcon.appiconset/` :

```json
{
  "images" : [
    {
      "idiom" : "watch",
      "role" : "appLauncher",
      "size" : "1024x1024",
      "filename" : "AppIcon.png"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

### 4. Ajouter l'icône

1. Placez votre logo **1024x1024** dans le dossier `AppIcon.appiconset/`
2. Nommez-le `AppIcon.png` (ou mettez le nom exact dans `Contents.json`)
3. Dans Xcode, glissez-déposez l'image dans l'emplacement Watch App Icon

## 🔧 Configuration automatique via script (Optionnel)

Si vous préférez configurer directement via les fichiers, voici ce que vous pouvez faire :

### Pour iOS/iPadOS

1. Placez votre logo dans `Shoply/Assets.xcassets/AppIcon.appiconset/`
2. Nommez-le `AppIcon-1024.png`
3. Mettez à jour `Contents.json` :

```json
{
  "images" : [
    {
      "filename" : "AppIcon-1024.png",
      "idiom" : "universal",
      "platform" : "ios",
      "size" : "1024x1024"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
```

### Pour watchOS

1. Créez le dossier `ShoplyWatchExtension/Assets.xcassets/AppIcon.appiconset/` s'il n'existe pas
2. Placez votre logo `AppIcon.png` (1024x1024) dans ce dossier
3. Créez/Modifiez `Contents.json` comme montré ci-dessus

## ✅ Vérification

### 1. Dans Xcode

Après avoir ajouté les icônes :
1. **Sélectionnez votre target** (Shoply pour iOS, ShoplyWatchExtension pour Watch)
2. Allez dans **General** > **App Icons and Launch Screen**
3. Vérifiez que **AppIcon** est sélectionné dans **App Icon Source**
4. Vous devriez voir votre icône apparaître dans l'aperçu

### 2. Test sur appareil/simulateur

1. **Compilez et lancez** l'application
2. **Vérifiez** que le logo apparaît correctement :
   - Sur l'écran d'accueil de l'iPhone/iPad
   - Sur l'Apple Watch (si configuré)
3. **Testez** les différentes tailles d'affichage

## 🎨 Recommandations de Design

### Conseils pour créer un bon logo d'application

1. **Simplicité** : Un logo trop complexe ne sera pas lisible en petite taille
2. **Contraste** : Assurez un bon contraste avec les fonds clairs et sombres
3. **Padding** : Laissez environ 10-15% d'espace autour du logo (pas de texte trop près des bords)
4. **Formes simples** : Les formes géométriques simples sont plus reconnaissables en petite taille
5. **Couleurs vives** : Utilisez des couleurs qui se distinguent bien

### Tailles réelles sur appareil

- **iPhone** : Affiché à environ 60x60 points (180x180 pixels sur Retina)
- **iPad** : Affiché à environ 76x76 points (152x152 pixels)
- **Apple Watch** : Affiché à environ 80x80 points sur Watch Series 9+
- Mais vous devez fournir **1024x1024** car iOS génère automatiquement toutes les tailles

## 🚨 Problèmes courants

### L'icône n'apparaît pas

1. Vérifiez que le fichier est bien dans le bon dossier
2. Vérifiez que le nom dans `Contents.json` correspond au nom du fichier
3. **Nettoyez le build** : Product > Clean Build Folder (Cmd+Shift+K)
4. **Supprimez l'app** du simulateur et réinstallez-la

### L'icône est pixelisée

1. Assurez-vous d'utiliser une image 1024x1024 pixels minimum
2. Vérifiez que le format est PNG (pas JPG)
3. Évitez les images compressées avec perte de qualité

### L'icône est coupée

1. Vérifiez que votre logo a un padding suffisant autour
2. iOS applique automatiquement un arrondi, donc gardez les éléments importants centrés
3. Testez sur différents appareils pour voir comment ça apparaît

## 📚 Ressources supplémentaires

- [Apple Human Interface Guidelines - App Icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
- [iOS App Icon Generator](https://www.appicon.co/) - Outil pour générer toutes les tailles
- [Watch App Icon Guidelines](https://developer.apple.com/design/human-interface-guidelines/components/system-experiences/watch-faces)

## 🎯 Résumé rapide

1. **Préparez** un logo 1024x1024 PNG
2. **Ouvrez** `Assets.xcassets` > `AppIcon` dans Xcode
3. **Glissez-déposez** votre logo dans l'emplacement 1024x1024
4. **Pour Watch** : Créez `ShoplyWatchExtension/Assets.xcassets/AppIcon.appiconset/` et ajoutez l'icône
5. **Testez** sur simulateur/appareil
6. **Profitez** de votre nouveau logo ! 🎉

