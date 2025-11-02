package com.shoply.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OutfitDetailScreen(navController: NavController, outfitId: String) {
    // En production, charger depuis Swift
    val outfit = remember {
        generateSampleOutfits().find { it.id == outfitId }
            ?: generateSampleOutfits().first()
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Détails de l'outfit") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Retour")
                    }
                },
                actions = {
                    IconButton(onClick = { /* Favoris */ }) {
                        Icon(Icons.Default.FavoriteBorder, contentDescription = "Favoris")
                    }
                }
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { /* Sélectionner */ },
                icon = { Icon(Icons.Default.Check, contentDescription = null) },
                text = { Text("Sélectionner cet outfit") }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = outfit.name,
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )
            
            Text(
                text = outfit.description,
                style = MaterialTheme.typography.bodyLarge
            )
            
            Card(modifier = Modifier.fillMaxWidth()) {
                Column(modifier = Modifier.padding(16.dp)) {
                    DetailRow("Confort", "${outfit.comfortLevel}/5")
                    DetailRow("Style", "${outfit.styleLevel}/5")
                }
            }
        }
    }
}

@Composable
fun DetailRow(label: String, value: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(label, style = MaterialTheme.typography.bodyMedium)
        Text(value, style = MaterialTheme.typography.bodyMedium, fontWeight = FontWeight.Bold)
    }
}

