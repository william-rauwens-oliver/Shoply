# Guide d'utilisation d'Apple Sign In pour Shoply

## 🎯 Vue d'ensemble

Apple Sign In permet de vous connecter à Shoply de manière sécurisée avec votre Apple ID. Cette authentification permet également la synchronisation automatique de vos données avec iCloud.

## 📱 Comment se connecter avec Apple Sign In

### Méthode 1 : Depuis l'écran d'accueil (si disponible)

1. **Lancez l'application Shoply**
2. Si vous voyez l'écran "Se connecter avec Apple", appuyez sur le bouton noir **"Se connecter avec Apple"**
3. **Authentifiez-vous** avec Face ID, Touch ID ou votre code d'accès Apple
4. Autorisez l'application à utiliser votre Apple ID

### Méthode 2 : Continuer sans Apple Sign In

Si vous ne souhaitez pas utiliser Apple Sign In immédiatement :

1. Sur l'écran de connexion, appuyez sur **"Passer cette étape"**
2. Vous pourrez toujours vous connecter plus tard depuis les paramètres de l'application

## ⚙️ Configuration requise

### Sur votre iPhone/iPad

1. **Assurez-vous d'être connecté à iCloud** :
   - Allez dans **Réglages** → **[Votre nom]** → **iCloud**
   - Vérifiez que vous êtes connecté avec votre Apple ID

2. **Vérifiez que votre appareil est à jour** :
   - Apple Sign In nécessite iOS 13.0 ou ultérieur

### Dans l'application

L'application doit être correctement configurée dans Xcode. Si vous voyez des erreurs, consultez la section "Dépannage" ci-dessous.

## 🔐 Sécurité et confidentialité

- **Votre Apple ID reste privé** : Apple utilise un identifiant unique pour chaque application
- **Aucun mot de passe requis** : L'authentification se fait via Face ID, Touch ID ou votre code d'accès
- **Données sécurisées** : Vos données sont synchronisées de manière cryptée via iCloud

## ☁️ Synchronisation iCloud

Une fois connecté avec Apple Sign In :

1. **Vos données sont automatiquement sauvegardées** dans iCloud :
   - Votre profil utilisateur
   - Votre garde-robe
   - Votre historique d'outfits
   - Vos conversations avec l'IA
   - Vos favoris

2. **Synchronisation multi-appareils** :
   - Vos données sont disponibles sur tous vos appareils connectés au même Apple ID
   - Les modifications sont synchronisées automatiquement

## 🔄 Synchronisation manuelle

Vous pouvez forcer une synchronisation manuelle depuis les paramètres :

1. Allez dans **Paramètres** (icône ⚙️)
2. Section **"Synchronisation iCloud"**
3. Appuyez sur **"Synchroniser maintenant"** pour envoyer vos données locales vers iCloud
4. Appuyez sur **"Récupérer depuis iCloud"** pour restaurer vos données depuis iCloud

## 🛠️ Dépannage

### Problème : "Apple Sign In n'est pas disponible"

**Solutions :**

1. **Vérifiez votre connexion iCloud** :
   - Réglages → [Votre nom] → iCloud
   - Assurez-vous d'être connecté

2. **Redémarrez l'application** :
   - Fermez complètement l'application et relancez-la

3. **Vérifiez que votre appareil est à jour** :
   - Réglages → Général → À propos → Version iOS

### Problème : L'écran de connexion ne s'affiche pas

**Solutions :**

1. **Continuez sans connexion** :
   - Appuyez sur "Passer cette étape"
   - L'application fonctionne sans Apple Sign In

2. **Vérifiez que l'application est à jour**

### Problème : Erreur de synchronisation

**Solutions :**

1. **Vérifiez votre connexion Internet**
2. **Vérifiez votre espace iCloud** :
   - Réglages → [Votre nom] → iCloud → Gérer le stockage
   - Assurez-vous d'avoir de l'espace disponible

3. **Synchronisez manuellement** :
   - Paramètres → Synchronisation iCloud → Synchroniser maintenant

## 📝 Notes importantes

- **Apple Sign In est optionnel** : L'application fonctionne parfaitement sans connexion Apple
- **Données locales** : Même sans iCloud, vos données sont sauvegardées localement sur votre appareil
- **Confidentialité** : Apple Sign In ne partage aucune information personnelle avec Shoply, uniquement un identifiant unique

## 💡 Astuce

Pour une expérience optimale, connectez-vous avec Apple Sign In dès le démarrage. Cela vous permet de :
- Sauvegarder automatiquement vos données
- Accéder à vos données depuis plusieurs appareils
- Protéger vos données en cas de perte ou changement d'appareil

## 🆘 Besoin d'aide ?

Si vous rencontrez des problèmes persistants :
1. Vérifiez que votre appareil est à jour
2. Redémarrez votre appareil
3. Vérifiez votre connexion Internet et iCloud
4. Contactez le support si le problème persiste

