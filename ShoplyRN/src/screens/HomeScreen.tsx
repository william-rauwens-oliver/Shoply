import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  TouchableOpacity,
  Image,
} from 'react-native';
import { SafeAreaView } from 'react-native-safe-area-context';
import { useTheme } from '../theme/ThemeContext';
import { Typography, Spacing, Radius } from '../theme/DesignSystem';
import { Card } from '../components/Card';
import { Button } from '../components/Button';
import { loadUserProfile } from '../utils/storage';
import { UserProfile } from '../models/UserProfile';

interface HomeScreenProps {
  navigation: any;
}

export const HomeScreen: React.FC<HomeScreenProps> = ({ navigation }) => {
  const { colors } = useTheme();
  const [userProfile, setUserProfile] = useState<UserProfile | null>(null);
  const [currentTime, setCurrentTime] = useState(new Date());

  useEffect(() => {
    loadUserData();
    const timer = setInterval(() => {
      setCurrentTime(new Date());
    }, 60000);
    return () => clearInterval(timer);
  }, []);

  const loadUserData = async () => {
    const profile = await loadUserProfile();
    setUserProfile(profile);
  };

  const getGreeting = () => {
    const hour = currentTime.getHours();
    if (hour >= 6 && hour < 19) {
      return 'Bonjour';
    }
    return 'Bonsoir';
  };

  const formatDate = () => {
    return currentTime.toLocaleDateString('fr-FR', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric',
    });
  };

  return (
    <SafeAreaView
      style={[styles.container, { backgroundColor: colors.background }]}
      edges={['top']}
    >
      <ScrollView
        showsVerticalScrollIndicator={false}
        contentContainerStyle={styles.scrollContent}
      >
        {/* Header */}
        <View style={styles.header}>
          <View style={styles.headerContent}>
            {userProfile?.profilePhotoUri ? (
              <Image
                source={{ uri: userProfile.profilePhotoUri }}
                style={styles.profileImage}
              />
            ) : (
              <View
                style={[
                  styles.profileImagePlaceholder,
                  { backgroundColor: colors.buttonSecondary },
                ]}
              >
                <Text style={[styles.profileIcon, { color: colors.buttonPrimary }]}>
                  👤
                </Text>
              </View>
            )}
            <View style={styles.headerText}>
              <Text
                style={[styles.greeting, { color: colors.primaryText }]}
                numberOfLines={1}
              >
                {userProfile?.firstName
                  ? `${getGreeting()}, ${userProfile.firstName}`
                  : getGreeting()}
              </Text>
              <Text style={[styles.date, { color: colors.secondaryText }]}>
                {formatDate()}
              </Text>
            </View>
          </View>
          <View style={styles.headerActions}>
            <TouchableOpacity
              onPress={() => navigation.navigate('Favorites')}
              style={styles.iconButton}
            >
              <Text style={[styles.icon, { color: colors.primaryText }]}>❤️</Text>
            </TouchableOpacity>
            <TouchableOpacity
              onPress={() => navigation.navigate('Profile')}
              style={styles.iconButton}
            >
              {userProfile?.profilePhotoUri ? (
                <Image
                  source={{ uri: userProfile.profilePhotoUri }}
                  style={styles.smallProfileImage}
                />
              ) : (
                <Text style={[styles.icon, { color: colors.primaryText }]}>👤</Text>
              )}
            </TouchableOpacity>
          </View>
        </View>

        {/* Main Action Card */}
        <TouchableOpacity
          onPress={() => navigation.navigate('SmartOutfitSelection')}
          activeOpacity={0.7}
        >
          <Card style={styles.mainActionCard}>
            <View style={styles.mainActionContent}>
              <View
                style={[
                  styles.mainActionIcon,
                  { backgroundColor: colors.buttonSecondary },
                ]}
              >
                <Text style={[styles.mainActionIconText, { color: colors.buttonPrimary }]}>
                  ✨
                </Text>
              </View>
              <View style={styles.mainActionText}>
                <Text
                  style={[styles.mainActionTitle, { color: colors.primaryText }]}
                >
                  Sélection Intelligente
                </Text>
                <Text
                  style={[styles.mainActionSubtitle, { color: colors.secondaryText }]}
                >
                  Générez des outfits adaptés
                </Text>
              </View>
              <Text style={[styles.chevron, { color: colors.secondaryText }]}>
                ›
              </Text>
            </View>
          </Card>
        </TouchableOpacity>

        {/* Quick Access */}
        <View style={styles.quickAccess}>
          <Text style={[styles.sectionTitle, { color: colors.primaryText }]}>
            Accès rapide
          </Text>
          <View style={styles.quickAccessGrid}>
            {quickAccessItems.map((item) => (
              <TouchableOpacity
                key={item.id}
                onPress={() => navigation.navigate(item.screen)}
                style={styles.quickAccessItem}
                activeOpacity={0.7}
              >
                <View
                  style={[
                    styles.quickAccessIcon,
                    { backgroundColor: colors.buttonSecondary },
                  ]}
                >
                  <Text style={{ fontSize: 24 }}>{item.icon}</Text>
                </View>
                <Text
                  style={[styles.quickAccessText, { color: colors.primaryText }]}
                  numberOfLines={1}
                >
                  {item.title}
                </Text>
              </TouchableOpacity>
            ))}
          </View>
        </View>
      </ScrollView>

      {/* Floating Chat Button */}
      <View style={styles.floatingButtonContainer}>
        <TouchableOpacity
          style={[
            styles.floatingButton,
            { backgroundColor: colors.buttonPrimary },
          ]}
          onPress={() => navigation.navigate('ChatAI')}
          activeOpacity={0.8}
        >
          <Text style={[styles.floatingButtonIcon, { color: colors.buttonPrimaryText }]}>
            💬
          </Text>
        </TouchableOpacity>
      </View>
    </SafeAreaView>
  );
};

