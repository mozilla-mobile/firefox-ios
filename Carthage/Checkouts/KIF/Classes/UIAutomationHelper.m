//
//  UIAutomationHelper.m
//  KIF
//
//  Created by Joe Masilotti on 12/1/14.
//
//

#import "UIAutomationHelper.h"
#include <dlfcn.h>

@interface UIAElement : NSObject <NSCopying>
- (void)tap;
@end

@interface UIAAlert : UIAElement
- (NSArray *)buttons;
@end

@interface UIAApplication : UIAElement
- (UIAAlert *)alert;
@end

@interface UIATarget : UIAElement
+ (UIATarget *)localTarget;
- (UIAApplication *)frontMostApp;
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

+ (void)acknowledgeSystemAlert {
    [[self sharedHelper] acknowledgeSystemAlert];
}

- (void)acknowledgeSystemAlert {
    UIAApplication *application = [[self target] frontMostApp];
    UIAAlert *alert = application.alert;

    if (![alert isKindOfClass:[self nilElementClass]]) {
        [[alert.buttons lastObject] tap];
        while (![application.alert isKindOfClass:[self nilElementClass]]) { }
    }
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
