//
//  ShoplyWidget.swift
//  ShoplyWidgetExtension
//
//  Created by William on 01/11/2025.
//

import WidgetKit
import SwiftUI

struct ShoplyWidget: Widget {
    let kind: String = "ShoplyWidget"
    
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ShoplyWidgetProvider()) { entry in
            ShoplyWidgetEntryView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName(LocalizedString.localized("Shoply", for: .french))
        .description(LocalizedString.localized("Affiche vos outfits du jour et la météo", for: .french))
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge, .accessoryRectangular, .accessoryCircular, .accessoryInline])
    }
}

struct ShoplyWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ShoplyWidgetEntry {
        ShoplyWidgetEntry(
            date: Date(),
            weather: WeatherWidgetData(temperature: 20, condition: "Ensoleillé"),
            outfitOfTheDay: "T-shirt blanc + Jeans + Baskets",
            wardrobeStats: WidgetWardrobeStats(totalItems: 25, categories: ["Hauts": 8, "Bas": 5])
        )
    }
    
    func getSnapshot(in context: Context, completion: @escaping (ShoplyWidgetEntry) -> ()) {
        let entry = createEntry()
        completion(entry)
    }
    
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entry = createEntry()
        
        // Rafraîchir toutes les heures
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
    
    private func createEntry() -> ShoplyWidgetEntry {
        // Récupérer la météo depuis UserDefaults (sauvegardée par l'app)
        var weatherData: WeatherWidgetData?
        if let weatherTemp = UserDefaults.standard.object(forKey: "widget_weather_temp") as? Double,
           let weatherCondition = UserDefaults.standard.string(forKey: "widget_weather_condition") {
            weatherData = WeatherWidgetData(
                temperature: Int(weatherTemp),
                condition: weatherCondition
            )
        }
        
        // Récupérer les stats de la garde-robe depuis UserDefaults (partagé avec l'app)
        let items = DataManager.shared.loadWardrobeItems()
        var categoriesDict: [String: Int] = [:]
        let categories = Dictionary(grouping: items, by: { $0.category })
        for (category, categoryItems) in categories {
            categoriesDict[category.rawValue] = categoryItems.count
        }
        
        let wardrobeStats = WidgetWardrobeStats(
            totalItems: items.count,
            categories: categoriesDict
        )
        
        // Générer un outfit simple pour aujourd'hui
        let outfitOfTheDay = generateSimpleOutfit(items: items)
        
        return ShoplyWidgetEntry(
            date: Date(),
            weather: weatherData,
            outfitOfTheDay: outfitOfTheDay,
            wardrobeStats: wardrobeStats
        )
    }
    
    private func generateSimpleOutfit(items: [WardrobeItem]) -> String {
        let tops = items.filter { $0.category == .top }
        let bottoms = items.filter { $0.category == .bottom }
        let shoes = items.filter { $0.category == .shoes }
        
        var outfit = ""
        
        if let top = tops.randomElement() {
            outfit += top.name
        } else {
            outfit += "Haut"
        }
        
        if let bottom = bottoms.randomElement() {
            outfit += " + \(bottom.name)"
        } else {
            outfit += " + Bas"
        }
        
        if let shoe = shoes.randomElement() {
            outfit += " + \(shoe.name)"
        } else {
            outfit += " + Chaussures"
        }
        
        return outfit
    }
}

struct ShoplyWidgetEntry: TimelineEntry {
    let date: Date
    let weather: WeatherWidgetData?
    let outfitOfTheDay: String
    let wardrobeStats: WidgetWardrobeStats
}

struct WeatherWidgetData {
    let temperature: Int
    let condition: String
}

struct WidgetWardrobeStats {
    let totalItems: Int
    let categories: [String: Int]
}

