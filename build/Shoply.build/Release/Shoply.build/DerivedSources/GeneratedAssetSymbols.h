#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The resource bundle ID.
static NSString * const ACBundleID AC_SWIFT_PRIVATE = @"William.Shoply";

/// The "Bg" asset catalog color resource.
static NSString * const ACColorNameBg AC_SWIFT_PRIVATE = @"Bg";

/// The "Primary" asset catalog color resource.
static NSString * const ACColorNamePrimary AC_SWIFT_PRIVATE = @"Primary";

/// The "chair_1" asset catalog image resource.
static NSString * const ACImageNameChair1 AC_SWIFT_PRIVATE = @"chair_1";

/// The "chair_2" asset catalog image resource.
static NSString * const ACImageNameChair2 AC_SWIFT_PRIVATE = @"chair_2";

/// The "chair_3" asset catalog image resource.
static NSString * const ACImageNameChair3 AC_SWIFT_PRIVATE = @"chair_3";

/// The "chair_4" asset catalog image resource.
static NSString * const ACImageNameChair4 AC_SWIFT_PRIVATE = @"chair_4";

#undef AC_SWIFT_PRIVATE
