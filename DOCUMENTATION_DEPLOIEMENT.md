# Documentation de Déploiement - Shoply

**Projet** : Shoply - Application de Sélection d'Outfits  
**Version** : 1.0.0  
**Date** : 01/11/2025  
**Auteur** : William

## 📋 Conformité RNCP37873

Cette documentation répond aux exigences du **Bloc 3 - Préparer le déploiement d'une application sécurisée** :
- ✅ Préparer et documenter le déploiement d'une application
- ✅ Contribuer à la mise en production dans une démarche DevOps

## 🎯 Objectifs

1. **Documenter le processus complet de déploiement**
2. **Assurer la reproductibilité** du déploiement
3. **Garantir la sécurité** pendant le déploiement
4. **Faciliter la maintenance** post-déploiement

## 📦 Prérequis

### Environnement de Développement

- **Xcode** : 15.0 ou supérieur
- **Swift** : 5.9 ou supérieur
- **iOS SDK** : 18.0 ou supérieur
- **macOS** : 14.0 (Sonoma) ou supérieur

### Comptes et Certificats

1. **Apple Developer Account** (compte payant requis)
   - Certificats de développement
   - Certificats de distribution
   - Identifiants d'application
   - Profils de provisionnement

2. **App Store Connect**
   - Application créée
   - Métadonnées configurées
   - Politique de confidentialité
   - Captures d'écran

## 🔧 Configuration du Projet

### 1. Configuration Build

#### Configuration Debug

```xml
<key>CODE_SIGN_IDENTITY</key>
<string>Apple Development</string>
<key>DEVELOPMENT_TEAM</key>
<string>YOUR_TEAM_ID</string>
<key>PROVISIONING_PROFILE_SPECIFIER</key>
<string>Shoply Development</string>
```

#### Configuration Release

```xml
<key>CODE_SIGN_IDENTITY</key>
<string>Apple Distribution</string>
<key>DEVELOPMENT_TEAM</key>
<string>YOUR_TEAM_ID</string>
<key>PROVISIONING_PROFILE_SPECIFIER</key>
<string>Shoply Distribution</string>
<key>SWIFT_OPTIMIZATION_LEVEL</key>
<string>-O</string>
```

### 2. Versioning

**Format** : `MAJOR.MINOR.PATCH` (ex: 1.0.0)

**Gestion** :
- `CFBundleShortVersionString` : Version utilisateur
- `CFBundleVersion` : Numéro de build

**Stratégie** :
- **Major** : Changements majeurs, incompatibilités
- **Minor** : Nouvelles fonctionnalités, compatibilité maintenue
- **Patch** : Corrections de bugs

### 3. Certificats et Profils

#### Génération des Certificats

1. Ouvrir **Xcode** → **Preferences** → **Accounts**
2. Ajouter votre compte Apple Developer
3. Sélectionner l'équipe et cliquer sur **Manage Certificates**
4. Générer :
   - **Development Certificate** (pour tests)
   - **Distribution Certificate** (pour App Store)

#### Création des Profils de Provisionnement

