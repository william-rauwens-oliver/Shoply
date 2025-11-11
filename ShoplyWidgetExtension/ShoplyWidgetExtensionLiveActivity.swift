//
//  ShoplyWidgetExtensionLiveActivity.swift
//  ShoplyWidgetExtension
//
//  Created by William on 02/11/2025.
//

import ActivityKit
import WidgetKit
import SwiftUI

@available(iOS 16.1, *)
struct ShoplyWidgetExtensionAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

@available(iOS 16.1, *)
struct ShoplyWidgetExtensionLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: ShoplyWidgetExtensionAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

@available(iOS 16.1, *)
extension ShoplyWidgetExtensionAttributes {
    fileprivate static var preview: ShoplyWidgetExtensionAttributes {
        ShoplyWidgetExtensionAttributes(name: "World")
    }
}

@available(iOS 16.1, *)
extension ShoplyWidgetExtensionAttributes.ContentState {
    fileprivate static var smiley: ShoplyWidgetExtensionAttributes.ContentState {
        ShoplyWidgetExtensionAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: ShoplyWidgetExtensionAttributes.ContentState {
         ShoplyWidgetExtensionAttributes.ContentState(emoji: "🤩")
     }
}

@available(iOS 16.1, *)
#Preview("Notification", as: .content, using: ShoplyWidgetExtensionAttributes.preview) {
   ShoplyWidgetExtensionLiveActivity()
} contentStates: {
    ShoplyWidgetExtensionAttributes.ContentState.smiley
    ShoplyWidgetExtensionAttributes.ContentState.starEyes
}
