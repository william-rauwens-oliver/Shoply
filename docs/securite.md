# Sécurité et Conformité

## Référentiel
- Recommandations ANSSI (bonnes pratiques)
- RGPD (consentement, portabilité, suppression)
- OWASP Mobile Top 10 (principes)

## Mesures en place
- Authentification:
  - Sign in with Apple (`AppleSignInService`)
  - Jetons OAuth (Gemini) stockés de manière sécurisée
- Persistance:
  - CloudKit (chiffré au repos et en transit)
  - SQLite local: données non sensibles
  - UserDefaults: uniquement préférences
- Données personnelles:
  - `RGDPManager` (consentement, révocation, export)
  - Suppression des données via `SettingsScreen.deleteAllUserData()`
- Réduction de surface d’attaque:
  - APIs externes encapsulées (`GeminiService`)
  - Nettoyage des logs de debug
  - Pas de clés en dur dans le code (variables à configurer)

## Politique de gestion des secrets
- Clés API configurées hors repo (variables d’environnement / secrets CI)
- Jamais de commit de secrets

## Plan de réponse aux incidents (résumé)
1) Détection (crash/erreurs via logs)
2) Confinement (désactiver fonctionnalités si nécessaire)
3) Correction (hotfix)
4) Publication (nouvelle build)
5) Rétro (post-mortem)

## Checklist Dev Secure
- [x] Validations d’entrée (EmailValidation)
- [x] Transport chiffré (HTTPS / CloudKit)
- [x] Données minimes persistées
- [x] Contrôle d’accès côté UI (auth)
- [x] Journalisation non sensible (no PII)


