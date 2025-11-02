package com.shoply.app.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.unit.dp
import com.shoply.app.ui.theme.AppColors

/**
 * Bouton moderne avec style iOS
 */
@Composable
fun ModernButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true,
    isPrimary: Boolean = true,
    isDark: Boolean = MaterialTheme.colorScheme.background == AppColors.backgroundDark
) {
    Box(
        modifier = modifier
            .fillMaxWidth()
            .height(56.dp)
            .background(
                brush = if (isPrimary) {
                    Brush.linearGradient(
                        colors = listOf(
                            AppColors.buttonPrimary(isDark),
                            AppColors.buttonPrimary(isDark).copy(alpha = 0.9f)
                        )
                    )
                } else {
                    Brush.linearGradient(
                        colors = listOf(
                            AppColors.buttonSecondary(isDark),
                            AppColors.buttonSecondary(isDark).copy(alpha = 0.9f)
                        )
                    )
                },
                shape = RoundedCornerShape(16.dp)
            )
            .clip(RoundedCornerShape(16.dp))
            .clickable(enabled = enabled, onClick = onClick)
            .then(
                if (enabled) Modifier else Modifier.alpha(0.6f)
            ),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.titleMedium,
            color = if (isPrimary) {
                AppColors.buttonPrimaryText(isDark)
            } else {
                AppColors.buttonSecondaryText(isDark)
            }
        )
    }
}

