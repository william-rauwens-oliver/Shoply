# Conformité RGPD

## Consentement
- Géré par `RGDPManager` (statut, date, révocation)
- UI de consentement au premier lancement

## Droits des personnes
- Droit d’accès/portabilité: `RGDPManager.exportUserData()`
- Droit à l’effacement: `SettingsScreen.deleteAllUserData()`
- Droit d’opposition: désactivation des fonctionnalités optionnelles

## Finalités
- Personnalisation d’outfits et conseils (traitement nécessaire au service)
- Sauvegarde iCloud (synchronisation entre appareils)

## Minimisation des données
- Stockage local préférentiel
- Synchronisation optionnelle

## Mentions légales (modèle à intégrer dans l’app)
```
Responsable du traitement: William RAUWENS OLIVER
Finalité: assistant style et gestion de garde-robe
Base légale: exécution du contrat (CGU)
Destinataires: aucun transfert à des tiers hors services cloud Apple/Google choisis
Durée de conservation: tant que le compte est actif ou selon réglages utilisateur
Exercice des droits: via l’écran Paramètres > Confidentialité
```


