# Forcer Xcode à Afficher la Vue Graphique (Pas la Vue Code)

## 🔧 Solution 1 : Fermer et Rouvrir Correctement

1. **Fermez TOUS les onglets** de l'éditeur :
   - Clic droit sur un onglet > **"Close All"**
   - Ou **⌘⌥W** (Commande + Option + W)

2. Dans le navigateur de gauche :
   - **Double-cliquez** sur `AppIcon.appiconset`
   - **NE PAS** cliquer sur `Assets.xcassets`

3. La vue graphique devrait s'ouvrir automatiquement

## 🔧 Solution 2 : Utiliser le Menu Editor

1. Dans le navigateur, **sélectionnez** `AppIcon.appiconset` (un seul clic)
2. Menu **Editor** > **Open As** > **Asset Catalog**
3. La vue graphique devrait s'ouvrir

## 🔧 Solution 3 : Clic Droit

1. Dans le navigateur, **clic droit** sur `AppIcon.appiconset`
2. Sélectionnez **"Open As"** > **"Asset Catalog"**
3. La vue graphique devrait s'ouvrir

## 🔧 Solution 4 : Changer le Type de Fichier par Défaut

Si Xcode ouvre toujours en vue code :

1. **Clic droit** sur `AppIcon.appiconset` dans le navigateur
2. Sélectionnez **"Get Info"** (ou **⌘I**)
3. Dans la fenêtre qui s'ouvre, cherchez **"Open with"**
4. Sélectionnez **"Xcode"** et cliquez sur **"Change All..."**
5. Cela changera le type par défaut pour tous les fichiers `.appiconset`

## ⚠️ Important

- **Ne cliquez PAS** sur `Assets.xcassets` (cela ouvre la vue code)
- **Double-cliquez** sur `AppIcon.appiconset` directement
- Si ça ne marche pas, fermez tous les onglets et réessayez

## ✅ Ce que vous devriez voir

En vue graphique, vous devriez voir :
- Une interface avec des zones rectangulaires pour les images
- Des emplacements vides ou avec des images
- La possibilité de **glisser-déposer** des images directement
- Pas de code JSON ou de texte

## 🎯 Si Rien ne Fonctionne

1. **Fermez Xcode complètement**
2. **Rouvrez Xcode**
3. **Ouvrez votre projet**
4. **Double-cliquez** sur `AppIcon.appiconset`
5. La vue graphique devrait s'ouvrir

