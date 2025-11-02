#!/bin/bash

# Script pour lancer automatiquement Shoply Android
# Usage: ./scripts/lancer-app.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator

cd "$PROJECT_ROOT"

echo "🚀 Lancement automatique de Shoply Android"
echo ""

# 1. Vérifier que l'APK existe
if [ ! -f "app/build/outputs/apk/debug/app-debug.apk" ]; then
    echo "❌ APK non trouvé, compilation nécessaire..."
    export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
    export PATH=$JAVA_HOME/bin:$PATH
    ./gradlew assembleDebug --no-daemon
    echo "✅ Compilation terminée"
    echo ""
fi

# 2. Vérifier/Attendre qu'un appareil soit connecté
echo "📱 Vérification des appareils..."
MAX_WAIT=60
WAITED=0

while [ $WAITED -lt $MAX_WAIT ]; do
    DEVICE_COUNT=$(adb devices | grep -c "device$" || echo "0")
    
    if [ "$DEVICE_COUNT" -gt 0 ]; then
        echo "✅ Appareil connecté !"
        adb devices
        break
    fi
    
    if [ $WAITED -eq 0 ]; then
        echo "⏳ Aucun appareil, attente..."
        echo "💡 Lancez un émulateur depuis Android Studio (Device Manager → Play ▶️)"
    fi
    
    sleep 2
    WAITED=$((WAITED + 2))
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo "❌ Timeout : Aucun appareil connecté après ${MAX_WAIT} secondes"
    echo ""
    echo "📋 Instructions :"
    echo "1. Ouvrez Android Studio"
    echo "2. Tools → Device Manager"
    echo "3. Créez un émulateur (Create Device) ou lancez-en un (Play ▶️)"
    echo "4. Relancez ce script : ./scripts/lancer-app.sh"
    exit 1
fi

# 3. Installer l'APK
echo ""
echo "📦 Installation de l'application..."
adb install -r app/build/outputs/apk/debug/app-debug.apk

# 4. Lancer l'app
echo ""
echo "🚀 Lancement de Shoply..."
adb shell am start -n com.shoply.app/.MainActivity

echo ""
echo "✅ Shoply est maintenant lancé sur l'émulateur !"
echo ""
echo "📱 L'app devrait être visible sur l'écran de l'émulateur"
echo ""
echo "📋 Commandes utiles :"
echo "   Voir les logs : adb logcat | grep Shoply"
echo "   Redémarrer : adb shell am start -n com.shoply.app/.MainActivity"
echo "   Arrêter : adb shell am force-stop com.shoply.app"

