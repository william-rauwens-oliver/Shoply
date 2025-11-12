import { Platform, StyleSheet } from 'react-native';

// MARK: - Espacements
export const Spacing = {
  xs: 4,
  sm: 8,
  md: 16,
  lg: 24,
  xl: 32,
  xxl: 40,
};

// MARK: - Rayons de coins
export const Radius = {
  sm: 8,
  md: 12,
  lg: 16,
  xl: 20,
};

// MARK: - Typographie
export const Typography = {
  largeTitle: {
    fontSize: 34,
    fontWeight: '700' as const,
    lineHeight: 41,
  },
  title: {
    fontSize: 28,
    fontWeight: '700' as const,
    lineHeight: 34,
  },
  title2: {
    fontSize: 22,
    fontWeight: '600' as const,
    lineHeight: 28,
  },
  headline: {
    fontSize: 17,
    fontWeight: '600' as const,
    lineHeight: 22,
  },
  body: {
    fontSize: 17,
    fontWeight: '400' as const,
    lineHeight: 22,
  },
  callout: {
    fontSize: 16,
    fontWeight: '400' as const,
    lineHeight: 21,
  },
  subheadline: {
    fontSize: 15,
    fontWeight: '400' as const,
    lineHeight: 20,
  },
  footnote: {
    fontSize: 13,
    fontWeight: '400' as const,
    lineHeight: 18,
  },
  caption: {
    fontSize: 12,
    fontWeight: '400' as const,
    lineHeight: 16,
  },
};

// MARK: - Couleurs (Noir & Blanc pour iOS, One UI 7 pour Android)
export const AppColors = {
  // Fond
  background: Platform.select({
    ios: '#FFFFFF',
    android: '#FFFFFF', // One UI 7 utilise aussi le blanc en mode clair
  }),
  backgroundDark: Platform.select({
    ios: '#000000',
    android: '#1C1C1E', // One UI 7 dark mode
  }),

  // Textes
  primaryText: Platform.select({
    ios: '#000000',
    android: '#000000',
  }),
  primaryTextDark: Platform.select({
    ios: '#FFFFFF',
    android: '#FFFFFF',
  }),
  secondaryText: Platform.select({
    ios: '#4D4D4D',
    android: '#6E6E73', // One UI 7 secondary text
  }),
  secondaryTextDark: Platform.select({
    ios: '#B3B3B3',
    android: '#AEAEB2',
  }),
  tertiaryText: Platform.select({
    ios: '#808080',
    android: '#8E8E93',
  }),

  // Cartes
  cardBackground: Platform.select({
    ios: '#FFFFFF',
    android: '#FFFFFF',
  }),
  cardBackgroundDark: Platform.select({
    ios: '#0D0D0D',
    android: '#2C2C2E', // One UI 7 card background
  }),
  cardBorder: Platform.select({
    ios: '#333333',
    android: '#E5E5EA',
  }),
  cardBorderDark: Platform.select({
    ios: '#333333',
    android: '#38383A',
  }),
  separator: Platform.select({
    ios: '#1A1A1A',
    android: '#C6C6C8',
  }),
  separatorDark: Platform.select({
    ios: '#1A1A1A',
    android: '#38383A',
  }),

  // Boutons
  buttonPrimary: Platform.select({
    ios: '#000000',
    android: '#000000',
  }),
  buttonPrimaryDark: Platform.select({
    ios: '#FFFFFF',
    android: '#FFFFFF',
  }),
  buttonPrimaryText: Platform.select({
    ios: '#FFFFFF',
    android: '#FFFFFF',
  }),
  buttonPrimaryTextDark: Platform.select({
    ios: '#000000',
    android: '#000000',
  }),
  buttonSecondary: Platform.select({
    ios: '#F2F2F7',
    android: '#F2F2F7',
  }),
  buttonSecondaryDark: Platform.select({
    ios: '#292929',
    android: '#2C2C2E', // One UI 7 secondary button
  }),
  buttonSecondaryText: Platform.select({
    ios: '#000000',
    android: '#000000',
  }),
  buttonSecondaryTextDark: Platform.select({
    ios: '#FFFFFF',
    android: '#FFFFFF',
  }),

  // Accents
  accent: Platform.select({
    ios: '#333333',
    android: '#333333',
  }),
  accentDark: Platform.select({
    ios: '#CCCCCC',
    android: '#CCCCCC',
  }),
  shadow: Platform.select({
    ios: 'rgba(0, 0, 0, 0.1)',
    android: 'rgba(0, 0, 0, 0.1)',
  }),
  shadowDark: Platform.select({
    ios: 'rgba(0, 0, 0, 0.3)',
    android: 'rgba(0, 0, 0, 0.3)',
  }),
};

// MARK: - Styles de base
export const baseStyles = StyleSheet.create({
  container: {
    flex: 1,
  },
  card: {
    borderRadius: Radius.md,
    padding: Spacing.md,
    backgroundColor: AppColors.cardBackground,
  },
  cardDark: {
    backgroundColor: AppColors.cardBackgroundDark,
  },
  primaryButton: {
    backgroundColor: AppColors.buttonPrimary,
    borderRadius: Radius.md,
    paddingVertical: Spacing.md,
    paddingHorizontal: Spacing.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  primaryButtonDark: {
    backgroundColor: AppColors.buttonPrimaryDark,
  },
  primaryButtonText: {
    color: AppColors.buttonPrimaryText,
    ...Typography.headline,
  },
  primaryButtonTextDark: {
    color: AppColors.buttonPrimaryTextDark,
  },
  secondaryButton: {
    backgroundColor: AppColors.buttonSecondary,
    borderRadius: Radius.md,
    paddingVertical: Spacing.md,
    paddingHorizontal: Spacing.lg,
    alignItems: 'center',
    justifyContent: 'center',
  },
  secondaryButtonDark: {
    backgroundColor: AppColors.buttonSecondaryDark,
  },
  secondaryButtonText: {
    color: AppColors.buttonSecondaryText,
    ...Typography.headline,
  },
  secondaryButtonTextDark: {
    color: AppColors.buttonSecondaryTextDark,
  },
});

// MARK: - Helpers pour obtenir les couleurs selon le thème
export const getColors = (isDark: boolean) => ({
  background: isDark ? AppColors.backgroundDark : AppColors.background,
  primaryText: isDark ? AppColors.primaryTextDark : AppColors.primaryText,
  secondaryText: isDark ? AppColors.secondaryTextDark : AppColors.secondaryText,
  cardBackground: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
  cardBorder: isDark ? AppColors.cardBorderDark : AppColors.cardBorder,
  separator: isDark ? AppColors.separatorDark : AppColors.separator,
  buttonPrimary: isDark ? AppColors.buttonPrimaryDark : AppColors.buttonPrimary,
  buttonPrimaryText: isDark
    ? AppColors.buttonPrimaryTextDark
    : AppColors.buttonPrimaryText,
  buttonSecondary: isDark
    ? AppColors.buttonSecondaryDark
    : AppColors.buttonSecondary,
  buttonSecondaryText: isDark
    ? AppColors.buttonSecondaryTextDark
    : AppColors.buttonSecondaryText,
  shadow: isDark ? AppColors.shadowDark : AppColors.shadow,
});

