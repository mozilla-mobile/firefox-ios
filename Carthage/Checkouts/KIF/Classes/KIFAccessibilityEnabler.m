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


@protocol KIFSelectorsToMakeCompilerHappy <NSObject>

// AccessibilitySettingsController (AccessibilitySettings.bundle)
- (void)setAXInspectorEnabled:(NSNumber*)enabled specifier:(id)specifier;
- (NSNumber *)AXInspectorEnabled:(id)specifier;

@end


static void * loadDylibForSimulator(NSString *path)
{
    NSDictionary *environment = [[NSProcessInfo processInfo] environment];
    NSString *simulatorRoot = [environment objectForKey:@"IPHONE_SIMULATOR_ROOT"];
    if (simulatorRoot) {
        path = [simulatorRoot stringByAppendingPathComponent:path];
    }
    return dlopen([path fileSystemRepresentation], RTLD_LOCAL);
}


void KIFEnableAccessibility(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // CPCopySharedResourcesPreferencesDomainForDomain from AppSupport
        void *appSupport = loadDylibForSimulator(@"/System/Library/PrivateFrameworks/AppSupport.framework/AppSupport");
        if (appSupport) {
            CFStringRef (*copySharedResourcesPreferencesDomainForDomain)(CFStringRef domain) = dlsym(appSupport, "CPCopySharedResourcesPreferencesDomainForDomain");
            if (copySharedResourcesPreferencesDomainForDomain) {
                CFStringRef accessibilityDomain = copySharedResourcesPreferencesDomainForDomain(CFSTR("com.apple.Accessibility"));
                if (accessibilityDomain) {
                    CFPreferencesSetValue(CFSTR("ApplicationAccessibilityEnabled"), kCFBooleanTrue, accessibilityDomain, kCFPreferencesAnyUser, kCFPreferencesAnyHost);
                    CFRelease(accessibilityDomain);
                }
            }
        }
        
        // Load AccessibilitySettings bundle
        NSString *settingsBundleLocation = @"/System/Library/PreferenceBundles/AccessibilitySettings.bundle/AccessibilitySettings";
        void *settingsBundle = loadDylibForSimulator(settingsBundleLocation);
        if (settingsBundle) {
            Class axClass = NSClassFromString(@"AccessibilitySettingsController");
            if (axClass) {
                id axInstance = [[axClass alloc] init];
                if ([axInstance respondsToSelector:@selector(AXInspectorEnabled:)]) {
                    NSNumber *initialValue = [axInstance AXInspectorEnabled:nil];
                    
                    // reset on exit
                    atexit_b(^{
                        [axInstance setAXInspectorEnabled:initialValue specifier:nil];
                    });
                    [axInstance setAXInspectorEnabled:@YES specifier:nil];
                    return;
                }
            }
        }
        
        // If we get to this point, the legacy method has not worked
        void *handle = loadDylibForSimulator(@"/usr/lib/libAccessibility.dylib");
        if (!handle) {
            [NSException raise:NSGenericException format:@"Could not enable accessibility"];
        }
        
        int (*_AXSAutomationEnabled)(void) = dlsym(handle, "_AXSAutomationEnabled");
        void (*_AXSSetAutomationEnabled)(int) = dlsym(handle, "_AXSSetAutomationEnabled");
        
        int initialValue = _AXSAutomationEnabled();
        _AXSSetAutomationEnabled(YES);
        atexit_b(^{
            _AXSSetAutomationEnabled(initialValue);
        });
    });
}
