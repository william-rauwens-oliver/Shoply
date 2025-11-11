# Éco‑conception — Shoply

## Objectifs
- Réduire l’empreinte énergétique et réseau
- Minimiser la taille, la fréquence et la complexité des traitements
- Favoriser la durabilité (lisibilité, testabilité, modularité)

## Principes appliqués
- Calcul local prioritaire
  - LLM local « Shoply AI » pour limiter les appels réseau
  - Caching léger (UserDefaults) pour éviter des fetchs inutiles
- Parcimonie réseau
  - Appels externes uniquement à la demande (météo, recherche web)
  - Pas de synchronisation en tâche de fond non essentielle
- UI performante
  - SwiftUI (diffing) + composants réutilisables
  - Animations limitées et optimisées (durées courtes)
  - iPad centré (AdaptiveLayout) pour réduire sur‑rendu
- Stockage minimal
  - Données essentielles en local (UserDefaults)
  - SQLite optionnel (démonstration) et Core Data optionnel
  - Pas d’assets géants embarqués
- Accessibilité par défaut
  - A11y renforce la lisibilité et donc la durabilité d’usage

## Indicateurs (suggestions)
- Suivi du nombre d’appels réseau / session
- Temps moyen de rendu des écrans (profil Xcode)
- Taille de l’app et des artefacts CI
- Taux de ré‑utilisation composants UI

## Pistes futures
- Mettre en place un cache d’images disque (taille limitée)
- Stratégie d’actualisation réseau « on‑demand » + backoff
- Mesures d’énergie via Instruments (Energy Log) pendant CI locale