struct ShoplyWidgetEntryView: View {
    var entry: ShoplyWidgetProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        case .systemLarge:
            LargeWidgetView(entry: entry)
        case .accessoryRectangular:
            LockScreenRectangularWidget(entry: entry)
        case .accessoryCircular:
            LockScreenCircularWidget(entry: entry)
        case .accessoryInline:
            LockScreenInlineWidget(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

// MARK: - Small Widget (Home Screen)
struct SmallWidgetView: View {
    let entry: ShoplyWidgetEntry
    
    var body: some View {
        VStack(spacing: 8) {
            // Icône et titre
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                Text(LocalizedString.localized("Shoply", for: .french))
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            // Météo
            if let weather = entry.weather {
                VStack(spacing: 4) {
                    Text("\(weather.temperature)°C")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(weather.condition)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Stats garde-robe
            Text("\(entry.wardrobeStats.totalItems) \(LocalizedString.localized("articles", for: .french))")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Medium Widget (Home Screen)
struct MediumWidgetView: View {
    let entry: ShoplyWidgetEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Colonne gauche - Météo
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "sparkles")
                        .foregroundColor(.blue)
                    Text(LocalizedString.localized("Shoply", for: .french))
                        .font(.headline)
                }
                
                if let weather = entry.weather {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(weather.temperature)°C")
                            .font(.title)
                            .fontWeight(.bold)
                        Text(weather.condition)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Colonne droite - Outfit
            VStack(alignment: .trailing, spacing: 8) {
                Text(LocalizedString.localized("Outfit du jour", for: .french))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(entry.outfitOfTheDay)
                    .font(.subheadline)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(3)
            }
        }
        .padding()
    }
}

// MARK: - Large Widget (Home Screen)
struct LargeWidgetView: View {
    let entry: ShoplyWidgetEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // En-tête
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                    .font(.title2)
                Text(LocalizedString.localized("Shoply", for: .french))
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            
            // Météo
            if let weather = entry.weather {
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(weather.temperature)°C")
                            .font(.system(size: 48, weight: .bold))
                        Text(weather.condition)
                            .font(.headline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 8)
            }
            
            Divider()
            
            // Outfit du jour
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedString.localized("Outfit du jour", for: .french))
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(entry.outfitOfTheDay)
                    .font(.body)
            }
            
            Divider()
            
            // Stats garde-robe
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedString.localized("Ma garde-robe", for: .french))
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text("\(entry.wardrobeStats.totalItems) \(LocalizedString.localized("articles", for: .french))")
                    .font(.body)
            }
        }
        .padding()
    }
}

// MARK: - Lock Screen Widgets

struct LockScreenRectangularWidget: View {
    let entry: ShoplyWidgetEntry
    
    var body: some View {
        HStack {
            if let weather = entry.weather {
                Text("\(weather.temperature)°C • \(entry.outfitOfTheDay.prefix(30))")
                    .font(.caption)
            } else {
                Text(entry.outfitOfTheDay.prefix(40))
                    .font(.caption)
            }
        }
    }
}

struct LockScreenCircularWidget: View {
    let entry: ShoplyWidgetEntry
    
    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            
            if let weather = entry.weather {
                VStack {
                    Text("\(weather.temperature)°")
                        .font(.headline)
                    Image(systemName: "sparkles")
                        .font(.caption)
                }
            } else {
                Image(systemName: "sparkles")
                    .font(.headline)
            }
        }
    }
}

struct LockScreenInlineWidget: View {
    let entry: ShoplyWidgetEntry
    
    var body: some View {
        if let weather = entry.weather {
            Label("\(weather.temperature)°C - \(weather.condition)", systemImage: "sparkles")
        } else {
            Label(LocalizedString.localized("Shoply", for: .french), systemImage: "sparkles")
        }
    }
}

#Preview(as: .systemSmall) {
    ShoplyWidget()
} timeline: {
    ShoplyWidgetEntry(
        date: .now,
        weather: WeatherWidgetData(temperature: 20, condition: "Ensoleillé"),
        outfitOfTheDay: "T-shirt blanc + Jeans + Baskets",
        wardrobeStats: WidgetWardrobeStats(totalItems: 25, categories: [:])
    )
    ShoplyWidgetEntry(
        date: .now,
        weather: WeatherWidgetData(temperature: 15, condition: "Nuageux"),
        outfitOfTheDay: "Pull gris + Pantalon noir + Chaussures",
        wardrobeStats: WidgetWardrobeStats(totalItems: 30, categories: [:])
    )
}

