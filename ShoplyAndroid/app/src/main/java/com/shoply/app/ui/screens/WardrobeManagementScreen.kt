package com.shoply.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.shoply.app.core.ShoplyCore

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WardrobeManagementScreen(navController: NavController) {
    // Appelle le code SWIFT !
    val wardrobeItems = remember { ShoplyCore.getWardrobeItems() }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Ma Garde-robe") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Retour")
                    }
                },
                actions = {
                    IconButton(onClick = { /* Ajouter un vêtement */ }) {
                        Icon(Icons.Default.Add, contentDescription = "Ajouter")
                    }
                }
            )
        },
        floatingActionButton = {
            ExtendedFloatingActionButton(
                onClick = { /* Ajouter un vêtement */ },
                icon = { Icon(Icons.Default.Add, contentDescription = null) },
                text = { Text("Ajouter") }
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            item {
                Card(modifier = Modifier.fillMaxWidth()) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
                    ) {
                        Column {
                            Text(
                                text = "${wardrobeItems.size}",
                                style = MaterialTheme.typography.headlineMedium
                            )
                            Text(
                                text = "articles dans votre garde-robe",
                                style = MaterialTheme.typography.bodyMedium
                            )
                        }
                        Icon(
                            imageVector = Icons.Default.CheckCircle,
                            contentDescription = null,
                            modifier = Modifier.size(48.dp)
                        )
                    }
                }
            }
            
            items(wardrobeItems.size) { index ->
                WardrobeItemCard(item = wardrobeItems[index])
            }
        }
    }
}

@Composable
fun WardrobeItemCard(item: com.shoply.app.models.WardrobeItem) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 1.dp)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = androidx.compose.ui.Alignment.CenterVertically
        ) {
            Text(text = item.name, style = MaterialTheme.typography.bodyLarge)
            IconButton(onClick = { /* Actions */ }) {
                Icon(Icons.Default.MoreVert, contentDescription = "Options")
            }
        }
    }
}

