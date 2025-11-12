# Adaptation Android One UI 7

Ce document décrit les adaptations spécifiques pour Android 15 avec One UI 7.

## 🎨 Design System One UI 7

### Couleurs

One UI 7 utilise une palette de couleurs spécifique :

#### Mode Clair
- **Background** : `#FFFFFF`
- **Primary Text** : `#000000`
- **Secondary Text** : `#6E6E73`
- **Card Background** : `#FFFFFF`
- **Card Border** : `#E5E5EA`
- **Separator** : `#C6C6C8`

#### Mode Sombre
- **Background** : `#1C1C1E`
- **Primary Text** : `#FFFFFF`
- **Secondary Text** : `#AEAEB2`
- **Card Background** : `#2C2C2E`
- **Card Border** : `#38383A`
- **Separator** : `#38383A`

### Typographie

One UI 7 utilise des tailles de police légèrement différentes :

- **Large Title** : 32sp (au lieu de 34pt iOS)
- **Title** : 24sp (au lieu de 28pt iOS)
- **Title2** : 20sp (au lieu de 22pt iOS)
- **Headline** : 16sp (au lieu de 17pt iOS)
- **Body** : 16sp (au lieu de 17pt iOS)

### Espacements

Les espacements sont identiques à iOS :
- xs: 4dp
- sm: 8dp
- md: 16dp
- lg: 24dp
- xl: 32dp
- xxl: 40dp

### Rayons de coins

- sm: 8dp
- md: 12dp
- lg: 16dp
- xl: 20dp

## 🔧 Implémentation

Le design system détecte automatiquement la plateforme et applique les styles appropriés :

```typescript
import { Platform } from 'react-native';
import { AppColors } from './theme/DesignSystem';

// Les couleurs sont automatiquement adaptées
const backgroundColor = Platform.select({
  ios: AppColors.background,
  android: AppColors.background, // One UI 7
});
```

## 📱 Composants adaptés

Tous les composants utilisent `Platform.select()` pour adapter automatiquement :
- **Card** : Bordures et ombres adaptées
- **Button** : Styles One UI 7
- **Text** : Tailles de police adaptées
- **Spacing** : Conversion automatique pt → dp

## 🎯 Principes One UI 7

1. **Simplicité** : Design épuré et minimaliste
2. **Cohérence** : Respect des guidelines Material Design 3
3. **Accessibilité** : Contraste élevé et tailles lisibles
4. **Performance** : Animations fluides et réactives

## 🔄 Différences iOS vs Android

| Élément | iOS | Android One UI 7 |
|---------|-----|-------------------|
| Fond clair | `#FFFFFF` | `#FFFFFF` |
| Fond sombre | `#000000` | `#1C1C1E` |
| Texte secondaire clair | `#4D4D4D` | `#6E6E73` |
| Texte secondaire sombre | `#B3B3B3` | `#AEAEB2` |
| Carte sombre | `#0D0D0D` | `#2C2C2E` |

## 📝 Notes

- Les couleurs sont définies dans `src/theme/DesignSystem.ts`
- Le thème est géré par `ThemeContext` qui détecte automatiquement le mode sombre/clair
- Les adaptations sont transparentes pour les développeurs

