//
//  AdaptiveLayout.swift
//  Shoply
//
//  Créé pour gérer les adaptations iPad (grilles, largeur max, etc.)
//

import SwiftUI

struct DeviceInfo {
    static var isPad: Bool {
        #if os(iOS)
        return UIDevice.current.userInterfaceIdiom == .pad
        #else
        return false
        #endif
    }
}

enum AdaptiveColumns {
    static func twoToFour(isPad: Bool) -> [GridItem] {
        if isPad {
            return [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
        } else {
            return [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
        }
    }
    
    static func twoToThree(isPad: Bool) -> [GridItem] {
        if isPad {
            return [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
        } else {
            return [
                GridItem(.flexible(), spacing: 16),
                GridItem(.flexible(), spacing: 16)
            ]
        }
    }
}

struct AdaptiveContentContainer<Content: View>: View {
    let maxWidthPad: CGFloat
    let horizontalPadding: CGFloat
    @ViewBuilder var content: () -> Content
    
    init(maxWidthPad: CGFloat = 1000, horizontalPadding: CGFloat = 20, @ViewBuilder content: @escaping () -> Content) {
        self.maxWidthPad = maxWidthPad
        self.horizontalPadding = horizontalPadding
        self.content = content
    }
    
    var body: some View {
        content()
            .frame(maxWidth: DeviceInfo.isPad ? maxWidthPad : .infinity, alignment: .center)
            .padding(.horizontal, DeviceInfo.isPad ? horizontalPadding : 0)
            .frame(maxWidth: .infinity, alignment: .center)
    }
}


