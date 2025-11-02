//
//  AppDelegate.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import UIKit
import SwiftUI

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        // Détecter le type d'appareil
        if UIDevice.current.userInterfaceIdiom == .pad {
            // iPad : toutes les orientations
            return [.portrait, .portraitUpsideDown, .landscapeLeft, .landscapeRight]
        } else {
            // iPhone : uniquement portrait
            return .portrait
        }
    }
}

