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

## Publication App Store (détaillée)
1. Incrémenter version et build (TARGETS > Shoply > General)
2. Sélectionner Any iOS Device (arm64) puis Product > Archive
3. Organizer: Validate App (corriger éventuels warnings)
4. Distribute App > App Store Connect > Upload
5. Sur App Store Connect: créer fiche App, compléter métadonnées, privacy, captures
6. Soumettre à la revue

## Procédure de rollback
1. Conserver l’archive signée précédente (Artifacts CI + Organizer)
2. Créer une nouvelle soumission en réutilisant la version stable (hotfix si nécessaire)
3. Communiquer les notes de version et impacts aux utilisateurs

## CI/CD
Workflow `.github/workflows/ci-cd.yml`:
- Jobs:
  - Tests (unitaires + UI)
  - Build (archive)
- Artefacts: export de l’archive (ajouté)

## Checklist Pré-prod
- [ ] Tests verts (Unit/UI/Intégration)
- [ ] Vérification RGPD (consentement, suppression)
- [ ] Accessibilité de base (VoiceOver)
- [ ] Localisations vérifiées (FR/EN/ES/IT/DE/…)
- [ ] Screenshots iPhone + iPad mis à jour


