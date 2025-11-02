# Guide : Intégration Python pour IA Locale

## Option : Utiliser Python pour une IA plus avancée

Si vous voulez une IA locale encore plus intelligente, vous pouvez créer un serveur Python qui communique avec votre app Swift.

### Étape 1 : Créer le script Python

Créez un fichier `outfit_ai_server.py` :

```python
#!/usr/bin/env python3
"""
Serveur Python pour l'IA de sélection d'outfits
Installer : pip install flask flask-cors numpy scikit-learn
"""

from flask import Flask, request, jsonify
from flask_cors import CORS
import json
from typing import List, Dict
from dataclasses import dataclass

app = Flask(__name__)
CORS(app)

@dataclass
class WardrobeItem:
    id: str
    name: str
    category: str
    color: str
    material: str = None
    season: List[str] = None
    is_favorite: bool = False
    wear_count: int = 0

@dataclass
class WeatherData:
    temperature: float
    condition: str
    humidity: int = 50

def analyze_color_harmony(items: List[WardrobeItem]) -> float:
    """Analyse avancée de l'harmonie des couleurs"""
    if len(items) < 2:
        return 0.5
    
    colors = [item.color.lower() for item in items]
    
    # Couleurs neutres
    neutrals = ["noir", "blanc", "gris", "beige", "crème", "kaki", "marine"]
    neutral_count = sum(1 for c in colors if any(n in c for n in neutrals))
    
    # Score de base
    score = 0.5
    
    # Bonus pour les neutres (s'accordent avec tout)
    if neutral_count > 0:
        score += 0.2
    
    # Bonus pour cohérence (même famille de couleurs)
    unique_colors = len(set(colors))
    if unique_colors <= 2:
        score += 0.3
    elif unique_colors <= 3:
        score += 0.1
    
    return min(1.0, score)

def calculate_weather_compatibility(item: WardrobeItem, weather: WeatherData) -> float:
    """Calcule la compatibilité météo"""
    score = 0.5
    
    # Analyse par température
    if weather.temperature < 5:
        if "laine" in (item.material or "").lower() or "winter" in (item.season or []):
            score += 0.5
    elif weather.temperature > 25:
        if "coton" in (item.material or "").lower() or "summer" in (item.season or []):
            score += 0.5
    
    # Analyse par condition
    if weather.condition == "rainy":
        if "imperméable" in (item.material or "").lower() or item.category == "outerwear":
            score += 0.3
    
    return min(1.0, score)

def generate_outfit(wardrobe: List[WardrobeItem], weather: WeatherData) -> Dict:
    """Génère un outfit optimal"""
    # Filtrer par catégorie
    by_category = {}
    for item in wardrobe:
        if item.category not in by_category:
            by_category[item.category] = []
        by_category[item.category].append(item)
    
    # Vérifier les requis
    required = ["bottom", "top", "shoes"]
    if not all(cat in by_category for cat in required):
        return {"error": "Vêtements manquants"}
    
    # Sélectionner intelligemment
    selected = []
    
    # Bas
    bottoms = sorted(by_category["bottom"], 
                    key=lambda x: calculate_weather_compatibility(x, weather),
                    reverse=True)[0]
    selected.append(bottoms)
    
    # Haut
    tops = sorted(by_category["top"],
                  key=lambda x: calculate_weather_compatibility(x, weather) + 
                               (0.2 if x.is_favorite else 0),
                  reverse=True)[0]
    selected.append(tops)
    
    # Chaussures
    shoes = sorted(by_category["shoes"],
                   key=lambda x: calculate_weather_compatibility(x, weather),
                   reverse=True)[0]
    selected.append(shoes)
    
    # Veste si nécessaire
    if weather.temperature < 15 or weather.condition == "rainy":
        if "outerwear" in by_category:
            outerwear = sorted(by_category["outerwear"],
                             key=lambda x: calculate_weather_compatibility(x, weather),
                             reverse=True)[0]
            selected.append(outerwear)
    
    # Calculer le score
    harmony_score = analyze_color_harmony(selected)
    weather_score = sum(calculate_weather_compatibility(item, weather) 
                       for item in selected) / len(selected)
    favorite_bonus = sum(0.1 for item in selected if item.is_favorite)
    
    final_score = (harmony_score * 30 + weather_score * 50 + favorite_bonus * 20)
    
    return {
        "items": [{"id": item.id, "name": item.name} for item in selected],
        "score": final_score,
        "reason": f"Harmonie: {harmony_score:.1f}, Météo: {weather_score:.1f}"
    }

@app.route('/generate', methods=['POST'])
def generate():
    """Endpoint pour générer des outfits"""
    data = request.json
    
    wardrobe_data = data.get('wardrobe', [])
    weather_data = data.get('weather', {})
    
    # Convertir en objets
    wardrobe = [WardrobeItem(**item) for item in wardrobe_data]
    weather = WeatherData(**weather_data)
    
    # Générer 5 outfits
    outfits = []
    for _ in range(5):
        outfit = generate_outfit(wardrobe, weather)
        if "error" not in outfit:
            outfits.append(outfit)
    
    return jsonify({"outfits": outfits})

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000, debug=True)
```

### Étape 2 : Installer les dépendances

```bash
pip install flask flask-cors
```

### Étape 3 : Lancer le serveur

```bash
python3 outfit_ai_server.py
```

### Étape 4 : Modifier Swift pour utiliser le serveur Python

Dans `IntelligentOutfitMatchingAlgorithm.swift`, ajoutez :

```swift
// Optionnel : appeler le serveur Python
private func callPythonServer(items: [WardrobeItem], weather: WeatherData) async -> [MatchedOutfit]? {
    guard let url = URL(string: "http://127.0.0.1:5000/generate") else { return nil }
    
    let requestBody: [String: Any] = [
        "wardrobe": items.map { [
            "id": $0.id.uuidString,
            "name": $0.name,
            "category": $0.category.rawValue,
            "color": $0.color,
            "material": $0.material ?? "",
            "season": $0.season.map { $0.rawValue },
            "is_favorite": $0.isFavorite,
            "wear_count": $0.wearCount
        ]},
        "weather": [
            "temperature": weather.temperature,
            "condition": weather.condition.rawValue,
            "humidity": 50
        ]
    ]
    
    // ... Code pour faire la requête HTTP
}
```

## Note importante

**L'algorithme Swift actuel est déjà très intelligent !** Il utilise :
- Analyse avancée des couleurs (théorie des couleurs)
- Scoring intelligent basé sur la météo
- Analyse des matières et saisons
- Prise en compte des préférences utilisateur
- Gestion des favoris et historique

Le serveur Python n'est utile que si vous voulez :
- Utiliser du machine learning (TensorFlow, scikit-learn)
- Analyser les images avec des modèles de vision
- Utiliser des modèles pré-entraînés

**Recommandation** : L'algorithme Swift actuel est suffisant et plus rapide (pas de serveur externe) !

