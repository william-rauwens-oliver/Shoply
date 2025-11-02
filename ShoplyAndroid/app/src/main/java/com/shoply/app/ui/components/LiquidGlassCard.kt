package com.shoply.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.shoply.app.ui.theme.AppColors

/**
 * Carte avec effet Liquid Glass (identique au design iOS)
 */
@Composable
fun LiquidGlassCard(
    modifier: Modifier = Modifier,
    cornerRadius: androidx.compose.ui.unit.Dp = 20.dp,
    isDark: Boolean = MaterialTheme.colorScheme.background == AppColors.backgroundDark,
    content: @Composable ColumnScope.() -> Unit
) {
    Column(
        modifier = modifier
            .background(
                brush = Brush.linearGradient(
                    colors = listOf(
                        AppColors.cardBackground(isDark).copy(alpha = 0.95f),
                        AppColors.cardBackground(isDark).copy(alpha = 0.9f)
                    )
                ),
                shape = RoundedCornerShape(cornerRadius)
            )
            .border(
                width = 0.5.dp,
                brush = Brush.linearGradient(
                    colors = listOf(
                        AppColors.cardBorder(isDark).copy(alpha = 0.3f),
                        AppColors.cardBorder(isDark).copy(alpha = 0.1f)
                    )
                ),
                shape = RoundedCornerShape(cornerRadius)
            )
            .shadow(
                elevation = 12.dp,
                shape = RoundedCornerShape(cornerRadius),
                ambientColor = AppColors.shadow(isDark).copy(alpha = 0.08f),
                spotColor = AppColors.shadow(isDark).copy(alpha = 0.15f)
            )
            .clip(RoundedCornerShape(cornerRadius)),
        content = content
    )
}

