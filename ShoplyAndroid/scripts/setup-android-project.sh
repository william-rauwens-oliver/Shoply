#!/bin/bash

# Script pour créer la structure de base du projet Android
# Usage: ./setup-android-project.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "🚀 Configuration du projet Android Shoply..."

# Créer la structure de dossiers
echo "📁 Création de la structure de dossiers..."

mkdir -p "$PROJECT_ROOT/app/src/main/java/com/shoply/app"
mkdir -p "$PROJECT_ROOT/app/src/main/jniLibs/arm64-v8a"
mkdir -p "$PROJECT_ROOT/app/src/main/jniLibs/x86_64"
mkdir -p "$PROJECT_ROOT/app/src/main/res/layout"
mkdir -p "$PROJECT_ROOT/app/src/main/res/values"
mkdir -p "$PROJECT_ROOT/app/src/main/res/drawable"
mkdir -p "$PROJECT_ROOT/swift/Sources/ShoplyCore"
mkdir -p "$PROJECT_ROOT/scripts"
mkdir -p "$PROJECT_ROOT/build/swift"
mkdir -p "$PROJECT_ROOT/build/android"

echo "✅ Structure de dossiers créée"

# Créer le fichier build.gradle principal
echo "📝 Création de build.gradle..."
cat > "$PROJECT_ROOT/build.gradle" << 'EOF'
buildscript {
    ext.kotlin_version = "1.9.20"
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath "com.android.tools.build:gradle:8.1.0"
        classpath "org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version"
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

task clean(type: Delete) {
    delete rootProject.buildDir
}
EOF

# Créer settings.gradle
cat > "$PROJECT_ROOT/settings.gradle" << 'EOF'
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "Shoply"
include ':app'
EOF

# Créer le build.gradle de l'app
echo "📝 Création de app/build.gradle..."
cat > "$PROJECT_ROOT/app/build.gradle" << 'EOF'
plugins {
    id 'com.android.application'
    id 'org.jetbrains.kotlin.android'
}

android {
    namespace 'com.shoply.app'
    compileSdk 34

    defaultConfig {
        applicationId "com.shoply.app"
        minSdk 28
        targetSdk 34
        versionCode 1
        versionName "1.0.0"

        testInstrumentationRunner "androidx.test.runner.AndroidJUnitRunner"
        ndk {
            abiFilters 'arm64-v8a', 'x86_64'
        }
    }

    buildTypes {
        release {
            minifyEnabled false
            proguardFiles getDefaultProguardFile('proguard-android-optimize.txt'), 'proguard-rules.pro'
        }
    }
    
    compileOptions {
        sourceCompatibility JavaVersion.VERSION_1_8
        targetCompatibility JavaVersion.VERSION_1_8
    }
    
    kotlinOptions {
        jvmTarget = '1.8'
    }
}

dependencies {
    implementation 'androidx.core:core-ktx:1.12.0'
    implementation 'androidx.appcompat:appcompat:1.6.1'
    implementation 'com.google.android.material:material:1.10.0'
    implementation 'androidx.constraintlayout:constraintlayout:2.1.4'
    
    // Jetpack Compose (optionnel, pour une UI moderne)
    implementation platform('androidx.compose:compose-bom:2023.10.01')
    implementation 'androidx.compose.ui:ui'
    implementation 'androidx.compose.ui:ui-tooling-preview'
    implementation 'androidx.compose.material3:material3'
    
    testImplementation 'junit:junit:4.13.2'
    androidTestImplementation 'androidx.test.ext:junit:1.1.5'
    androidTestImplementation 'androidx.test.espresso:espresso-core:3.5.1'
}
EOF

# Créer AndroidManifest.xml
echo "📝 Création de AndroidManifest.xml..."
cat > "$PROJECT_ROOT/app/src/main/AndroidManifest.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    xmlns:tools="http://schemas.android.com/tools">

    <application
        android:allowBackup="true"
        android:icon="@mipmap/ic_launcher"
        android:label="@string/app_name"
        android:roundIcon="@mipmap/ic_launcher_round"
        android:supportsRtl="true"
        android:theme="@style/Theme.Shoply"
        tools:targetApi="31">
        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:theme="@style/Theme.Shoply">
            <intent-filter>
                <action android:name="android.intent.action.MAIN" />
                <category android:name="android.intent.category.LAUNCHER" />
            </intent-filter>
        </activity>
    </application>

</manifest>
EOF

# Créer strings.xml
echo "📝 Création de strings.xml..."
cat > "$PROJECT_ROOT/app/src/main/res/values/strings.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="app_name">Shoply</string>
    <string name="welcome">Bienvenue sur Shoply</string>
    <string name="subtitle">Votre assistant style intelligent</string>
</resources>
EOF

# Créer styles.xml
cat > "$PROJECT_ROOT/app/src/main/res/values/themes.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="Theme.Shoply" parent="Theme.MaterialComponents.DayNight.DarkActionBar">
        <item name="colorPrimary">@color/purple_500</item>
        <item name="colorPrimaryVariant">@color/purple_700</item>
        <item name="colorOnPrimary">@color/white</item>
        <item name="colorSecondary">@color/teal_200</item>
        <item name="colorSecondaryVariant">@color/teal_700</item>
        <item name="colorOnSecondary">@color/black</item>
        <item name="android:statusBarColor">?attr/colorPrimaryVariant</item>
    </style>
</resources>
EOF

# Créer colors.xml
cat > "$PROJECT_ROOT/app/src/main/res/values/colors.xml" << 'EOF'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="purple_200">#FFBB86FC</color>
    <color name="purple_500">#FF6200EE</color>
    <color name="purple_700">#FF3700B3</color>
    <color name="teal_200">#FF03DAC5</color>
    <color name="teal_700">#FF018786</color>
    <color name="black">#FF000000</color>
    <color name="white">#FFFFFFFF</color>
</resources>
EOF

echo "✅ Projet Android de base créé avec succès !"
echo ""
echo "📋 Prochaines étapes :"
echo "1. Ouvrez le projet dans Android Studio"
echo "2. Exécutez ./scripts/build-swift-libs.sh pour compiler les bibliothèques Swift"
echo "3. Créez MainActivity.kt pour l'interface utilisateur"
echo ""
echo "📖 Consultez README.md pour plus d'informations"

