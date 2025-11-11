# Guide de Synchronisation iOS → Watch

## 📱 Synchronisation des Données

Pour que l'application Watch affiche toutes les données de l'iPhone, vous devez synchroniser les données via App Groups.

### Configuration dans l'App iOS

Ajoutez ce code dans `DataManager.swift` ou créez une méthode de synchronisation :

```swift
func syncToWatch() {
    guard let sharedDefaults = UserDefaults(suiteName: "group.com.william.shoply") else {
        return
    }
    
    // 1. Profil utilisateur
    if let profile = loadUserProfile() {
        let watchProfile = WatchUserProfile(
            firstName: profile.firstName,
            isConfigured: !profile.firstName.isEmpty && profile.gender != .notSpecified
        )
        if let encoded = try? JSONEncoder().encode(watchProfile) {
            sharedDefaults.set(encoded, forKey: "user_profile")
        }
    }
    
    // 2. Garde-robe
    let wardrobeItems = loadWardrobeItems()
    let watchWardrobe = wardrobeItems.map { item in
        WatchWardrobeItem(
            id: item.id,
            name: item.name,
            category: mapCategory(item.category),
            color: item.color,
            brand: item.brand,
            isFavorite: item.isFavorite
        )
    }
    if let encoded = try? JSONEncoder().encode(watchWardrobe) {
        sharedDefaults.set(encoded, forKey: "wardrobe_items")
    }
    
    // 3. Historique des outfits
    // Convertir les outfits en WatchOutfitHistoryItem
    // ...
    
    // 4. Wishlist
    // Convertir les wishlist items
    // ...
    
    // 5. Conversations IA
    // Convertir les conversations
    // ...
    
    sharedDefaults.synchronize()
}
```

### Clés de Synchronisation

Les données sont synchronisées avec ces clés :
- `user_profile` : Profil utilisateur (prénom, configuration)
- `wardrobe_items` : Liste des vêtements
- `outfit_history` : Historique des outfits
- `wishlist_items` : Articles de la wishlist
- `chat_conversations` : Conversations avec l'IA
- `current_weather` : Météo actuelle

### Quand Synchroniser

Synchronisez les données :
- Au démarrage de l'app iOS
- Après chaque modification (ajout vêtement, nouvelle conversation, etc.)
- Lors de la sauvegarde d'un outfit
- Lors de l'ajout à la wishlist

### Exemple d'Implémentation

```swift
// Dans DataManager.swift
func saveWardrobeItems(_ items: [WardrobeItem]) {
    // Sauvegarder normalement
    if let encoded = try? JSONEncoder().encode(items) {
        UserDefaults.standard.set(encoded, forKey: "wardrobeItems")
    }
    
    // Synchroniser avec Watch
    syncToWatch()
}
```

## ✅ Vérification

L'application Watch vérifie automatiquement si l'app iOS est configurée en vérifiant :
- Le profil utilisateur existe
- Le prénom n'est pas vide
- L'onboarding est complété

Si non configuré, l'écran `WatchConfigurationCheckView` s'affiche.

