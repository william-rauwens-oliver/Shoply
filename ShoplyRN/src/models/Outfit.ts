import { WardrobeItem } from './WardrobeItem';

export enum OutfitType {
  CASUAL = 'Décontracté',
  FORMAL = 'Formel',
  SPORTY = 'Sportif',
  ELEGANT = 'Élégant',
  STREETWEAR = 'Streetwear',
  BUSINESS = 'Business',
  ROMANTIC = 'Romantique',
  TRAVEL = 'Voyage',
}

export interface Outfit {
  id: string;
  name?: string;
  items: WardrobeItem[];
  type: OutfitType;
  weather?: string;
  temperature?: number;
  occasion?: string;
  notes?: string;
  rating?: number; // 1-5
  isFavorite: boolean;
  wornDate?: Date | string;
  createdAt: Date | string;
  updatedAt: Date | string;
}

export const createDefaultOutfit = (): Outfit => ({
  id: Date.now().toString(),
  items: [],
  type: OutfitType.CASUAL,
  isFavorite: false,
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
});

