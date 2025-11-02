package com.shoply.app.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.shoply.app.ui.theme.AppColors

@Composable
fun WardrobeCard(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    isDark: Boolean
) {
    LiquidGlassCard(
        cornerRadius = 18.dp,
        isDark = isDark,
        modifier = modifier
            .height(120.dp)
            .clickable(onClick = onClick)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(20.dp),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(
                    verticalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Text(
                        text = "Garde-robe",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.Bold,
                        color = AppColors.primaryText(isDark)
                    )
                    Text(
                        text = "Ajoutez vos vêtements",
                        style = MaterialTheme.typography.bodySmall,
                        color = AppColors.secondaryText(isDark)
                    )
                }
                
                Icon(
                    imageVector = Icons.Default.CheckCircle,
                    contentDescription = null,
                    modifier = Modifier.size(24.dp),
                    tint = AppColors.primaryText(isDark).copy(alpha = 0.7f)
                )
            }
        }
    }
}

