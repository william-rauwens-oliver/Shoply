package com.shoply.app.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.LocationOn
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.shoply.app.ui.theme.AppColors

/**
 * Carte de sélection intelligente (identique iOS)
 */
@Composable
fun SmartSelectionCard(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    isDark: Boolean
) {
    LiquidGlassCard(
        cornerRadius = 20.dp,
        isDark = isDark,
        modifier = modifier.clickable(onClick = onClick)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(28.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Column(
                    modifier = Modifier.weight(1f),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Text(
                        text = "Sélection Intelligente",
                        style = MaterialTheme.typography.headlineSmall,
                        fontWeight = FontWeight.Bold,
                        color = AppColors.primaryText(isDark)
                    )
                    Text(
                        text = "Météo automatique + IA",
                        style = MaterialTheme.typography.bodyMedium,
                        color = AppColors.secondaryText(isDark)
                    )
                }
                
                Icon(
                    imageVector = Icons.Default.Star,
                    contentDescription = null,
                    modifier = Modifier.size(32.dp),
                    tint = AppColors.primaryText(isDark).copy(alpha = 0.6f)
                )
            }
            
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(
                        color = AppColors.buttonPrimary(isDark),
                        shape = RoundedCornerShape(16.dp)
                    )
                    .padding(horizontal = 20.dp, vertical = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(
                    imageVector = Icons.Default.LocationOn,
                    contentDescription = null,
                    modifier = Modifier.size(16.dp),
                    tint = AppColors.buttonPrimaryText(isDark)
                )
                Text(
                    text = "Détection automatique",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium,
                    color = AppColors.buttonPrimaryText(isDark)
                )
            }
        }
    }
}

