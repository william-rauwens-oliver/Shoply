# Guide de débogage Apple Sign In

## 🔍 Vérifier si le popup s'affiche

Si le popup Apple Sign In ne s'affiche pas, voici comment déboguer :

### 1. Vérifier les logs Xcode

Ouvrez la console Xcode et cherchez ces messages :
- `🔐 Tentative de connexion Apple Sign In...` - Le bouton a été cliqué
- `✅ Requête créée avec scopes: fullName, email` - La requête est créée
- `✅ Contrôleur créé avec delegate et presentationContextProvider` - Le contrôleur est prêt
- `🚀 Lancement de performRequests()...` - La requête est lancée
- `✅ performRequests() appelé` - La méthode a été appelée

### 2. Vérifier la configuration dans Xcode

1. **Ouvrez Xcode**
2. **Sélectionnez le projet** (icône bleue en haut)
3. **Sélectionnez le target "Shoply"** (pas le widget)
4. **Allez dans l'onglet "Signing & Capabilities"**
5. **Vérifiez que "Sign in with Apple" apparaît dans la liste**

Si elle n'apparaît pas :
- Cliquez sur **"+ Capability"**
- Cherchez **"Sign in with Apple"**
- Ajoutez-la

### 3. Vérifier le fichier Entitlements

Le fichier `Shoply/Shoply.entitlements` doit contenir :
```xml
<key>com.apple.developer.applesignin</key>
<array>
    <string>Default</string>
</array>
```

### 4. Vérifier le Bundle Identifier

Dans Xcode → Target "Shoply" → Signing & Capabilities :
- Le **Bundle Identifier** doit être configuré
- Un **Team** doit être sélectionné (même gratuit)

### 5. Nettoyer et reconstruire

1. Menu **Product** → **Clean Build Folder** (⇧⌘K)
2. Fermez Xcode complètement
3. Rouvrez Xcode
4. Menu **Product** → **Build** (⌘B)
5. Relancez l'application

### 6. Vérifier sur un appareil physique

Apple Sign In **ne fonctionne PAS sur le simulateur** pour certaines configurations. Testez sur un **iPhone/iPad réel**.

### 7. Erreurs courantes

#### Erreur 1000
- **Cause** : Capability "Sign in with Apple" non configurée
- **Solution** : Ajoutez la capability dans Xcode (Signing & Capabilities → + Capability → Sign in with Apple)

#### Le popup ne s'affiche pas du tout
- **Cause possible** : Le contrôleur est libéré avant l'affichage
- **Solution** : J'ai ajouté une référence au contrôleur pour éviter sa libération

#### "The operation couldn't be completed"
- **Cause** : Configuration manquante ou Team non configuré
- **Solution** : Vérifiez que votre Team Apple Developer est configuré dans Xcode

### 8. Tester la connexion

Si les logs montrent que `performRequests()` est appelé mais rien ne se passe :
1. Vérifiez que vous êtes sur un **appareil réel** (pas le simulateur)
2. Vérifiez que votre **Apple ID est configuré** dans Réglages → [Votre nom]
3. Vérifiez que **iCloud est activé**

### 9. Console de débogage

Dans Xcode, ouvrez la console (View → Debug Area → Activate Console) et filtrez avec "Apple Sign In" pour voir tous les logs détaillés.

### 10. Réinitialiser l'état

Si vous voulez tester à nouveau :
1. Supprimez l'application de votre appareil
2. Dans Xcode, nettoyez le build (⇧⌘K)
3. Recompilez et relancez

## ✅ Checklist

- [ ] Le fichier `Shoply.entitlements` contient `com.apple.developer.applesignin`
- [ ] La capability "Sign in with Apple" est ajoutée dans Xcode
- [ ] Un Team Apple Developer est configuré
- [ ] Le Bundle Identifier est correct
- [ ] Vous testez sur un appareil physique (pas simulateur)
- [ ] Votre Apple ID est configuré dans Réglages iOS
- [ ] iCloud est activé
- [ ] Les logs Xcode montrent que `performRequests()` est appelé

