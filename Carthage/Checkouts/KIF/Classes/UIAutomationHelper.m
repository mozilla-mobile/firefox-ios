//
//  UIAutomationHelper.m
//  KIF
//
//  Created by Joe Masilotti on 12/1/14.
//
//

#import "UIAutomationHelper.h"
#import <dlfcn.h>
#import <objc/runtime.h>
#import "UIApplication-KIFAdditions.h"

@interface UIAElement : NSObject <NSCopying>
- (void)tap;
- (NSNumber *)pid;
@end

@interface UIAXElement : NSObject
- (BOOL)isValid;
@end

@interface UIAElementArray : NSArray
- (id)firstWithPredicate:(id)predicate;
@end

@interface UIAAlert : UIAElement
- (NSArray *)buttons;
- (BOOL)isValid;
- (BOOL)isVisible;
@end

@interface UIAApplication : UIAElement
- (UIAAlert *)alert;
- (NSString *)name;
- (id)appItemScrollView;
@end

@interface UIATarget : UIAElement
+ (UIATarget *)localTarget;
- (UIAApplication *)frontMostApp;
- (void)deactivateAppForDuration:(NSNumber *)duration;
@end

@interface UIAElementNil : UIAElement

@end

@implementation UIAutomationHelper

static UIAApplication * (*frontMostAppIMP)(id, SEL);
static id (*firstWithPredicateIMP)(id, SEL, id);

static UIAApplication * KIF_frontMostApp(id self, SEL _cmd)
{
    UIAApplication *frontMostApp = frontMostAppIMP(self, _cmd);
    if (![frontMostApp name] && [@(getpid()) isEqual:[frontMostApp pid]]) {
        NSBundle *mainBundle = [NSBundle mainBundle];
        NSString *appName = [mainBundle objectForInfoDictionaryKey:@"CFBundleDisplayName"] ?: [mainBundle objectForInfoDictionaryKey:@"CFBundleName"];
        [frontMostApp setValue:appName forKey:@"name"];
    }
    return frontMostApp;
}

static id KIF_firstWithPredicate(id self, SEL _cmd, id predicate)
{
    NSArray *callStackSymbols = [NSThread callStackSymbols];
    if (callStackSymbols.count > 1 && [callStackSymbols[1] containsString:@"-[UIATarget reactivateApp]"]) {
        id firstWithPredicate = firstWithPredicateIMP(self, _cmd, predicate);
        // -[UIATarget reactivateApp] was not rewritten for the new iOS 9 app switcher
        return [firstWithPredicate isValid] ? firstWithPredicate : [[[[UIAutomationHelper sharedHelper] target] frontMostApp] appItemScrollView];
    } else {
        return firstWithPredicateIMP(self, _cmd, predicate);
    }
}

static void FixReactivateApp(void)
{
    NSProcessInfo *processInfo = [NSProcessInfo processInfo];
    if ([processInfo respondsToSelector:@selector(isOperatingSystemAtLeastVersion:)] && [processInfo isOperatingSystemAtLeastVersion:(NSOperatingSystemVersion){9, 0, 0}]) {
        // Workaround bug in iOS 9: https://github.com/kif-framework/KIF/issues/703
        Method frontMostApp = class_getInstanceMethod(objc_lookUpClass("UIATarget"), @selector(frontMostApp));
        frontMostAppIMP = (__typeof__(frontMostAppIMP))method_getImplementation(frontMostApp);
        method_setImplementation(frontMostApp, (IMP)KIF_frontMostApp);
        
        Method firstWithPredicate = class_getInstanceMethod(objc_lookUpClass("UIAElementArray"), @selector(firstWithPredicate:));
        firstWithPredicateIMP = (__typeof__(firstWithPredicateIMP))method_getImplementation(firstWithPredicate);
        method_setImplementation(firstWithPredicate, (IMP)KIF_firstWithPredicate);
    }
}

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
	if (![alert isKindOfClass:[self nilElementClass]] && [self _alertIsValidAndVisible:alert]) {
            [[alert.buttons lastObject] tap];
            while ([self _alertIsValidAndVisible:alert]) {
                // Wait for button press to complete.
                KIFRunLoopRunInModeRelativeToAnimationSpeed(UIApplicationCurrentRunMode, 0.1, false);
            }
            // Wait for alert dismissial animation.
            KIFRunLoopRunInModeRelativeToAnimationSpeed(UIApplicationCurrentRunMode, 0.4, false);
            return YES;
	}
    return NO;
}

- (void)deactivateAppForDuration:(NSNumber *)duration {
    [[self target] deactivateAppForDuration:duration];
}

#pragma mark - Private

- (BOOL)_alertIsValidAndVisible:(UIAAlert *)alert;
{
    // [alert isValid] is returning an __NSCFBoolean which is really hard to compare against.
    // Translate the __NSCFBoolean into a vanilla BOOL.
    // See https://www.bignerdranch.com/blog/bools-sharp-corners/ for more details.
    
    BOOL visible = [[alert valueForKeyPath:@"isVisible"] boolValue];
    return ([alert isValid] && visible);
}

- (void)linkAutomationFramework {
    dlopen([@"/Developer/Library/PrivateFrameworks/UIAutomation.framework/UIAutomation" fileSystemRepresentation], RTLD_LOCAL);
    FixReactivateApp();

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
