package com.shoply.app.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * Palette de couleurs Shoply - Identique à iOS
 * Design Liquid Glass avec support mode sombre/clair
 */
object AppColors {
    // Fond
    val backgroundLight = Color(0xFFFFFFFF)
    val backgroundDark = Color(0xFF000000)
    
    // Textes
    val primaryTextLight = Color(0xFF000000)
    val primaryTextDark = Color(0xFFFFFFFF)
    val secondaryTextLight = Color(0xFF666666)
    val secondaryTextDark = Color(0xFF999999)
    
    // Cartes
    val cardBackgroundLight = Color(0xFFFFFFFF)
    val cardBackgroundDark = Color(0xFF1A1A1A)
    val cardBorderLight = Color(0xFFE0E0E0)
    val cardBorderDark = Color(0xFF333333)
    
    // Boutons
    val buttonPrimaryLight = Color(0xFF000000)
    val buttonPrimaryDark = Color(0xFFFFFFFF)
    val buttonPrimaryTextLight = Color(0xFFFFFFFF)
    val buttonPrimaryTextDark = Color(0xFF000000)
    val buttonSecondaryLight = Color(0xFFF5F5F5)
    val buttonSecondaryDark = Color(0xFF2A2A2A)
    val buttonSecondaryTextLight = Color(0xFF000000)
    val buttonSecondaryTextDark = Color(0xFFFFFFFF)
    
    // Accents
    val accentLight = Color(0xFFE0E0E0)
    val accentDark = Color(0xFF666666)
    
    // Ombres
    val shadowLight = Color(0x26000000)
    val shadowDark = Color(0x80000000)
    
    // Fonction pour obtenir la couleur selon le thème (shadows)
    fun shadow(isDark: Boolean): Color = if (isDark) shadowDark else shadowLight
    
    // Fonction pour obtenir la couleur selon le thème
    fun background(isDark: Boolean): Color = if (isDark) backgroundDark else backgroundLight
    fun primaryText(isDark: Boolean): Color = if (isDark) primaryTextDark else primaryTextLight
    fun secondaryText(isDark: Boolean): Color = if (isDark) secondaryTextDark else secondaryTextLight
    fun cardBackground(isDark: Boolean): Color = if (isDark) cardBackgroundDark else cardBackgroundLight
    fun cardBorder(isDark: Boolean): Color = if (isDark) cardBorderDark else cardBorderLight
    fun buttonPrimary(isDark: Boolean): Color = if (isDark) buttonPrimaryDark else buttonPrimaryLight
    fun buttonPrimaryText(isDark: Boolean): Color = if (isDark) buttonPrimaryTextDark else buttonPrimaryTextLight
    fun buttonSecondary(isDark: Boolean): Color = if (isDark) buttonSecondaryDark else buttonSecondaryLight
    fun buttonSecondaryText(isDark: Boolean): Color = if (isDark) buttonSecondaryTextDark else buttonSecondaryTextLight
}

