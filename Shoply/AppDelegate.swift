//
//  AppDelegate.swift
//  Shoply - Outfit Selector
//
//  Created by William on 01/11/2025.
//

import UIKit
import SwiftUI
import UserNotifications

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
    
    func applicationDidBecomeActive(_ application: UIApplication) {
        // Réinitialiser le badge de notification quand l'app devient active
        clearApplicationBadge()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        // Réinitialiser le badge de notification quand l'app entre au premier plan
        clearApplicationBadge()
    }
    
    private func clearApplicationBadge() {
        // Méthode moderne avec UNUserNotificationCenter (iOS 16+)
        if #available(iOS 16.0, *) {
            UNUserNotificationCenter.current().setBadgeCount(0) { error in
                if error != nil {
                    // Erreur silencieuse
                }
            }
        } else {
            // Méthode de fallback pour iOS < 16
            DispatchQueue.main.async {
                UIApplication.shared.applicationIconBadgeNumber = 0
            }
        }
    }
}

