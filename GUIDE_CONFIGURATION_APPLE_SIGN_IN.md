# Guide de Configuration Apple Sign In

## Problème : Erreur 1000 - Apple Sign In non disponible

Si vous voyez l'erreur "Apple Sign In n'est pas configuré", suivez ces étapes :

## Étapes de Configuration dans Xcode

### 1. Ouvrir le Projet dans Xcode
   - Ouvrez `Shoply.xcodeproj` dans Xcode

### 2. Sélectionner le Target
   - Dans le navigateur de projet (panneau gauche), cliquez sur le projet "Shoply"
   - Sélectionnez le target "Shoply" (pas le widget extension)

### 3. Ajouter la Capability "Sign in with Apple"
   - Cliquez sur l'onglet **"Signing & Capabilities"** en haut
   - Cliquez sur le bouton **"+ Capability"** (en haut à gauche, à côté de "Signing & Capabilities")
   - Recherchez **"Sign in with Apple"** dans la liste
   - Double-cliquez ou cliquez sur **"+ Add"** pour l'ajouter

### 4. Vérifier le Bundle Identifier
   - Assurez-vous qu'un **Bundle Identifier** est configuré (ex: `com.votreNom.Shoply`)
   - Il doit être unique et correspondre à un App ID dans votre compte développeur Apple

### 5. Vérifier le Compte de Développement
   - Dans l'onglet "Signing & Capabilities"
   - Vérifiez que **"Automatically manage signing"** est coché
   - Ou sélectionnez manuellement votre équipe de développement

### 6. Nettoyer et Reconstruire
   - Menu **Product** → **Clean Build Folder** (⇧⌘K)
   - Puis **Product** → **Build** (⌘B)

## Test sur Appareil Physique

Apple Sign In fonctionne mieux sur un appareil physique que sur le simulateur :
- Connectez votre iPhone/iPad via USB
- Sélectionnez l'appareil dans Xcode (en haut à côté du bouton Run)
- Lancez l'application

## Vérification

Après configuration, l'application devrait :
1. Afficher le popup Apple Sign In au clic sur le bouton
2. Permettre l'authentification avec Face ID / Touch ID / Code
3. Ne plus afficher l'erreur 1000

## Logs de Débogage

Si le problème persiste, vérifiez la console Xcode pour voir les logs :
- `🔐 Tentative de connexion Apple Sign In...`
- `✅ Requête créée...`
- `✅ Contrôleur créé...`
- `✅ Fenêtre obtenue...`
- `🚀 Lancement de performRequests()...`

Si vous voyez une erreur dans les logs, notez le code d'erreur et la description.

## Problèmes Courants

### Erreur 1000
- **Cause** : Capability "Sign in with Apple" non activée
- **Solution** : Suivre les étapes 1-3 ci-dessus

### Popup ne s'affiche pas
- **Cause** : Problème de fenêtre/presentationAnchor
- **Solution** : Tester sur appareil physique plutôt que simulateur

### "Not Handled"
- **Cause** : Bundle Identifier mal configuré
- **Solution** : Vérifier que le Bundle ID est valide et unique

