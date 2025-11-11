# Solution : Accéder aux Paramètres (Si project.pbxproj s'ouvre)

## ✅ Méthode qui fonctionne TOUJOURS

### Étape 1 : Fermer le fichier project.pbxproj
1. **Fermez l'onglet** `project.pbxproj` (cliquez sur le **X** de l'onglet)
2. Ou appuyez sur **⌘W** pour fermer l'onglet actif

### Étape 2 : Cliquer UNE SEULE FOIS (pas double-clic)
1. Dans le navigateur de gauche, **cliquez UNE SEULE FOIS** sur l'icône bleue "Shoply"
2. **Ne double-cliquez pas** (cela ouvre le fichier project.pbxproj)

### Étape 3 : Sélectionner le target Watch App
1. Dans la zone centrale, vous devriez voir "PROJECT" et "TARGETS"
2. **Cliquez sur "ShoplyWatchApp Watch App"** dans la liste TARGETS
3. Les onglets devraient apparaître en haut : General, Signing & Capabilities, Build Settings, etc.

## 🎯 Méthode Alternative : Via le Menu

### Option A : Menu File
1. Menu **File** > **Project Settings...** (ou **⌘;**)
2. Cela ouvre directement les paramètres du projet

### Option B : Clic droit
1. **Clic droit** sur l'icône bleue "Shoply" dans le navigateur
2. Sélectionnez **"Show Project Settings"** ou **"Edit Project Settings"**

## 🔍 Vérification : Ce que vous devriez voir

Après avoir cliqué une fois sur l'icône bleue et sélectionné "ShoplyWatchApp Watch App", vous devriez voir :

```
┌─────────────────────────────────────────┐
│  Zone Centrale                          │
│                                         │
│  PROJECT                                │
│    Shoply                               │
│                                         │
│  TARGETS                                │
│    Shoply                               │
│    ShoplyWidgetExtension                │
│    ShoplyWatchApp Watch App  ← ICI      │
│                                         │
│  ┌───────────────────────────────────┐ │
│  │ General | Signing & Capabilities │ │ ← ONGLETS
│  │ Build Settings | Build Phases     │ │
│  └───────────────────────────────────┘ │
│                                         │
│  [Contenu des paramètres ici]          │
└─────────────────────────────────────────┘
```

## ⚠️ Si vous voyez toujours project.pbxproj

1. **Fermez TOUS les onglets** de l'éditeur :
   - Clic droit sur un onglet > **"Close All"**
   - Ou **⌘⌥W** pour fermer tous les onglets

2. **Cliquez UNE SEULE FOIS** sur l'icône bleue "Shoply"

3. Si ça ne marche pas, utilisez le raccourci clavier :
   - **⌘;** (Commande + Point-virgule) pour ouvrir les paramètres du projet

## 🎨 Raccourci Rapide

**⌘;** = Ouvre directement les paramètres du projet (sans passer par le navigateur)

## 📝 Résumé des Actions

```
1. Fermer l'onglet project.pbxproj (⌘W)
2. Cliquer UNE FOIS sur l'icône bleue "Shoply"
3. Cliquer sur "ShoplyWatchApp Watch App" dans TARGETS
4. Cliquer sur l'onglet "Signing & Capabilities" ou "Build Settings"
```

