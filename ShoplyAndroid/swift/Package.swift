// swift-tools-version: 6.0
// Package.swift pour Shoply Android
// Code Swift partagé entre iOS et Android

import PackageDescription

let package = Package(
    name: "ShoplyCore",
    platforms: [
        .iOS(.v16),
        .macOS(.v12),
        // Note: Android n'a pas encore de platform défini officiellement
        // Le Swift SDK Android utilise des triples comme aarch64-unknown-linux-android
    ],
    products: [
        .library(
            name: "ShoplyCore",
            targets: ["ShoplyCore"]
        ),
    ],
    dependencies: [
        // Aucune dépendance externe pour Android
        // Toutes les dépendances doivent être compatibles Android
    ],
    targets: [
        .target(
            name: "ShoplyCore",
            dependencies: [],
            path: "Sources"
        ),
        .testTarget(
            name: "ShoplyCoreTests",
            dependencies: ["ShoplyCore"]
        ),
    ]
)

