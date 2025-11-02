#!/bin/bash

# Script pour lancer Shoply Android sur un émulateur
# Usage: ./launch-on-emulator.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Lancement de Shoply Android sur émulateur..."

# Vérifier ADB
if ! command -v adb &> /dev/null; then
    echo "❌ ADB n'est pas dans le PATH"
    echo "💡 Ajoutez Android SDK platform-tools à votre PATH :"
    echo "   export PATH=\$PATH:\$HOME/Library/Android/sdk/platform-tools"
    exit 1
fi

# Vérifier les appareils connectés
echo "📱 Vérification des appareils..."
adb devices

# Compter les appareils disponibles
DEVICE_COUNT=$(adb devices | grep -v "List" | grep -v "^$" | wc -l | tr -d ' ')

if [ "$DEVICE_COUNT" -eq 0 ]; then
    echo ""
    echo "❌ Aucun appareil/émulateur trouvé"
    echo ""
    echo "📋 Options :"
    echo "1. Créer un émulateur depuis Android Studio :"
    echo "   - Ouvrir Android Studio"
    echo "   - Tools → Device Manager"
    echo "   - Create Device → Choisir Pixel 6 → API 33"
    echo "   - Cliquer Play ▶️ pour lancer l'émulateur"
    echo ""
    echo "2. Lancer un émulateur existant depuis Android Studio"
    echo ""
    echo "3. Utiliser un appareil physique :"
    echo "   - Activer 'Débogage USB' dans Options développeur"
    echo "   - Connecter le téléphone en USB"
    echo ""
    echo "💡 Une fois l'émulateur/appareil lancé, relancez ce script"
    exit 1
fi

echo "✅ $DEVICE_COUNT appareil(s) trouvé(s)"
echo ""

# Aller dans le dossier du projet
cd "$PROJECT_ROOT"

# Compiler l'app si nécessaire
if [ ! -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
    echo "🔨 Compilation de l'application..."
    if [ -f "./gradlew" ]; then
        ./gradlew assembleDebug
    else
        echo "⚠️  Gradle wrapper non trouvé, compilation manuelle nécessaire"
        echo "💡 Ouvrez le projet dans Android Studio et compilez depuis là"
        exit 1
    fi
else
    echo "✅ APK déjà compilé"
fi

# Installer l'app
echo "📦 Installation de l'app..."
adb install -r app/build/outputs/apk/debug/app-debug.apk

if [ $? -eq 0 ]; then
    echo "✅ Application installée avec succès"
    
    # Lancer l'app
    echo "🚀 Lancement de l'application..."
    adb shell am start -n com.shoply.app/.MainActivity
    
    echo ""
    echo "✅ Shoply est maintenant lancé sur l'émulateur !"
    echo ""
    echo "📋 Commandes utiles :"
    echo "   Voir les logs : adb logcat | grep Shoply"
    echo "   Redémarrer : adb shell am start -n com.shoply.app/.MainActivity"
    echo "   Désinstaller : adb uninstall com.shoply.app"
else
    echo "❌ Erreur lors de l'installation"
    exit 1
fi

