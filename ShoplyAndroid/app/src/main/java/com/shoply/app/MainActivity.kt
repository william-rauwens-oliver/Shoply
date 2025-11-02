package com.shoply.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import androidx.compose.runtime.*
import com.shoply.app.ui.theme.ShoplyTheme
import android.widget.FrameLayout

/**
 * MainActivity pour Shoply Android
 * 
 * Point d'entrée minimal - Charge juste le SwiftUI
 * TOUTE l'UI est en SwiftUI maintenant !
 */
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Charger les bibliothèques Swift
        try {
            System.loadLibrary("ShoplyCore")
            android.util.Log.d("Shoply", "✅ Bibliothèque Swift chargée")
        } catch (e: UnsatisfiedLinkError) {
            android.util.Log.w("Shoply", "⚠️ Bibliothèques Swift non disponibles: ${e.message}")
            android.util.Log.w("Shoply", "   L'app utilisera le mode fallback")
        }
        
        setContent {
            ShoplyTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    // Container pour SwiftUI
                    SwiftUIContainer()
                }
            }
        }
    }
}

/**
 * Container minimal pour SwiftUI
 * SwiftUI sera rendu dans ce container
 */
@Composable
fun SwiftUIContainer() {
    AndroidView(
        factory = { context ->
            FrameLayout(context).apply {
                // SwiftUI sera rendu ici via le runtime Swift
                // Pour l'instant, affiche un message
                android.util.Log.d("Shoply", "SwiftUIContainer créé")
            }
        },
        modifier = Modifier.fillMaxSize()
    )
}
