# Guide de Déploiement & DevOps

## Environnements
- Développement: Xcode (simulateur/appareil)
- CI: GitHub Actions (macos-latest)
- Production: App Store (archive + notarisation)

## Variables / Secrets
- `GEMINI_API_KEY` (sécurisé)
- `GOOGLE_CSE_KEY` si utilisé

## Étapes de Build locales
1. `open Shoply.xcodeproj`
2. Sélectionner la cible Shoply, Device iPhone
3. `Cmd + R`

## Publication App Store (résumé)
1. Incrémenter version / build
2. Product > Archive
3. Validate App
4. Distribute App (App Store Connect)

## CI/CD
Workflow `.github/workflows/ci-cd.yml`:
- Jobs:
  - Tests (unitaires + UI)
  - Build (archive)
- Artefacts: export de l’archive (ajouté)

## Checklist Pré-prod
- [ ] Tests verts
-. [ ] Vérification RGPD (consentement, suppression)
- [ ] Accessibilité de base (VoiceOver)
- [ ] Localisations vérifiées (FR/EN/ES/IT/DE/…)


