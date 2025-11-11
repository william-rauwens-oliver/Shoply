# Guide de Diagnostic - App Group Synchronisation

## Problème
L'application Apple Watch ne détecte pas la configuration depuis l'iPhone, même si l'app iOS est configurée.

## Vérifications à faire dans Xcode

### 1. Vérifier l'App Group pour le target iOS (Shoply)

1. Ouvrez Xcode
2. Sélectionnez le projet dans le navigateur
3. Sélectionnez le target **Shoply** (iOS)
4. Allez dans l'onglet **Signing & Capabilities**
5. Vérifiez que la capability **App Groups** est présente
6. Si elle n'est pas présente :
   - Cliquez sur **+ Capability**
   - Recherchez **App Groups** et ajoutez-la
7. Vérifiez que `group.com.william.shoply` est **coché** dans la liste
8. Si ce n'est pas le cas, cochez la case

### 2. Vérifier l'App Group pour le target Watch App

1. Sélectionnez le target **ShoplyWatchApp Watch App**
2. Allez dans l'onglet **Signing & Capabilities**
3. Vérifiez que la capability **App Groups** est présente
4. Vérifiez que `group.com.william.shoply` est **coché**

### 3. Nettoyer et reconstruire

1. Dans Xcode : **Product > Clean Build Folder** (⇧⌘K)
2. Fermez Xcode complètement
3. Rouvrez Xcode
4. Recompilez le projet
5. **Désinstallez** les apps iOS et Watch de vos appareils
6. **Réinstallez** les apps depuis Xcode

### 4. Vérifier les logs

Lancez l'app iOS et regardez les logs dans la console Xcode. Vous devriez voir :

```
📱 iOS: ========== DÉBUT SYNCHRONISATION ==========
✅ iOS: App Group accessible
📦 iOS: Données encodées - Taille: XX bytes
💾 iOS: Données écrites dans UserDefaults avec la clé 'user_profile'
✅ iOS: Données retrouvées dans App Group
✅ iOS: Profil décodé avec succès
```

Si vous voyez :
```
❌ iOS: CRITIQUE - Impossible d'accéder à l'App Group
```
→ L'App Group n'est pas activé dans Xcode

## Vérification manuelle

Vous pouvez vérifier si l'App Group fonctionne en ajoutant ce code temporaire dans l'app iOS :

```swift
// Dans ShoplyApp.swift, dans onAppear
if let sharedDefaults = UserDefaults(suiteName: "group.com.william.shoply") {
    print("✅ App Group accessible")
    sharedDefaults.set("test", forKey: "test_key")
    if let value = sharedDefaults.string(forKey: "test_key") {
        print("✅ Écriture/lecture réussie: \(value)")
    }
} else {
    print("❌ App Group non accessible")
}
```

## Problèmes courants

1. **App Group non activé dans Xcode** : Même si les fichiers `.entitlements` existent, il faut activer la capability dans Xcode
2. **Identifiants différents** : Vérifiez que les deux targets utilisent exactement `group.com.william.shoply`
3. **Cache Xcode** : Nettoyez le build folder et réinstallez les apps
4. **Profils de provisioning** : Assurez-vous que les profils de provisioning incluent l'App Group

