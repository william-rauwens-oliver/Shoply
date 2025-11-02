package com.shoply.app.ui.screens

import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.shoply.app.core.ShoplyCore
import com.shoply.app.ui.components.*
import com.shoply.app.ui.theme.AppColors
import java.text.SimpleDateFormat
import java.util.*

/**
 * HomeScreen - MINIMUM Kotlin
 * Appelle TOUT le code Swift via ShoplyCore
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(navController: NavController, isDark: Boolean = MaterialTheme.colorScheme.background == AppColors.backgroundDark) {
    // Appelle le code SWIFT !
    val outfits = remember { ShoplyCore.getAllOutfits() }
    val profile = remember { ShoplyCore.getUserProfile() }
    
    val greeting = remember { getGreeting() }
    val formattedDate = remember { getFormattedDate() }
    
    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        "Shoply",
                        fontWeight = FontWeight.Bold,
                        style = MaterialTheme.typography.titleLarge
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = AppColors.background(isDark)
                ),
                actions = {
                    IconButton(onClick = { navController.navigate("favorites") }) {
                        Icon(
                            Icons.Default.Favorite,
                            contentDescription = "Favoris",
                            tint = AppColors.primaryText(isDark)
                        )
                    }
                    IconButton(onClick = { navController.navigate("profile") }) {
                        Icon(
                            Icons.Default.Person,
                            contentDescription = "Profil",
                            tint = AppColors.primaryText(isDark)
                        )
                    }
                }
            )
        },
        floatingActionButton = {
            FloatingChatButton(navController = navController, isDark = isDark)
        }
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .background(AppColors.background(isDark))
        ) {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = 20.dp)
                    .padding(top = 20.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // En-tête avec salutation (logique Swift via ShoplyCore)
                HeaderSection(
                    greeting = greeting,
                    date = formattedDate,
                    userName = profile?.firstName ?: "",
                    isDark = isDark
                )
                    .padding(bottom = 16.dp)
                
                // Carte principale - Sélection intelligente
                SmartSelectionCard(
                    onClick = { navController.navigate("smart_selection") },
                    isDark = isDark
                )
                
                // Deux colonnes
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    WardrobeCard(
                        onClick = { navController.navigate("wardrobe") },
                        modifier = Modifier.weight(1f),
                        isDark = isDark
                    )
                    
                    HistoryCard(
                        onClick = { navController.navigate("history") },
                        modifier = Modifier.weight(1f),
                        isDark = isDark
                    )
                }
                
                // Calendrier
                CalendarCard(
                    onClick = { navController.navigate("calendar") },
                    isDark = isDark
                )
                
                Spacer(modifier = Modifier.height(120.dp))
            }
        }
    }
}

@Composable
private fun HeaderSection(greeting: String, date: String, userName: String, isDark: Boolean) {
    val displayGreeting = if (userName.isNotEmpty()) "$greeting $userName" else greeting
    
    LiquidGlassCard(
        cornerRadius = 20.dp,
        isDark = isDark
    ) {
        Column(
            modifier = Modifier.padding(24.dp),
            horizontalAlignment = Alignment.Start
        ) {
            Text(
                text = displayGreeting,
                style = MaterialTheme.typography.headlineLarge,
                fontWeight = FontWeight.Bold,
                color = AppColors.primaryText(isDark)
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = date,
                style = MaterialTheme.typography.bodyLarge,
                color = AppColors.secondaryText(isDark)
            )
        }
    }
}

private fun getGreeting(): String {
    val hour = Calendar.getInstance().get(Calendar.HOUR_OF_DAY)
    return when (hour) {
        in 5..11 -> "Bonjour"
        in 12..17 -> "Bon après-midi"
        in 18..21 -> "Bonsoir"
        else -> "Bonne nuit"
    }
}

private fun getFormattedDate(): String {
    val formatter = SimpleDateFormat("EEEE d MMMM", Locale.FRENCH)
    return formatter.format(Date()).replaceFirstChar { it.uppercaseChar() }
}
