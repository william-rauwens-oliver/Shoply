#!/bin/bash

# Script pour compiler les bibliothèques Swift pour Android
# Usage: ./build-swift-libs.sh [architecture]
# Architectures supportées: arm64-v8a (par défaut), x86_64

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SWIFT_PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)/Shoply"

ARCH=${1:-arm64-v8a}

# Mapper l'architecture Android vers Swift SDK
case $ARCH in
    arm64-v8a)
        SWIFT_SDK="aarch64-unknown-linux-android28"
        ;;
    x86_64)
        SWIFT_SDK="x86_64-unknown-linux-android28"
        ;;
    *)
        echo "❌ Architecture non supportée: $ARCH"
        echo "Architectures supportées: arm64-v8a, x86_64"
        exit 1
        ;;
esac

echo "🔨 Compilation des bibliothèques Swift pour Android ($ARCH)..."
echo "📦 SDK Swift: $SWIFT_SDK"

# Vérifier que Swift est installé
if ! command -v swiftly &> /dev/null; then
    echo "❌ Swiftly n'est pas installé. Installez-le d'abord (voir SETUP_ANDROID_SWIFT.md)"
    exit 1
fi

# Aller dans le dossier du projet Swift
if [ ! -d "$SWIFT_PROJECT_ROOT" ]; then
    echo "❌ Dossier Swift non trouvé: $SWIFT_PROJECT_ROOT"
    echo "💡 Assurez-vous d'être dans le bon répertoire du projet"
    exit 1
fi

cd "$SWIFT_PROJECT_ROOT"

# Pour Shoply, nous devons créer un Package.swift si nécessaire
# car c'est un projet Xcode, pas un package Swift standard
echo "📝 Création d'un Package.swift temporaire pour la compilation Android..."

# Note: Cette étape nécessitera d'adapter votre code Swift
# pour qu'il soit compatible avec un Package.swift standard
# Pour l'instant, créons une structure de base

SWIFT_BUILD_DIR="$PROJECT_ROOT/build/swift/$ARCH"
mkdir -p "$SWIFT_BUILD_DIR"

echo "🔨 Compilation pour $SWIFT_SDK..."

# Compiler avec Swift SDK Android
# Note: Vous devrez adapter cela selon votre structure de projet
swiftly run swift build \
    --swift-sdk "$SWIFT_SDK" \
    --static-swift-stdlib \
    -c release \
    --build-path "$SWIFT_BUILD_DIR"

echo "✅ Compilation terminée"

# Copier les bibliothèques .so dans le dossier jniLibs de l'app Android
echo "📦 Copie des bibliothèques dans app/src/main/jniLibs..."

JNI_LIBS_DIR="$PROJECT_ROOT/app/src/main/jniLibs"

# Créer le dossier pour l'architecture
mkdir -p "$JNI_LIBS_DIR/$ARCH"

# Copier les bibliothèques Swift compilées
# Note: Adaptez cela selon ce que produit votre build Swift
if [ -d "$SWIFT_BUILD_DIR/release" ]; then
    find "$SWIFT_BUILD_DIR/release" -name "*.so" -exec cp {} "$JNI_LIBS_DIR/$ARCH/" \;
fi

# Copier libc++_shared.so depuis le NDK
if [ -z "$ANDROID_NDK_HOME" ]; then
    echo "⚠️  ANDROID_NDK_HOME n'est pas défini"
    echo "💡 Les bibliothèques Swift nécessitent libc++_shared.so"
    echo "   Vous devrez le copier manuellement depuis le NDK"
else
    NDK_LIBCXX="$ANDROID_NDK_HOME/toolchains/llvm/prebuilt"
    
    # Trouver le dossier selon l'OS
    if [ -d "$NDK_LIBCXX/darwin-x86_64" ]; then
        NDK_PREBUILT="$NDK_LIBCXX/darwin-x86_64"
    elif [ -d "$NDK_LIBCXX/linux-x86_64" ]; then
        NDK_PREBUILT="$NDK_LIBCXX/linux-x86_64"
    else
        NDK_PREBUILT=$(find "$NDK_LIBCXX" -type d -maxdepth 1 | head -n 1)
    fi
    
    if [ -n "$NDK_PREBUILT" ]; then
        ARCH_LIB_NAME=""
        case $ARCH in
            arm64-v8a)
                ARCH_LIB_NAME="aarch64-linux-android"
                ;;
            x86_64)
                ARCH_LIB_NAME="x86_64-linux-android"
                ;;
        esac
        
        if [ -n "$ARCH_LIB_NAME" ]; then
            LIBCXX_PATH="$NDK_PREBUILT/sysroot/usr/lib/$ARCH_LIB_NAME/libc++_shared.so"
            if [ -f "$LIBCXX_PATH" ]; then
                cp "$LIBCXX_PATH" "$JNI_LIBS_DIR/$ARCH/"
                echo "✅ libc++_shared.so copié"
            else
                echo "⚠️  libc++_shared.so non trouvé à: $LIBCXX_PATH"
            fi
        fi
    fi
fi

echo ""
echo "✅ Bibliothèques Swift compilées et copiées avec succès !"
echo "📁 Emplacement: $JNI_LIBS_DIR/$ARCH/"
echo ""
echo "📋 Prochaines étapes :"
echo "1. Compilez pour l'autre architecture si nécessaire:"
echo "   ./build-swift-libs.sh x86_64"
echo "2. Compilez l'app Android:"
echo "   ./build-android-app.sh"

