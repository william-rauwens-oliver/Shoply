package com.shoply.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
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
fun SmartOutfitSelectionScreen(navController: NavController) {
    var selectedMood by remember { mutableStateOf("Énergique") }
    var selectedWeather by remember { mutableStateOf("Ensoleillé") }
    
    val moods = listOf("Énergique", "Calme", "Confiant", "Détendu", "Professionnel", "Créatif")
    val weatherTypes = listOf("Ensoleillé", "Nuageux", "Pluvieux", "Froid", "Chaud")
    
    // Simuler des outfits (en production, charger depuis Swift)
    val outfits = remember {
        generateSampleOutfits()
    }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Sélection Intelligente") },
                navigationIcon = {
                    IconButton(onClick = { navController.popBackStack() }) {
                        Icon(Icons.Default.ArrowBack, contentDescription = "Retour")
                    }
                }
            )
        }
    ) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                // Sélection d'humeur
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("Humeur", style = MaterialTheme.typography.titleMedium)
                        MoodSelector(moods, selectedMood) { selectedMood = it }
                    }
                }
            }
            
            item {
                // Sélection météo
                Card(modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(16.dp)) {
                        Text("Météo", style = MaterialTheme.typography.titleMedium)
                        WeatherSelector(weatherTypes, selectedWeather) { selectedWeather = it }
                    }
                }
            }
            
            item {
                Text(
                    "Suggestions d'outfits",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )
            }
            
            items(outfits) { outfit ->
                OutfitCard(outfit = outfit, onClick = {
                    navController.navigate("outfit_detail/${outfit.id}")
                })
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MoodSelector(moods: List<String>, selected: String, onSelect: (String) -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        moods.forEach { mood ->
            FilterChip(
                selected = mood == selected,
                onClick = { onSelect(mood) },
                label = { Text(mood) },
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun WeatherSelector(weatherTypes: List<String>, selected: String, onSelect: (String) -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        weatherTypes.forEach { weather ->
            FilterChip(
                selected = weather == selected,
                onClick = { onSelect(weather) },
                label = { Text(weather) },
                modifier = Modifier.weight(1f)
            )
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun OutfitCard(outfit: SampleOutfit, onClick: () -> Unit) {
    Card(
        onClick = onClick,
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = outfit.name,
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = outfit.description,
                style = MaterialTheme.typography.bodyMedium,
                modifier = Modifier.padding(top = 8.dp)
            )
            Row(
                modifier = Modifier.padding(top = 8.dp),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                InfoChip("Confort: ${outfit.comfortLevel}/5")
                InfoChip("Style: ${outfit.styleLevel}/5")
            }
        }
    }
}

@Composable
fun InfoChip(text: String) {
    Surface(
        color = MaterialTheme.colorScheme.secondaryContainer,
        shape = MaterialTheme.shapes.small
    ) {
        Text(
            text = text,
            modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp),
            style = MaterialTheme.typography.labelSmall
        )
    }
}

data class SampleOutfit(
    val id: String,
    val name: String,
    val description: String,
    val comfortLevel: Int,
    val styleLevel: Int
)

fun generateSampleOutfits(): List<SampleOutfit> {
    return listOf(
        SampleOutfit("1", "Look Dynamique", "Parfait pour une journée active", 5, 4),
        SampleOutfit("2", "Sérénité Urbaine", "Idéal pour une journée de détente", 4, 5),
        SampleOutfit("3", "Élégance Confiante", "Pour impressionner", 3, 5),
        SampleOutfit("4", "Détente Moderne", "Confort et style", 5, 3),
        SampleOutfit("5", "Business Chic", "Professionnel et élégant", 4, 5),
        SampleOutfit("6", "Créatif Original", "Exprimer votre personnalité", 4, 5)
    )
}

