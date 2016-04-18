//
//  KIFAccessibilityEnabler.m
//  KIF
//
//  Created by Timothy Clem on 10/11/15.
//
//

#import "KIFAccessibilityEnabler.h"
#import <XCTest/XCTest.h>
#import <dlfcn.h>


#if __IPHONE_OS_VERSION_MAX_ALLOWED < 90000
@protocol XCTestObservation <NSObject>
@end

@interface XCTestObservationCenter : NSObject
+ (XCTestObservationCenter *)sharedTestObservationCenter;
- (void)addTestObserver:(id <XCTestObservation>)testObserver;
@end
#endif


@interface AccessibilitySettingsController
- (void)setAXInspectorEnabled:(NSNumber*)enabled specifier:(id)specifier;
- (NSNumber *)AXInspectorEnabled:(id)specifier;
@end


@interface KIFAccessibilityEnabler () <XCTestObservation>

@property (nonatomic, strong) id axSettingPrefController;
@property (nonatomic, strong) NSNumber *initialAccessibilityInspectorSetting;

@end


@implementation KIFAccessibilityEnabler

+ (void)load
{
    @autoreleasepool {
        if ([XCTestObservationCenter respondsToSelector:@selector(sharedTestObservationCenter)]) {
            XCTestObservationCenter *observationCenter = [XCTestObservationCenter sharedTestObservationCenter];
            [observationCenter addTestObserver:[self sharedAccessibilityEnabler]];
        } else {
            [[self sharedAccessibilityEnabler] _enableAccessibility];
        }
    }
}

+ (instancetype)sharedAccessibilityEnabler
{
    static dispatch_once_t onceToken;
    static KIFAccessibilityEnabler *_sharedAccessibilityEnabler;
    dispatch_once(&onceToken, ^{
        _sharedAccessibilityEnabler = [[self alloc] init];
    });

    return _sharedAccessibilityEnabler;
}

- (void)_enableAccessibility
{
    NSDictionary *environment = [[NSProcessInfo processInfo] environment];
    NSString *simulatorRoot = [environment objectForKey:@"IPHONE_SIMULATOR_ROOT"];

    NSString *appSupportLocation = @"/System/Library/PrivateFrameworks/AppSupport.framework/AppSupport";
    if (simulatorRoot) {
        appSupportLocation = [simulatorRoot stringByAppendingString:appSupportLocation];
    }

    void *appSupportLibrary = dlopen([appSupportLocation fileSystemRepresentation], RTLD_LAZY);

    CFStringRef (*copySharedResourcesPreferencesDomainForDomain)(CFStringRef domain) = dlsym(appSupportLibrary, "CPCopySharedResourcesPreferencesDomainForDomain");

    if (copySharedResourcesPreferencesDomainForDomain) {
        CFStringRef accessibilityDomain = copySharedResourcesPreferencesDomainForDomain(CFSTR("com.apple.Accessibility"));

        if (accessibilityDomain) {
            CFPreferencesSetValue(CFSTR("ApplicationAccessibilityEnabled"), kCFBooleanTrue, accessibilityDomain, kCFPreferencesAnyUser, kCFPreferencesAnyHost);
            CFRelease(accessibilityDomain);
        }
    }

    NSString* accessibilitySettingsBundleLocation = @"/System/Library/PreferenceBundles/AccessibilitySettings.bundle/AccessibilitySettings";
    if (simulatorRoot) {
        accessibilitySettingsBundleLocation = [simulatorRoot stringByAppendingString:accessibilitySettingsBundleLocation];
    }
    const char *accessibilitySettingsBundlePath = [accessibilitySettingsBundleLocation fileSystemRepresentation];
    void* accessibilitySettingsBundle = dlopen(accessibilitySettingsBundlePath, RTLD_LAZY);
    if (accessibilitySettingsBundle) {
        Class axSettingsPrefControllerClass = NSClassFromString(@"AccessibilitySettingsController");
        self.axSettingPrefController = [[axSettingsPrefControllerClass alloc] init];

        self.initialAccessibilityInspectorSetting = [self.axSettingPrefController AXInspectorEnabled:nil];
        [self.axSettingPrefController setAXInspectorEnabled:@(YES) specifier:nil];
    }
}

- (void)_resetAccessibilityInspector
{
    [self.axSettingPrefController setAXInspectorEnabled:self.initialAccessibilityInspectorSetting specifier:nil];
}

- (void)testBundleWillStart:(NSBundle *)testBundle
{
    [self _enableAccessibility];
}

- (void)testBundleDidFinish:(NSBundle *)testBundle
{
    [self _resetAccessibilityInspector];
}

@end
