# Instructions Manuelles pour Activer Sign in with Apple

## Problème : "Sign in with Apple" n'apparaît pas dans la liste des capabilities

Si vous ne trouvez pas "Sign in with Apple" dans la liste des capabilities, suivez ces étapes **manuellement** :

## Méthode 1 : Ajouter le fichier Entitlements dans Xcode

### Étape 1 : Ouvrir Xcode
1. Ouvrez `Shoply.xcodeproj` dans Xcode

### Étape 2 : Ajouter le fichier Entitlements au projet
1. Dans le navigateur de projet (panneau gauche), faites un **clic droit** sur le dossier **"Shoply"** (le dossier bleu)
2. Sélectionnez **"Add Files to Shoply..."**
3. Naviguez jusqu'au fichier `Shoply/Shoply.entitlements` que je viens de créer
4. **IMPORTANT** : Cochez la case **"Copy items if needed"**
5. Cochez **"Add to targets: Shoply"** (pas le widget)
6. Cliquez sur **"Add"**

### Étape 3 : Configurer le fichier Entitlements dans les Build Settings
1. Sélectionnez le projet **"Shoply"** dans le navigateur (icône bleue en haut)
2. Sélectionnez le target **"Shoply"** (pas le widget)
3. Cliquez sur l'onglet **"Build Settings"** (pas "Signing & Capabilities")
4. Dans la barre de recherche en haut, tapez : **"code sign entitlements"**
5. Trouvez la ligne **"Code Signing Entitlements"**
6. Double-cliquez dans la colonne **"Value"** pour le mode Debug
7. Tapez : `Shoply/Shoply.entitlements`
8. Répétez pour le mode Release

### Étape 4 : Vérifier que le fichier Entitlements contient la bonne clé
Le fichier `Shoply/Shoply.entitlements` doit contenir :
```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

### Étape 5 : Nettoyer et Reconstruire
1. Menu **Product** → **Clean Build Folder** (⇧⌘K)
2. Menu **Product** → **Build** (⌘B)

## Méthode 2 : Via le Developer Portal (si vous avez un compte payant)

Si vous avez un compte développeur Apple payant :

1. Allez sur [developer.apple.com](https://developer.apple.com)
2. Connectez-vous avec votre compte
3. Allez dans **Certificates, Identifiers & Profiles**
4. Sélectionnez **Identifiers**
5. Trouvez ou créez votre App ID (ex: `William.Shoply`)
6. Cliquez dessus pour l'éditer
7. Cochez **"Sign In with Apple"**
8. Cliquez sur **Save**
9. Retournez dans Xcode et nettoyez/reconstruisez

## Vérification

Après avoir ajouté le fichier entitlements, vérifiez que :
- Le fichier `Shoply.entitlements` apparaît dans le navigateur Xcode sous le dossier "Shoply"
- Dans "Build Settings", "Code Signing Entitlements" pointe vers `Shoply/Shoply.entitlements`
- Le fichier contient bien la clé `com.apple.developer.applesignin`

## Si ça ne fonctionne toujours pas

1. **Vérifiez votre compte développeur** : Apple Sign In nécessite parfois un compte développeur payant pour certaines configurations
2. **Testez sur un appareil physique** : Le simulateur peut avoir des limitations
3. **Vérifiez les logs** : Regardez la console Xcode pour voir les erreurs exactes

## Alternative : Désactiver temporairement Apple Sign In

Si vous ne pouvez pas activer Apple Sign In pour l'instant, l'application fonctionne normalement sans. Vous pouvez :
- Cliquer sur "Passer cette étape" dans l'écran de connexion
- Utiliser l'app normalement
- Activer Apple Sign In plus tard quand vous aurez configuré votre compte développeur

