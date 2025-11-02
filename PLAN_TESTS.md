# Plan de Tests - Shoply

**Projet** : Shoply - Application de Sélection d'Outfits  
**Version** : 1.0.0  
**Date** : 01/11/2025  
**Auteur** : William

## 📋 Conformité RNCP37873

Ce plan de tests répond aux exigences du **Bloc 3 - Préparer le déploiement d'une application sécurisée** :
- ✅ Préparer et exécuter les plans de tests d'une application
- ✅ Préparer et documenter le déploiement d'une application
- ✅ Contribuer à la mise en production dans une démarche DevOps

## 🎯 Objectifs des Tests

1. **Valider la fonctionnalité** : Vérifier que toutes les fonctionnalités répondent aux besoins exprimés
2. **Garantir la qualité** : Assurer la stabilité, performance et sécurité de l'application
3. **Vérifier la conformité** : S'assurer du respect du RGPD et de l'accessibilité (RGAA)
4. **Préparer le déploiement** : Identifier et corriger les problèmes avant la mise en production

## 📊 Stratégie de Tests

### Niveaux de Tests

#### 1. Tests Unitaires
**Objectif** : Tester les composants isolément

**Couverture** :
- Services métier (`OutfitService`, `WardrobeService`)
- Gestionnaires de données (`DataManager`, `SQLDatabaseService`, `NoSQLDatabaseService`)
- Validation des données
- Calculs et transformations
- Gestion RGPD (`RGDPManager`)

**Fichiers de tests** :
- `ShoplyTests/OutfitServiceTests.swift`
- `ShoplyTests/RGDPManagerTests.swift`
- `ShoplyTests/DatabaseServiceTests.swift` (à créer)
- `ShoplyTests/DataManagerTests.swift` (à créer)

**Objectif de couverture** : ≥ 80%

#### 2. Tests d'Intégration
**Objectif** : Vérifier les interactions entre les couches

**Scénarios testés** :
- Interaction Présentation → Métier → Données
- Persistance des données (SQL et NoSQL)
- Synchronisation CloudKit
- Flux complets utilisateur

**Fichiers de tests** :
- `ShoplyTests/IntegrationTests.swift` (à créer)

#### 3. Tests UI
**Objectif** : Valider l'interface utilisateur et l'expérience utilisateur

**Couverture** :
- Navigation entre écrans
- Interactions utilisateur (touches, glissements)
- Accessibilité (VoiceOver, contraste, tailles)
- Affichage des données
- Gestion des erreurs

**Fichiers de tests** :
- `Shoply/Shoply_appUITests/Shoply_appUITests.swift`

#### 4. Tests de Performance
**Objectif** : Valider les performances de l'application

**Métriques** :
- Temps de lancement : < 2 secondes
- Fluidité : 60 FPS
- Consommation mémoire : < 50 MB
- Taille de l'application : < 20 MB

**Outils** :
- Instruments (Time Profiler, Allocations, Leaks)
- XCTest Performance Tests

#### 5. Tests de Sécurité
**Objectif** : Vérifier la sécurité de l'application

**Points testés** :
- Validation des entrées utilisateur
- Gestion sécurisée des erreurs
- Conformité RGPD
- Chiffrement des données sensibles
- Protection contre les injections SQL

#### 6. Tests d'Accessibilité
**Objectif** : Valider la conformité RGAA

**Points testés** :
- Support VoiceOver complet
- Contraste des couleurs (WCAG AA)
- Tailles de police accessibles
- Navigation au clavier
- Alternatives textuelles

## 📝 Cas de Tests Détaillés

### Tests Unitaires - OutfitService

| ID | Description | Préconditions | Actions | Résultat Attendu |
|---|---|---|---|---|
| UT-001 | Filtrer outfits par humeur | Base de données avec outfits variés | Filtrer par "Énergique" | Retourne uniquement les outfits avec humeur "Énergique" |
| UT-002 | Filtrer outfits par météo | Base de données avec outfits variés | Filtrer par "Ensoleillé" | Retourne uniquement les outfits avec météo "Ensoleillé" |
| UT-003 | Ajouter un favori | Aucun favori existant | Ajouter outfit ID "123" | Favori ajouté avec succès |
| UT-004 | Supprimer un favori | Favori existant | Supprimer outfit ID "123" | Favori supprimé avec succès |
| UT-005 | Recherche textuelle | Base de données avec outfits | Rechercher "casual" | Retourne les outfits contenant "casual" |

### Tests d'Intégration - Persistance