1. Aller sur [developer.apple.com](https://developer.apple.com)
2. **Certificates, Identifiers & Profiles**
3. Créer un **App ID** : `com.yourcompany.shoply`
4. Créer les profils :
   - **Development Profile** (pour développement)
   - **Distribution Profile** (pour App Store)

## 🚀 Processus de Déploiement

### Étape 1 : Préparation

1. **Vérifier les tests**
   ```bash
   xcodebuild test -scheme Shoply -destination 'platform=iOS Simulator,name=iPhone 15'
   ```

2. **Vérifier la version**
   - Ouvrir `Info.plist`
   - Mettre à jour `CFBundleShortVersionString` et `CFBundleVersion`

3. **Vérifier les métadonnées**
   - Description de l'app
   - Captures d'écran à jour
   - Politique de confidentialité

### Étape 2 : Build de Production

#### Archive

1. Ouvrir le projet dans Xcode
2. Sélectionner **Product** → **Archive**
3. Attendre la fin de l'archive
4. Ouvrir l'**Organizer** (⌘⇧⌥O)

#### Validation

1. Dans l'Organizer, sélectionner l'archive
2. Cliquer sur **Validate App**
3. Sélectionner **App Store Connect**
4. Suivre le processus de validation

**Vérifications automatiques** :
- Certificats valides
- Profils de provisionnement corrects
- Aucune erreur de build
- Conformité aux guidelines App Store

### Étape 3 : Upload vers App Store Connect

#### Méthode 1 : Via Xcode

1. Dans l'Organizer, sélectionner l'archive validée
2. Cliquer sur **Distribute App**
3. Sélectionner **App Store Connect**
4. Choisir **Upload**
5. Suivre l'assistant

#### Méthode 2 : Via Commande Ligne (altool)

```bash
xcrun altool --upload-app \
  --type ios \
  --file "Shoply.ipa" \
  --username "your-email@example.com" \
  --password "app-specific-password"
```

### Étape 4 : Configuration App Store Connect

1. **Aller sur [appstoreconnect.apple.com](https://appstoreconnect.apple.com)**

2. **Sélectionner l'application Shoply**

3. **Créer une nouvelle version**
   - Numéro de version : 1.0.0
   - Informations de build : Sélectionner le build uploadé

4. **Remplir les métadonnées** :
   - Description
   - Mots-clés
   - URL de support
   - URL de politique de confidentialité
   - Captures d'écran

5. **Soumission pour révision**
   - Répondre aux questions de conformité
   - Soumettre pour révision

## 🔄 Approche DevOps

### Intégration Continue / Déploiement Continu (CI/CD)

#### GitHub Actions Workflow

Fichier : `.github/workflows/ci-cd.yml`

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run Tests
        run: |
          xcodebuild test \
            -scheme Shoply \
            -destination 'platform=iOS Simulator,name=iPhone 15'
      
  build:
    runs-on: macos-latest
    needs: test
    steps:
      - uses: actions/checkout@v3
      - name: Build Archive
        run: |
          xcodebuild archive \
            -scheme Shoply \
            -configuration Release \
            -archivePath ./build/Shoply.xcarchive
      
  deploy:
    runs-on: macos-latest
    needs: build
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - name: Upload to App Store Connect
        env:
          APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
        run: |
          xcrun altool --upload-app ...
```

### Outils DevOps

1. **Fastlane** : Automatisation du déploiement
   ```ruby
   # Fastfile
   lane :beta do
     build_app(scheme: "Shoply")
     upload_to_testflight
   end
   ```

2. **Git** : Gestion de version
   - Tags de version : `v1.0.0`
   - Branches : `main` (production), `develop` (développement)

3. **Automated Testing** : Tests à chaque commit

## 📱 Distribution

### TestFlight (Bêta Testing)

1. **Upload vers TestFlight**
   - Via Xcode Organizer
   - Via Fastlane
   - Via App Store Connect API

2. **Ajouter des testeurs**
   - Testeurs internes (jusqu'à 100)
   - Testeurs externes (jusqu'à 10 000)

3. **Feedback**
   - Collecter les retours
   - Corriger les bugs
   - Itérer

### App Store

1. **Soumission pour révision**
   - Remplir toutes les métadonnées
   - Répondre aux questions
   - Soumettre

2. **Suivi de la révision**
   - Statut : En attente → En révision → Approuvé/Rejeté
   - Temps moyen : 24-48 heures

3. **Publication**
   - Automatique ou manuelle
   - Disponible immédiatement ou à une date programmée

## 🔒 Sécurité du Déploiement

### Bonnes Pratiques

1. **Certificats**
   - Ne jamais commiter les certificats dans Git
   - Utiliser des secrets chiffrés (GitHub Secrets, Keychain)

2. **API Keys**
   - Stocker dans des fichiers de configuration non versionnés
   - Utiliser des variables d'environnement

3. **Code Signing**
   - Toujours signer avec des certificats valides
   - Vérifier les profils de provisionnement

### Checklist Sécurité

- ✅ Certificats valides et non expirés
- ✅ Pas de clés API en clair dans le code
- ✅ Profils de provisionnement corrects
- ✅ Validation des entrées utilisateur
- ✅ Conformité RGPD
- ✅ Pas de données sensibles dans les logs

## 📊 Monitoring Post-Déploiement

### Métriques à Suivre

1. **Crash Reports**
   - Taux de crash < 0.1%
   - Utiliser Crashlytics ou App Store Connect

2. **Performance**
   - Temps de lancement
   - Consommation mémoire
   - Fluidité de l'interface

3. **Utilisation**
   - Nombre d'utilisateurs actifs
   - Taux de rétention
   - Fonctionnalités les plus utilisées

### Outils

- **App Store Connect** : Analytics, Crash Reports
- **Xcode Instruments** : Profiling
- **TestFlight Feedback** : Retours utilisateurs

## 🐛 Résolution de Problèmes

### Problèmes Courants

| Problème | Solution |
|---|---|
| Certificat expiré | Générer un nouveau certificat dans Developer Portal |
| Profil invalide | Recréer le profil de provisionnement |
| Erreur de validation | Vérifier les métadonnées dans App Store Connect |
| Build rejeté | Consulter les détails dans App Store Connect |

## 📚 Ressources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Fastlane Documentation](https://docs.fastlane.tools/)

---

**Approuvé par** : William  
**Date d'approbation** : 01/11/2025

