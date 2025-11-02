#!/bin/bash
# Script rapide pour compiler et lancer Shoply Android

set -e

cd "$(dirname "$0")"

echo "🚀 Shoply Android - Démarrage rapide"
echo ""

# Configuration
export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
export PATH=$JAVA_HOME/bin:$PATH
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools

# 1. Compiler
echo "📦 Compilation de l'APK..."
./gradlew assembleDebug --no-daemon

# 2. Vérifier un appareil
echo ""
echo "📱 Vérification des appareils..."
DEVICES=$(adb devices | grep -c "device$" || echo "0")

if [ "$DEVICES" = "0" ]; then
    echo "❌ Aucun appareil connecté !"
    echo ""
    echo "📋 Pour lancer un émulateur :"
    echo "1. Ouvrez Android Studio"
    echo "2. Tools → Device Manager"
    echo "3. Cliquez Play ▶️ sur un émulateur"
    echo ""
    echo "Ou ouvrez directement Android Studio :"
    open -a "Android Studio" .
    exit 1
fi

# 3. Installer
echo "✅ Appareil trouvé !"
echo "📦 Installation de l'app..."
adb install -r app/build/outputs/apk/debug/app-debug.apk

# 4. Lancer
echo "🚀 Lancement de Shoply..."
adb shell am start -n com.shoply.app/.MainActivity

echo ""
echo "✅ Shoply est maintenant lancé sur l'émulateur !"
echo ""