const quickAccessItems = [
  { id: '1', icon: '👕', title: 'Garde-robe', screen: 'Wardrobe' },
  { id: '2', icon: '🕐', title: 'Historique', screen: 'OutfitHistory' },
  { id: '3', icon: '📁', title: 'Collections', screen: 'Collections' },
  { id: '4', icon: '❤️', title: 'Wishlist', screen: 'Wishlist' },
  { id: '5', icon: '✈️', title: 'Voyage', screen: 'TravelMode' },
  { id: '6', icon: '💼', title: 'Occasions', screen: 'Occasions' },
  { id: '7', icon: '📅', title: 'Calendrier', screen: 'OutfitCalendar' },
  { id: '8', icon: '⭐', title: 'Badges', screen: 'Gamification' },
];

const styles = StyleSheet.create({
  container: {
    flex: 1,
  },
  scrollContent: {
    paddingHorizontal: Spacing.md,
    paddingTop: Spacing.md,
    paddingBottom: 100,
  },
  header: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginBottom: Spacing.xl,
  },
  headerContent: {
    flexDirection: 'row',
    alignItems: 'center',
    flex: 1,
  },
  profileImage: {
    width: 64,
    height: 64,
    borderRadius: 32,
    marginRight: Spacing.md,
  },
  profileImagePlaceholder: {
    width: 64,
    height: 64,
    borderRadius: 32,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: Spacing.md,
  },
  profileIcon: {
    fontSize: 28,
  },
  headerText: {
    flex: 1,
  },
  greeting: {
    ...Typography.largeTitle,
    marginBottom: 4,
  },
  date: {
    ...Typography.subheadline,
  },
  headerActions: {
    flexDirection: 'row',
    gap: Spacing.md,
  },
  iconButton: {
    width: 32,
    height: 32,
    justifyContent: 'center',
    alignItems: 'center',
  },
  icon: {
    fontSize: 20,
  },
  smallProfileImage: {
    width: 32,
    height: 32,
    borderRadius: 16,
  },
  mainActionCard: {
    marginBottom: Spacing.xl,
  },
  mainActionContent: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  mainActionIcon: {
    width: 60,
    height: 60,
    borderRadius: 30,
    justifyContent: 'center',
    alignItems: 'center',
    marginRight: Spacing.md,
  },
  mainActionIconText: {
    fontSize: 28,
  },
  mainActionText: {
    flex: 1,
  },
  mainActionTitle: {
    ...Typography.title2,
    marginBottom: 4,
  },
  mainActionSubtitle: {
    ...Typography.caption,
  },
  chevron: {
    fontSize: 24,
    fontWeight: '300',
  },
  quickAccess: {
    marginTop: Spacing.lg,
  },
  sectionTitle: {
    ...Typography.headline,
    marginBottom: Spacing.md,
    paddingHorizontal: 4,
  },
  quickAccessGrid: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    gap: Spacing.sm,
  },
  quickAccessItem: {
    width: '23%',
    alignItems: 'center',
    paddingVertical: Spacing.md,
  },
  quickAccessIcon: {
    width: 50,
    height: 50,
    borderRadius: 25,
    justifyContent: 'center',
    alignItems: 'center',
    marginBottom: Spacing.sm,
  },
  quickAccessText: {
    ...Typography.caption,
    textAlign: 'center',
  },
  floatingButtonContainer: {
    position: 'absolute',
    bottom: Spacing.md,
    right: Spacing.md,
  },
  floatingButton: {
    width: 56,
    height: 56,
    borderRadius: 28,
    justifyContent: 'center',
    alignItems: 'center',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 6 },
    shadowOpacity: 0.3,
    shadowRadius: 12,
    elevation: 8,
  },
  floatingButtonIcon: {
    fontSize: 22,
  },
});

