export enum WardrobeCategory {
  TOPS = 'Hauts',
  BOTTOMS = 'Bas',
  SHOES = 'Chaussures',
  ACCESSORIES = 'Accessoires',
  OUTERWEAR = 'Manteaux',
  UNDERWEAR = 'Sous-vêtements',
}

export enum WardrobeColor {
  BLACK = 'Noir',
  WHITE = 'Blanc',
  GRAY = 'Gris',
  BROWN = 'Marron',
  BEIGE = 'Beige',
  NAVY = 'Bleu marine',
  BLUE = 'Bleu',
  RED = 'Rouge',
  PINK = 'Rose',
  GREEN = 'Vert',
  YELLOW = 'Jaune',
  ORANGE = 'Orange',
  PURPLE = 'Violet',
  MULTICOLOR = 'Multicolore',
}

export interface WardrobeItem {
  id: string;
  name: string;
  category: WardrobeCategory;
  color: WardrobeColor;
  brand?: string;
  size?: string;
  purchaseDate?: Date | string;
  purchasePrice?: number;
  photoUri?: string;
  notes?: string;
  tags: string[];
  wearCount: number;
  lastWorn?: Date | string;
  createdAt: Date | string;
  updatedAt: Date | string;
}

export const createDefaultWardrobeItem = (): WardrobeItem => ({
  id: Date.now().toString(),
  name: '',
  category: WardrobeCategory.TOPS,
  color: WardrobeColor.BLACK,
  tags: [],
  wearCount: 0,
  createdAt: new Date().toISOString(),
  updatedAt: new Date().toISOString(),
});

