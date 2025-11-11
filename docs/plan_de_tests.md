# Plan de Tests

## Objectifs
Vérifier la conformité fonctionnelle, la stabilité, la sécurité et l’accessibilité.

## Stratégie
- Tests unitaires (Services, Utils)
- Tests UI (flux critiques)
- Tests d’accessibilité (libellés, traits)

## Périmètre
1. Onboarding (profil, photo, thème)
2. Sélection intelligente (IA, météo)
3. Collections (CRUD)
4. Garde-robe (CRUD)
5. Wishlist (ajout, photo)
6. Mode Voyage (plans, checklist)
7. Chat IA (conversation, fermeture)
8. Paramètres (langue, suppression données)

## Cas de tests (exemples)
- `RGDPManagerTests`: consentement, export, révoquer
- `OutfitServiceTests`: génération aléatoire sans crash
- UI:
  - Onboarding: bouton “Pour commencer” visible
  - Collections: suppression collection non défaut
  - Chat: fermeture via croix

## Critères d’acceptation
- 0 crash sur les parcours principaux
- Tests Unit/UI passent en CI
- A11y labels présents pour éléments interactifs clés


