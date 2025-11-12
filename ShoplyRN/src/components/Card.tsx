import React from 'react';
import { View, StyleSheet, ViewStyle } from 'react-native';
import { useTheme } from '../theme/ThemeContext';
import { Radius, Spacing } from '../theme/DesignSystem';

interface CardProps {
  children: React.ReactNode;
  style?: ViewStyle;
  cornerRadius?: number;
}

export const Card: React.FC<CardProps> = ({
  children,
  style,
  cornerRadius = Radius.md,
}) => {
  const { colors } = useTheme();

  return (
    <View
      style={[
        styles.card,
        {
          backgroundColor: colors.cardBackground,
          borderRadius: cornerRadius,
          borderWidth: 1,
          borderColor: colors.cardBorder,
        },
        style,
      ]}
    >
      {children}
    </View>
  );
};

const styles = StyleSheet.create({
  card: {
    padding: Spacing.md,
  },
});

