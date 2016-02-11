//
//  UIAutomationHelper.m
//  KIF
//
//  Created by Joe Masilotti on 12/1/14.
//
//

#import "UIAutomationHelper.h"
#include <dlfcn.h>
#import <UIView-KIFAdditions.h>

@interface UIAElement : NSObject <NSCopying>
- (void)tap;
@end

@interface UIAAlert : UIAElement
- (NSArray *)buttons;
- (BOOL)isValid;
- (BOOL)isVisible;
@end

@interface UIAApplication : UIAElement
- (UIAAlert *)alert;
@end

@interface UIATarget : UIAElement
+ (UIATarget *)localTarget;
- (UIAApplication *)frontMostApp;
- (void)deactivateAppForDuration:(NSNumber *)duration;
@end

@interface UIAElementNil : UIAElement

@end

@implementation UIAutomationHelper

+ (UIAutomationHelper *)sharedHelper
{
    static dispatch_once_t once;
    static UIAutomationHelper *sharedHelper = nil;
    dispatch_once(&once, ^{
        sharedHelper = [[self alloc] init];
        [sharedHelper linkAutomationFramework];
    });
    return sharedHelper;
}

+ (BOOL)acknowledgeSystemAlert {
    return [[self sharedHelper] acknowledgeSystemAlert];
}

+ (void)deactivateAppForDuration:(NSNumber *)duration {
    [[self sharedHelper] deactivateAppForDuration:duration];
}
- (BOOL)acknowledgeSystemAlert {
    UIAApplication *application = [[self target] frontMostApp];
	UIAAlert* alert = application.alert;
	if (![alert isKindOfClass:[self nilElementClass]]) {
		[[alert.buttons lastObject] tap];
		while ([alert isValid] && [alert isVisible]) {
		}
		return YES;
	}
    return NO;
}

- (void)deactivateAppForDuration:(NSNumber *)duration {
    [[self target] deactivateAppForDuration:duration];
}

#pragma mark - Private

- (void)linkAutomationFramework {
    dlopen([@"/Developer/Library/PrivateFrameworks/UIAutomation.framework/UIAutomation" fileSystemRepresentation], RTLD_LOCAL);

    // Keep trying until the accessibility server starts up (it takes a little while on iOS 7)
    UIATarget *target = nil;
    while (!target) {
        @try {
            target = [self target];
        }
        @catch (NSException *exception) { }
        @finally { }
    }
}

- (UIATarget *)target {
    return [NSClassFromString(@"UIATarget") localTarget];
}

- (Class)nilElementClass {
    return NSClassFromString(@"UIAElementNil");
}

@end
