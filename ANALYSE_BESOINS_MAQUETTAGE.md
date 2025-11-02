# Analyse des Besoins et Maquettage - Shoply

**Projet** : Shoply - Application de Sélection d'Outfits  
**Version** : 1.0.0  
**Date** : 01/11/2025  
**Auteur** : William

## 📋 Conformité RNCP37873

Cette documentation répond aux exigences du **Bloc 2 - Concevoir et développer une application sécurisée organisée en couches** :
- ✅ Analyser les besoins et maquetter une application
- ✅ Définir l'architecture logicielle d'une application

## 🎯 Analyse des Besoins

### Contexte

Shoply est une application iOS permettant aux utilisateurs de choisir leur tenue du jour en fonction de leur humeur et des conditions météorologiques. L'application doit être intuitive, accessible et respecter les standards de qualité professionnels.

### Besoins Fonctionnels

#### BF-001 : Sélection par Humeur
**Description** : L'utilisateur doit pouvoir sélectionner son humeur du jour  
**Priorité** : Élevée  
**Critères d'acceptation** :
- 6 humeurs disponibles : Énergique, Calme, Confiant, Détendu, Professionnel, Créatif
- Interface intuitive avec icônes représentatives
- Sélection facile en un tap

#### BF-002 : Sélection par Météo
**Description** : L'utilisateur doit pouvoir choisir les conditions météorologiques  
**Priorité** : Élevée  
**Critères d'acceptation** :
- 5 types : Ensoleillé, Nuageux, Pluvieux, Froid, Chaud
- Affichage visuel des conditions
- Intégration avec API météo (optionnel)

#### BF-003 : Affichage des Outfits
**Description** : Affichage d'outfits adaptés selon les critères sélectionnés  
**Priorité** : Élevée  
**Critères d'acceptation** :
- Liste des outfits filtrés
- Détails complets pour chaque outfit
- Niveaux de confort et de style affichés

#### BF-004 : Gestion des Favoris
**Description** : Ajout/suppression d'outfits aux favoris  
**Priorité** : Moyenne  
**Critères d'acceptation** :
- Persistance des favoris
- Accès rapide depuis l'écran d'accueil
- Synchronisation iCloud (optionnel)

#### BF-005 : Recherche
**Description** : Recherche textuelle parmi tous les outfits  
**Priorité** : Moyenne  
**Critères d'acceptation** :
- Recherche instantanée
- Filtrage en temps réel
- Suggestions (optionnel)

#### BF-006 : Gestion du Profil Utilisateur
**Description** : Création et modification du profil utilisateur  
**Priorité** : Élevée  
**Critères d'acceptation** :
- Âge, genre, préférences
- Photo de profil (optionnel)
- Sauvegarde automatique

#### BF-007 : Gestion de la Garde-robe
**Description** : Ajout, modification et suppression de vêtements  
**Priorité** : Élevée  
**Critères d'acceptation** :
- Photos des vêtements
- Catégories (haut, bas, chaussures, accessoires)
- Couleurs, matières, saisons

#### BF-008 : Chat IA pour Conseils
**Description** : Assistant IA pour conseils sur les outfits  
**Priorité** : Moyenne  
**Critères d'acceptation** :
- Chat avec Shoply AI (local)
- Intégration ChatGPT/Gemini (optionnel)
- Historique des conversations

### Besoins Non-Fonctionnels

#### BNF-001 : Performance
**Description** : Application rapide et fluide  
**Critères** :
- Temps de lancement < 2 secondes
- Interface fluide (60 FPS)
- Consommation mémoire < 50 MB

#### BNF-002 : Sécurité
**Description** : Conformité RGPD et sécurité des données  
**Critères** :
- Consentement explicite
- Données stockées localement
- Chiffrement des données sensibles

#### BNF-003 : Accessibilité
**Description** : Conformité RGAA (WCAG 2.1 Niveau AA)  
**Critères** :
- Support VoiceOver complet
- Contraste suffisant (4.5:1)
- Tailles de police accessibles (≥ 16pt)

#### BNF-004 : Maintenabilité
**Description** : Code propre et documenté  
**Critères** :
- Architecture multicouche
- Code documenté
- Tests unitaires (≥ 80% couverture)

## 📐 Maquettage

### Structure de Navigation

