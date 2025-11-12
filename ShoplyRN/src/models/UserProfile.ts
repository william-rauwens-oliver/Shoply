export enum Gender {
  MALE = 'Homme',
  FEMALE = 'Femme',
  NOT_SPECIFIED = 'Non spécifié',
}

export interface UserPreferences {
  preferredStyleRawValue?: string;
  favoriteColors: string[];
  comfortLevel: number; // 1-5
  styleLevel: number; // 1-5
  casualness: number; // 1-5, 1 = très formel, 5 = très décontracté
}

export interface UserProfile {
  firstName: string;
  dateOfBirth?: Date | string;
  gender: Gender;
  email?: string;
  profilePhotoUri?: string;
  backgroundPhotoUri?: string;
  createdAt: Date | string;
  lastWeatherUpdate?: Date | string;
  preferences: UserPreferences;
}

export const createDefaultUserProfile = (): UserProfile => ({
  firstName: '',
  gender: Gender.NOT_SPECIFIED,
  createdAt: new Date().toISOString(),
  preferences: {
    favoriteColors: [],
    comfortLevel: 3,
    styleLevel: 3,
    casualness: 3,
  },
});

