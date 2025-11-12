import AsyncStorage from '@react-native-async-storage/async-storage';
import { UserProfile } from '../models/UserProfile';
import { WardrobeItem } from '../models/WardrobeItem';
import { Outfit } from '../models/Outfit';

const STORAGE_KEYS = {
  USER_PROFILE: '@shoply:user_profile',
  WARDROBE_ITEMS: '@shoply:wardrobe_items',
  OUTFITS: '@shoply:outfits',
  OUTFIT_HISTORY: '@shoply:outfit_history',
  FAVORITES: '@shoply:favorites',
  ONBOARDING_COMPLETED: '@shoply:onboarding_completed',
  TUTORIAL_COMPLETED: '@shoply:tutorial_completed',
};

// User Profile
export const saveUserProfile = async (profile: UserProfile): Promise<void> => {
  try {
    await AsyncStorage.setItem(
      STORAGE_KEYS.USER_PROFILE,
      JSON.stringify(profile),
    );
  } catch (error) {
    console.error('Error saving user profile:', error);
    throw error;
  }
};

export const loadUserProfile = async (): Promise<UserProfile | null> => {
  try {
    const data = await AsyncStorage.getItem(STORAGE_KEYS.USER_PROFILE);
    if (data) {
      return JSON.parse(data);
    }
    return null;
  } catch (error) {
    console.error('Error loading user profile:', error);
    return null;
  }
};

export const deleteUserProfile = async (): Promise<void> => {
  try {
    await AsyncStorage.removeItem(STORAGE_KEYS.USER_PROFILE);
  } catch (error) {
    console.error('Error deleting user profile:', error);
    throw error;
  }
};

// Wardrobe Items
export const saveWardrobeItems = async (
  items: WardrobeItem[],
): Promise<void> => {
  try {
    await AsyncStorage.setItem(
      STORAGE_KEYS.WARDROBE_ITEMS,
      JSON.stringify(items),
    );
  } catch (error) {
    console.error('Error saving wardrobe items:', error);
    throw error;
  }
};

export const loadWardrobeItems = async (): Promise<WardrobeItem[]> => {
  try {
    const data = await AsyncStorage.getItem(STORAGE_KEYS.WARDROBE_ITEMS);
    if (data) {
      return JSON.parse(data);
    }
    return [];
  } catch (error) {
    console.error('Error loading wardrobe items:', error);
    return [];
  }
};

// Outfits
export const saveOutfits = async (outfits: Outfit[]): Promise<void> => {
  try {
    await AsyncStorage.setItem(STORAGE_KEYS.OUTFITS, JSON.stringify(outfits));
  } catch (error) {
    console.error('Error saving outfits:', error);
    throw error;
  }
};

export const loadOutfits = async (): Promise<Outfit[]> => {
  try {
    const data = await AsyncStorage.getItem(STORAGE_KEYS.OUTFITS);
    if (data) {
      return JSON.parse(data);
    }
    return [];
  } catch (error) {
    console.error('Error loading outfits:', error);
    return [];
  }
};

// Outfit History
export const saveOutfitHistory = async (outfits: Outfit[]): Promise<void> => {
  try {
    await AsyncStorage.setItem(
      STORAGE_KEYS.OUTFIT_HISTORY,
      JSON.stringify(outfits),
    );
  } catch (error) {
    console.error('Error saving outfit history:', error);
    throw error;
  }
};

export const loadOutfitHistory = async (): Promise<Outfit[]> => {
  try {
    const data = await AsyncStorage.getItem(STORAGE_KEYS.OUTFIT_HISTORY);
    if (data) {
      return JSON.parse(data);
    }
    return [];
  } catch (error) {
    console.error('Error loading outfit history:', error);
    return [];
  }
};

// Favorites
export const saveFavorites = async (outfitIds: string[]): Promise<void> => {
  try {
    await AsyncStorage.setItem(
      STORAGE_KEYS.FAVORITES,
      JSON.stringify(outfitIds),
    );
  } catch (error) {
    console.error('Error saving favorites:', error);
    throw error;
  }
};

export const loadFavorites = async (): Promise<string[]> => {
  try {
    const data = await AsyncStorage.getItem(STORAGE_KEYS.FAVORITES);
    if (data) {
      return JSON.parse(data);
    }
    return [];
  } catch (error) {
    console.error('Error loading favorites:', error);
    return [];
  }
};

// Onboarding & Tutorial
export const setOnboardingCompleted = async (): Promise<void> => {
  try {
    await AsyncStorage.setItem(STORAGE_KEYS.ONBOARDING_COMPLETED, 'true');
  } catch (error) {
    console.error('Error setting onboarding completed:', error);
  }
};

export const isOnboardingCompleted = async (): Promise<boolean> => {
  try {
    const value = await AsyncStorage.getItem(STORAGE_KEYS.ONBOARDING_COMPLETED);
    return value === 'true';
  } catch (error) {
    console.error('Error checking onboarding status:', error);
    return false;
  }
};

export const setTutorialCompleted = async (): Promise<void> => {
  try {
    await AsyncStorage.setItem(STORAGE_KEYS.TUTORIAL_COMPLETED, 'true');
  } catch (error) {
    console.error('Error setting tutorial completed:', error);
  }
};

export const isTutorialCompleted = async (): Promise<boolean> => {
  try {
    const value = await AsyncStorage.getItem(STORAGE_KEYS.TUTORIAL_COMPLETED);
    return value === 'true';
  } catch (error) {
    console.error('Error checking tutorial status:', error);
    return false;
  }
};

// Clear all data
export const clearAllData = async (): Promise<void> => {
  try {
    await AsyncStorage.multiRemove(Object.values(STORAGE_KEYS));
  } catch (error) {
    console.error('Error clearing all data:', error);
    throw error;
  }
};

