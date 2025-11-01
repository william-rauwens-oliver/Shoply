import Foundation
#if canImport(AppKit)
import AppKit
#endif
#if canImport(UIKit)
import UIKit
#endif
#if canImport(SwiftUI)
import SwiftUI
#endif
#if canImport(DeveloperToolsSupport)
import DeveloperToolsSupport
#endif

#if SWIFT_PACKAGE
private let resourceBundle = Foundation.Bundle.module
#else
private class ResourceBundleClass {}
private let resourceBundle = Foundation.Bundle(for: ResourceBundleClass.self)
#endif

// MARK: - Color Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ColorResource {

    /// The "Bg" asset catalog color resource.
    static let bg = DeveloperToolsSupport.ColorResource(name: "Bg", bundle: resourceBundle)

    /// The "Primary" asset catalog color resource.
    static let primary = DeveloperToolsSupport.ColorResource(name: "Primary", bundle: resourceBundle)

}

// MARK: - Image Symbols -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension DeveloperToolsSupport.ImageResource {

    /// The "chair_1" asset catalog image resource.
    static let chair1 = DeveloperToolsSupport.ImageResource(name: "chair_1", bundle: resourceBundle)

    /// The "chair_2" asset catalog image resource.
    static let chair2 = DeveloperToolsSupport.ImageResource(name: "chair_2", bundle: resourceBundle)

    /// The "chair_3" asset catalog image resource.
    static let chair3 = DeveloperToolsSupport.ImageResource(name: "chair_3", bundle: resourceBundle)

    /// The "chair_4" asset catalog image resource.
    static let chair4 = DeveloperToolsSupport.ImageResource(name: "chair_4", bundle: resourceBundle)

}

// MARK: - Color Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    /// The "Bg" asset catalog color.
    static var bg: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .bg)
#else
        .init()
#endif
    }

    /// The "Primary" asset catalog color.
    static var primary: AppKit.NSColor {
#if !targetEnvironment(macCatalyst)
        .init(resource: .primary)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    /// The "Bg" asset catalog color.
    static var bg: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .bg)
#else
        .init()
#endif
    }

    /// The "Primary" asset catalog color.
    static var primary: UIKit.UIColor {
#if !os(watchOS)
        .init(resource: .primary)
#else
        .init()
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    /// The "Bg" asset catalog color.
    static var bg: SwiftUI.Color { .init(.bg) }

    #warning("The \"Primary\" color asset name resolves to a conflicting Color symbol \"primary\". Try renaming the asset.")

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    /// The "Bg" asset catalog color.
    static var bg: SwiftUI.Color { .init(.bg) }

}
#endif

// MARK: - Image Symbol Extensions -

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    /// The "chair_1" asset catalog image.
    static var chair1: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chair1)
#else
        .init()
#endif
    }

    /// The "chair_2" asset catalog image.
    static var chair2: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chair2)
#else
        .init()
#endif
    }

    /// The "chair_3" asset catalog image.
    static var chair3: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chair3)
#else
        .init()
#endif
    }

    /// The "chair_4" asset catalog image.
    static var chair4: AppKit.NSImage {
#if !targetEnvironment(macCatalyst)
        .init(resource: .chair4)
#else
        .init()
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    /// The "chair_1" asset catalog image.
    static var chair1: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chair1)
#else
        .init()
#endif
    }

    /// The "chair_2" asset catalog image.
    static var chair2: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chair2)
#else
        .init()
#endif
    }

    /// The "chair_3" asset catalog image.
    static var chair3: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chair3)
#else
        .init()
#endif
    }

    /// The "chair_4" asset catalog image.
    static var chair4: UIKit.UIImage {
#if !os(watchOS)
        .init(resource: .chair4)
#else
        .init()
#endif
    }

}
#endif

// MARK: - Thinnable Asset Support -

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ColorResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if AppKit.NSColor(named: NSColor.Name(thinnableName), bundle: bundle) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIColor(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIColor {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(SwiftUI)
@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
extension SwiftUI.ShapeStyle where Self == SwiftUI.Color {

    private init?(thinnableResource: DeveloperToolsSupport.ColorResource?) {
        if let resource = thinnableResource {
            self.init(resource)
        } else {
            return nil
        }
    }

}
#endif

@available(iOS 17.0, macOS 14.0, tvOS 17.0, watchOS 10.0, *)
@available(watchOS, unavailable)
extension DeveloperToolsSupport.ImageResource {

    private init?(thinnableName: Swift.String, bundle: Foundation.Bundle) {
#if canImport(AppKit) && os(macOS)
        if bundle.image(forResource: NSImage.Name(thinnableName)) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#elseif canImport(UIKit) && !os(watchOS)
        if UIKit.UIImage(named: thinnableName, in: bundle, compatibleWith: nil) != nil {
            self.init(name: thinnableName, bundle: bundle)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}

#if canImport(AppKit)
@available(macOS 14.0, *)
@available(macCatalyst, unavailable)
extension AppKit.NSImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !targetEnvironment(macCatalyst)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

#if canImport(UIKit)
@available(iOS 17.0, tvOS 17.0, *)
@available(watchOS, unavailable)
extension UIKit.UIImage {

    private convenience init?(thinnableResource: DeveloperToolsSupport.ImageResource?) {
#if !os(watchOS)
        if let resource = thinnableResource {
            self.init(resource: resource)
        } else {
            return nil
        }
#else
        return nil
#endif
    }

}
#endif