| ID | Description | Préconditions | Actions | Résultat Attendu |
|---|---|---|---|---|
| IT-001 | Sauvegarder outfit dans SQL | Application lancée | Créer un outfit | Outfit sauvegardé dans SQLite |
| IT-002 | Sauvegarder outfit dans NoSQL | Compte iCloud connecté | Créer un outfit | Outfit sauvegardé dans CloudKit |
| IT-003 | Synchronisation SQL ↔ NoSQL | Données dans SQL et CloudKit | Synchroniser | Données identiques dans les deux bases |
| IT-004 | Export RGPD | Données utilisateur présentes | Exporter les données | Fichier JSON généré avec toutes les données |

### Tests UI - Navigation

| ID | Description | Préconditions | Actions | Résultat Attendu |
|---|---|---|---|---|
| UI-001 | Navigation Home → Sélection | Application lancée | Tap sur "Sélectionner" | Écran de sélection s'affiche |
| UI-002 | Navigation Sélection → Détails | Liste d'outfits affichée | Tap sur un outfit | Écran de détails s'affiche |
| UI-003 | Retour en arrière | Sur écran de détails | Tap sur bouton retour | Retour à l'écran précédent |

### Tests de Sécurité

| ID | Description | Préconditions | Actions | Résultat Attendu |
|---|---|---|---|---|
| SEC-001 | Validation entrée utilisateur | Champ texte | Entrer "<script>" | Entrée rejetée ou échappée |
| SEC-002 | Protection injection SQL | Service SQL | Requête avec "'; DROP TABLE--" | Requête sécurisée, aucune injection |
| SEC-003 | Consentement RGPD | Premier lancement | Accepter/Refuser | Consentement enregistré |

## 🚀 Exécution des Tests

### Commandes

```bash
# Tous les tests
xcodebuild test -scheme Shoply -destination 'platform=iOS Simulator,name=iPhone 15'

# Tests unitaires uniquement
xcodebuild test -scheme Shoply -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ShoplyTests

# Tests UI uniquement
xcodebuild test -scheme Shoply -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:Shoply_appUITests

# Tests de performance
xcodebuild test -scheme Shoply -destination 'platform=iOS Simulator,name=iPhone 15' -only-testing:ShoplyTests/PerformanceTests
```

### Environnements de Test

1. **Développement**
   - Simulateur iOS 18.0
   - Xcode 15.0+
   - Tests rapides (moins de validation)

2. **Staging**
   - Simulateur et appareils physiques
   - Tests complets
   - Validation avant production

3. **Production**
   - Appareils physiques uniquement
   - Tests de régression complets
   - Validation finale

## 📈 Métriques et Rapports

### Couverture de Code

**Objectif** : ≥ 80% de couverture

**Outils** :
- Xcode Code Coverage
- Génération de rapports HTML

### Résultats des Tests

**Format de rapport** :
- JUnit XML pour intégration CI/CD
- HTML pour consultation manuelle

**Métriques suivies** :
- Nombre de tests exécutés
- Nombre de tests réussis/échoués
- Temps d'exécution
- Couverture de code

## 🔄 Intégration Continue (CI/CD)

### Pipeline de Tests

1. **Commit/Push** → Déclenchement automatique
2. **Tests unitaires** → Validation rapide
3. **Tests d'intégration** → Validation complète
4. **Tests UI** → Validation interface
5. **Rapport** → Génération et envoi

### Outils CI/CD

- **GitHub Actions** : Automatisation des tests
- **Fastlane** : Automatisation du déploiement
- **Codecov** : Suivi de la couverture (optionnel)

## ✅ Critères d'Acceptation

Pour qu'une version soit considérée comme prête pour la production :

- ✅ 100% des tests unitaires passent
- ✅ 100% des tests d'intégration passent
- ✅ 100% des tests UI passent
- ✅ Couverture de code ≥ 80%
- ✅ Pas de crashs détectés
- ✅ Performance conforme aux objectifs
- ✅ Conformité RGPD validée
- ✅ Accessibilité RGAA validée

## 📅 Planning d'Exécution

| Phase | Période | Tests | Responsable |
|---|---|---|---|
| Développement | En continu | Tests unitaires | Développeur |
| Intégration | Avant chaque release | Tests d'intégration | Développeur |
| Validation | Avant production | Tous les tests | Équipe |
| Production | Après déploiement | Tests de régression | Équipe |

---

**Approuvé par** : William  
**Date d'approbation** : 01/11/2025

