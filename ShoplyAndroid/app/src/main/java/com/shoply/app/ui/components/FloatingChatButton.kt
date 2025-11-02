package com.shoply.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.unit.dp
import androidx.navigation.NavController
import com.shoply.app.ui.theme.AppColors

/**
 * Bouton chat flottant avec menu (identique iOS FloatingChatButton)
 */
@Composable
fun FloatingChatButton(
    navController: NavController,
    isDark: Boolean,
    modifier: Modifier = Modifier
) {
    var expanded by remember { mutableStateOf(false) }
    
    Box(
        modifier = modifier.padding(16.dp),
        contentAlignment = Alignment.BottomEnd
    ) {
        FloatingActionButton(
            onClick = { expanded = !expanded },
            containerColor = AppColors.buttonPrimary(isDark),
            modifier = Modifier
                .size(56.dp)
                .shadow(
                    elevation = 10.dp,
                    shape = CircleShape,
                    ambientColor = AppColors.buttonPrimary(isDark).copy(alpha = 0.4f),
                    spotColor = AppColors.buttonPrimary(isDark).copy(alpha = 0.3f)
                )
        ) {
            Icon(
                imageVector = Icons.Default.Send,
                contentDescription = "Chat IA",
                tint = AppColors.buttonPrimaryText(isDark)
            )
        }
        
        // Menu dropdown
        DropdownMenu(
            expanded = expanded,
            onDismissRequest = { expanded = false },
            modifier = Modifier
                .background(
                    color = AppColors.cardBackground(isDark),
                    shape = RoundedCornerShape(16.dp)
                )
                .shadow(elevation = 8.dp, shape = RoundedCornerShape(16.dp))
        ) {
            DropdownMenuItem(
                text = { Text("Nouvelle conversation") },
                onClick = {
                    expanded = false
                    navController.navigate("chat_ai")
                },
                leadingIcon = {
                    Icon(Icons.Default.Send, contentDescription = null)
                }
            )
            DropdownMenuItem(
                text = { Text("Historique des conversations") },
                onClick = {
                    expanded = false
                    navController.navigate("chat_conversations")
                },
                leadingIcon = {
                    Icon(Icons.Default.AccessTime, contentDescription = null)
                }
            )
        }
    }
}

