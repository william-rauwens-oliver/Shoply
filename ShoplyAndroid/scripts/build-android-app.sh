#!/bin/bash

# Script pour compiler l'application Android complète
# Usage: ./build-android-app.sh [debug|release]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

BUILD_TYPE=${1:-debug}

echo "🔨 Compilation de l'application Android Shoply ($BUILD_TYPE)..."

# Vérifier que Gradle est disponible
if ! command -v ./gradlew &> /dev/null; then
    echo "📦 Téléchargement de Gradle Wrapper..."
    
    # Créer gradle wrapper si nécessaire
    cd "$PROJECT_ROOT"
    
    # Utiliser gradle directement si disponible, sinon télécharger wrapper
    if command -v gradle &> /dev/null; then
        gradle wrapper
    else
        echo "❌ Gradle n'est pas installé"
        echo "💡 Installez Gradle ou Android Studio (qui inclut Gradle)"
        exit 1
    fi
fi

cd "$PROJECT_ROOT"

# Vérifier que les bibliothèques Swift sont compilées
if [ ! -d "app/src/main/jniLibs" ] || [ -z "$(ls -A app/src/main/jniLibs 2>/dev/null)" ]; then
    echo "⚠️  Aucune bibliothèque Swift trouvée dans jniLibs/"
    echo "💡 Exécutez d'abord: ./scripts/build-swift-libs.sh"
    read -p "Continuer quand même? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Compiler l'app
echo "🔨 Compilation Android en cours..."

case $BUILD_TYPE in
    debug)
        ./gradlew assembleDebug
        APK_PATH="app/build/outputs/apk/debug/app-debug.apk"
        ;;
    release)
        ./gradlew assembleRelease
        APK_PATH="app/build/outputs/apk/release/app-release.apk"
        ;;
    *)
        echo "❌ Type de build invalide: $BUILD_TYPE"
        echo "Types supportés: debug, release"
        exit 1
        ;;
esac

if [ -f "$APK_PATH" ]; then
    APK_SIZE=$(du -h "$APK_PATH" | cut -f1)
    echo ""
    echo "✅ Compilation réussie !"
    echo "📦 APK: $APK_PATH"
    echo "📏 Taille: $APK_SIZE"
    echo ""
    echo "📋 Pour installer sur un appareil/émulateur :"
    echo "   adb install $APK_PATH"
    echo ""
    echo "🚀 Pour lancer l'app :"
    echo "   adb shell am start -n com.shoply.app/.MainActivity"
else
    echo "❌ L'APK n'a pas été généré"
    exit 1
fi

