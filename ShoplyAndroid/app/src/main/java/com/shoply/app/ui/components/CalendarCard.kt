package com.shoply.app.ui.components

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.DateRange
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.shoply.app.ui.theme.AppColors

@Composable
fun CalendarCard(
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    isDark: Boolean
) {
    LiquidGlassCard(
        cornerRadius = 18.dp,
        isDark = isDark,
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column(
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Text(
                    text = "Calendrier",
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = AppColors.primaryText(isDark)
                )
                Text(
                    text = "Planifiez vos outfits à l'avance",
                    style = MaterialTheme.typography.bodyMedium,
                    color = AppColors.secondaryText(isDark)
                )
            }
            
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .clip(CircleShape)
                    .background(AppColors.buttonSecondary(isDark)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.DateRange,
                    contentDescription = null,
                    modifier = Modifier.size(28.dp),
                    tint = AppColors.primaryText(isDark).copy(alpha = 0.7f)
                )
            }
        }
    }
}

