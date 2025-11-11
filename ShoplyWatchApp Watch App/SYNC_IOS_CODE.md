# Code de Synchronisation pour l'App iOS

## 🔧 À Ajouter dans DataManager.swift

Ajoutez cette méthode pour synchroniser le profil utilisateur vers l'App Group :

```swift
// Dans DataManager.swift
func syncUserProfileToWatch() {
    guard let sharedDefaults = UserDefaults(suiteName: "group.com.william.shoply") else {
        print("App Group non configuré")
        return
    }
    
    if let profile = loadUserProfile() {
        // Créer le profil Watch simplifié
        let watchProfile = WatchUserProfile(
            firstName: profile.firstName,
            isConfigured: !profile.firstName.isEmpty && profile.gender != .notSpecified
        )
        
        if let encoded = try? JSONEncoder().encode(watchProfile) {
            sharedDefaults.set(encoded, forKey: "user_profile")
            sharedDefaults.synchronize()
            print("✅ Profil synchronisé vers Watch")
        }
    }
}
```

## 📍 Où Appeler la Synchronisation

Appelez `syncUserProfileToWatch()` dans ces endroits :

1. **Après l'onboarding** (dans `OnboardingScreen.swift`) :
```swift
dataManager.saveUserProfile(profile)
dataManager.syncUserProfileToWatch() // ← Ajouter cette ligne
```

2. **Dans `saveUserProfile`** (dans `DataManager.swift`) :
```swift
func saveUserProfile(_ profile: UserProfile) {
    if let encoded = try? JSONEncoder().encode(profile) {
        UserDefaults.standard.set(encoded, forKey: "userProfile")
        // ...
        syncUserProfileToWatch() // ← Ajouter cette ligne
    }
}
```

3. **Au démarrage de l'app** (dans `ShoplyApp.swift`) :
```swift
.onAppear {
    // ...
    dataManager.syncUserProfileToWatch() // ← Ajouter cette ligne
}
```

## ⚠️ Important

- L'App Group `group.com.william.shoply` doit être configuré dans les capabilities de l'app iOS
- La synchronisation doit être faite après chaque modification du profil
- Utilisez `synchronize()` pour forcer l'écriture immédiate