```
┌─────────────────────────────────────────┐
│            ÉCRAN D'ACCUEIL              │
│  - Bonjour, [Nom]                       │
│  - Météo du jour                        │
│  - Bouton "Sélectionner mon outfit"     │
│  - Favoris                              │
│  - Navigation (Garde-robe, Profil)     │
└───────────┬─────────────────────────────┘
            │
    ┌───────┴───────┬───────────┬───────────┐
    │               │           │           │
┌───▼────┐   ┌──────▼───┐  ┌───▼────┐  ┌───▼────┐
│ Sélect.│   │Garde-robe│  │ Profil│  │Favoris │
│ Outfit │   │          │  │        │  │        │
└───┬────┘   └──────┬───┘  └───┬────┘  └───┬────┘
    │               │           │           │
└───────────────────┴─────────┴───────────┘
```

### Maquettes des Écrans Principaux

#### Écran d'Accueil (HomeScreen)

```
┌─────────────────────────────────────┐
│  [🌞] Bonjour, William              │
│                                     │
│  📅 Lundi 1er novembre 2025        │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  ☀️ Ensoleillé • 22°C         │ │
│  └───────────────────────────────┘ │
│                                     │
│  ┌───────────────────────────────┐ │
│  │  🎯 Sélectionner mon outfit   │ │
│  │     →                        │ │
│  └───────────────────────────────┘ │
│                                     │
│  ⭐ Favoris                         │
│  ┌────┐ ┌────┐ ┌────┐            │
│  │ 📷 │ │ 📷 │ │ 📷 │            │
│  └────┘ └────┘ └────┘            │
│                                     │
│  [🏠] [👔] [👤] [⚙️]              │
└─────────────────────────────────────┘
```

#### Écran de Sélection (MoodSelectionScreen)

```
┌─────────────────────────────────────┐
│  ← Choisir mon humeur               │
│                                     │
│  Comment vous sentez-vous ?         │
│                                     │
│  ┌──────┐ ┌──────┐ ┌──────┐      │
│  │ ⚡️  │ │ 😌  │ │ 💪  │      │
│  │Énerg.│ │ Calme│ │Conf. │      │
│  └──────┘ └──────┘ └──────┘      │
│                                     │
│  ┌──────┐ ┌──────┐ ┌──────┐      │
│  │ 🧘  │ │ 👔  │ │ 🎨  │      │
│  │Dét. │ │Prof.│ │Créa.│      │
│  └──────┘ └──────┘ └──────┘      │
│                                     │
│         [Continuer →]               │
└─────────────────────────────────────┘
```

#### Écran de Sélection Météo (WeatherSelectionScreen)

```
┌─────────────────────────────────────┐
│  ← Choisir la météo                 │
│                                     │
│  Quelle est la météo ?              │
│                                     │
│  ┌──────┐ ┌──────┐ ┌──────┐      │
│  │ ☀️  │ │ ☁️  │ │ 🌧️  │      │
│  │Ensol.│ │Nuag. │ │Pluv. │      │
│  └──────┘ └──────┘ └──────┘      │
│                                     │
│  ┌──────┐ ┌──────┐                │
│  │ ❄️  │ │ 🔥  │                │
│  │ Froid│ │Chaud │                │
│  └──────┘ └──────┘                │
│                                     │
│         [Voir les outfits →]        │
└─────────────────────────────────────┘
```

#### Écran de Liste des Outfits

```
┌─────────────────────────────────────┐
│  ← Outfits pour Énergique + Ensoleillé│
│                                     │
│  ┌─────────────────────────────────┐ │
│  │ 📷 Outfit 1                     │ │
│  │    Casuel • Confortable         │ │
│  │    ⭐ 4.5 | 💪 Énergique        │ │
│  │              [Voir détails →]   │ │
│  └─────────────────────────────────┘ │
│                                     │
│  ┌─────────────────────────────────┐ │
│  │ 📷 Outfit 2                     │ │
│  │    Élégant • Confiant           │ │
│  │    ⭐ 4.8 | 💪 Énergique        │ │
│  │              [Voir détails →]   │ │
│  └─────────────────────────────────┘ │
└─────────────────────────────────────┘
```

#### Écran Profil Utilisateur

