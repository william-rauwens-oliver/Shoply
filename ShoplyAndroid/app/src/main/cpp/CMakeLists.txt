# CMakeLists.txt pour lier les bibliothèques Swift

cmake_minimum_required(VERSION 3.18.1)
project("ShoplyCore")

# Chemin vers les bibliothèques Swift compilées
set(SWIFT_LIB_DIR "${CMAKE_SOURCE_DIR}/../../../../swift/.build/android-${ANDROID_ABI}")

# Charger la bibliothèque Swift compilée
add_library(ShoplyCore SHARED IMPORTED)
set_target_properties(ShoplyCore PROPERTIES
    IMPORTED_LOCATION "${SWIFT_LIB_DIR}/libShoplyCore.so"
)

# Note: La bibliothèque Swift doit être compilée séparément avec le Swift SDK Android
# Voir scripts/build-swift-libs.sh

