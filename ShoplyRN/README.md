# Shoply React Native

Application React Native pour iOS et Android 15 (One UI 7) - Migration de l'application iOS native Shoply.

## 🎯 Fonctionnalités

- **Design identique iOS** : Conservation du design minimaliste noir et blanc
- **Support Android One UI 7** : Adaptation pour Android 15 avec One UI 7
- **Gestion de garde-robe** : Ajoutez, modifiez et organisez vos vêtements
- **Sélection intelligente d'outfits** : IA avancée pour générer des outfits adaptés
- **Chat IA** : Interface de chat avec Shoply AI
- **Historique et favoris** : Suivez vos outfits portés et favoris

## 🚀 Installation

### Prérequis

- Node.js >= 20
- React Native CLI
- Xcode (pour iOS)
- Android Studio (pour Android)

### Installation des dépendances

```bash
cd ShoplyRN
npm install
```

### iOS

```bash
cd ios
pod install
cd ..
npm run ios
```

### Android

```bash
npm run android
```

## 📁 Structure du Projet

```
ShoplyRN/
├── src/
│   ├── components/          # Composants réutilisables
│   │   ├── Card.tsx
│   │   └── Button.tsx
│   ├── screens/             # Écrans de l'application
│   │   └── HomeScreen.tsx
│   ├── services/            # Services métier
│   ├── models/              # Modèles de données
│   │   ├── UserProfile.ts
│   │   ├── WardrobeItem.ts
│   │   └── Outfit.ts
│   ├── theme/               # Design system
│   │   ├── DesignSystem.ts
│   │   └── ThemeContext.tsx
│   ├── utils/               # Utilitaires
│   │   └── storage.ts
│   └── navigation/          # Navigation
│       └── AppNavigator.tsx
├── App.tsx
└── package.json
```

## 🎨 Design System

Le design system supporte :
- **iOS** : Design minimaliste noir et blanc identique à l'app native
- **Android One UI 7** : Adaptation avec les couleurs et styles One UI 7

### Couleurs

- **Fond** : Blanc (clair) / Noir (sombre)
- **Textes** : Noir (clair) / Blanc (sombre)
- **Boutons** : Noir (clair) / Blanc (sombre)
- **Cartes** : Fond adaptatif selon le thème

### Typographie

- Large Title : 34pt, Bold
- Title : 28pt, Bold
- Title2 : 22pt, Semibold
- Headline : 17pt, Semibold
- Body : 17pt, Regular
- Caption : 12pt, Regular

## 📱 Écrans

### Écran d'accueil (HomeScreen)

- En-tête avec photo de profil et salutation
- Carte principale "Sélection Intelligente"
- Accès rapide aux fonctionnalités
- Bouton chat flottant

## 🔄 Migration depuis iOS

Les fonctionnalités suivantes sont en cours de migration :

- ✅ Structure de base du projet
- ✅ Design system (iOS + Android One UI 7)
- ✅ Modèles de données
- ✅ Persistance (AsyncStorage)
- ✅ Écran d'accueil
- ⏳ Services (IA, météo, etc.)
- ⏳ Autres écrans
- ⏳ Navigation complète

## 🛠️ Technologies

- **React Native** : 0.82.1
- **React Navigation** : Navigation native
- **AsyncStorage** : Persistance des données
- **TypeScript** : Typage statique
- **React Native Safe Area Context** : Gestion des zones sûres

## 📝 Notes

- Le design iOS est conservé tel quel
- Android utilise One UI 7 avec adaptation des couleurs et espacements
- Les polices sont adaptées selon la plateforme

## 👤 Créateur

**William RAUWENS OLIVER**