```
┌─────────────────────────────────────┐
│  ← Mon Profil                       │
│                                     │
│  ┌──────┐                           │
│  │  👤  │  William                  │
│  └──────┘                            │
│                                     │
│  📝 Informations personnelles       │
│  ┌─────────────────────────────────┐ │
│  │ Âge : 25 ans                     │ │
│  │ Genre : Homme                    │ │
│  └─────────────────────────────────┘ │
│                                     │
│  ⚙️ Préférences                      │
│  ┌─────────────────────────────────┐ │
│  │ Mode sombre : Oui               │ │
│  │ Langue : Français               │ │
│  └─────────────────────────────────┘ │
│                                     │
│         [Modifier]                  │
└─────────────────────────────────────┘
```

## 🏗️ Architecture Logicielle

### Diagramme d'Architecture Multicouche

```
┌─────────────────────────────────────────────────────────────┐
│                    COUCHE PRÉSENTATION                     │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐      │
│  │  HomeScreen  │ │ MoodScreen   │ │ OutfitScreen│      │
│  └──────────────┘ └──────────────┘ └──────────────┘      │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐      │
│  │ ProfileScreen│ │SettingsScreen │ │ChatAIScreen  │      │
│  └──────────────┘ └──────────────┘ └──────────────┘      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ @EnvironmentObject
                         │ @StateObject
                         │
┌────────────────────────▼────────────────────────────────────┐
│                     COUCHE MÉTIER                           │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐      │
│  │OutfitService │ │WardrobeService│ │OpenAIService │      │
│  └──────────────┘ └──────────────┘ └──────────────┘      │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐      │
│  │GeminiService │ │WeatherService │ │DataManager   │      │
│  └──────────────┘ └──────────────┘ └──────────────┘      │
└────────────────────────┬────────────────────────────────────┘
                         │
                         │ Protocol-based
                         │
┌────────────────────────▼────────────────────────────────────┐
│                    COUCHE DONNÉES                           │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐      │
│  │SQLDatabase   │ │NoSQLDatabase │ │CloudKit      │      │
│  │Service       │ │Service       │ │Service       │      │
│  └──────────────┘ └──────────────┘ └──────────────┘      │
│  ┌──────────────┐ ┌──────────────┐                       │
│  │Core Data     │ │UserDefaults  │                       │
│  └──────────────┘ └──────────────┘                       │
└─────────────────────────────────────────────────────────────┘
```

### Flux de Données

```
Utilisateur → View → ViewModel/Service → DataManager → Database
                ↓         ↓                  ↓           ↓
             State    Business Logic      Persistence  Storage
```

## 📊 Modèle de Données

### Entités Principales

1. **UserProfile**
   - id: UUID
   - name: String
   - age: Int
   - gender: Gender
   - preferences: UserPreferences

2. **WardrobeItem**
   - id: UUID
   - name: String
   - category: ClothingCategory
   - color: String
   - material: String?
   - season: [Season]
   - photoURL: String?

3. **Outfit**
   - id: UUID
   - name: String
   - description: String
   - mood: Mood
   - weather: WeatherType
   - items: [WardrobeItem]

4. **ChatConversation**
   - id: UUID
   - messages: [ChatMessage]
   - aiMode: AIMode
   - createdAt: Date

### Relations

```
UserProfile 1 ──── * WardrobeItem
UserProfile 1 ──── * Outfit (favoris)
Outfit * ──── * WardrobeItem (composition)
```

## 🎨 Design System

### Couleurs

- **Primary** : Bleu système iOS
- **Secondary** : Gris système iOS
- **Success** : Vert
- **Error** : Rouge
- **Background** : Adaptatif (clair/sombre)

### Typographie

- **Titres** : SF Pro Display, Bold, 28pt
- **Sous-titres** : SF Pro Text, Semibold, 20pt
- **Corps** : SF Pro Text, Regular, 16pt
- **Labels** : SF Pro Text, Medium, 14pt

### Composants Réutilisables

- `SettingRow` : Ligne de paramètres
- `OutfitCard` : Carte d'outfit
- `MoodButton` : Bouton d'humeur
- `WeatherCard` : Carte météo

## ✅ Validation et Ajustements

### Tests Utilisateur

1. **Tests de Navigation** : Vérifier la fluidité entre écrans
2. **Tests d'Utilisabilité** : Vérifier l'intuitivité de l'interface
3. **Tests d'Accessibilité** : Valider VoiceOver et contraste

### Itérations

- **V1.0** : Fonctionnalités de base
- **V1.1** : Améliorations UX basées sur retours
- **V2.0** : Nouvelles fonctionnalités (synchronisation, social, etc.)

---

**Approuvé par** : William  
**Date d'approbation** : 01/11/2025

