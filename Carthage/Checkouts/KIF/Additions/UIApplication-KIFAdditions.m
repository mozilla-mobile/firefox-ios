//
//  UIApplication-KIFAdditions.m
//  KIF
//
//  Created by Eric Firestone on 5/20/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "UIApplication-KIFAdditions.h"
#import "LoadableCategory.h"
#import "UIView-KIFAdditions.h"
#import "NSError-KIFAdditions.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import <objc/message.h>

MAKE_CATEGORIES_LOADABLE(UIApplication_KIFAdditions)

static BOOL _KIF_UIApplicationMockOpenURL = NO;
static BOOL _KIF_UIApplicationMockOpenURL_returnValue = NO;

SInt32 KIFRunLoopRunInModeRelativeToAnimationSpeed(CFStringRef mode, CFTimeInterval seconds, Boolean returnAfterSourceHandled)
{
    CFTimeInterval scaledSeconds = seconds / [UIApplication sharedApplication].animationSpeed;
    return CFRunLoopRunInMode(mode, scaledSeconds, returnAfterSourceHandled);
}

@interface UIApplication (Undocumented)
- (void)pushRunLoopMode:(id)arg1;
- (void)pushRunLoopMode:(id)arg1 requester:(id)requester;
- (void)popRunLoopMode:(id)arg1;
- (void)popRunLoopMode:(id)arg1 requester:(id)requester;
@end

NSString *const UIApplicationDidMockOpenURLNotification = @"UIApplicationDidMockOpenURLNotification";
NSString *const UIApplicationDidMockCanOpenURLNotification = @"UIApplicationDidMockCanOpenURLNotification";
NSString *const UIApplicationOpenedURLKey = @"UIApplicationOpenedURL";
static const void *KIFRunLoopModesKey = &KIFRunLoopModesKey;

@implementation UIApplication (KIFAdditions)

#pragma mark - Finding elements

- (UIAccessibilityElement *)accessibilityElementWithLabel:(NSString *)label accessibilityValue:(NSString *)value traits:(UIAccessibilityTraits)traits;
{
    // Go through the array of windows in reverse order to process the frontmost window first.
    // When several elements with the same accessibilitylabel are present the one in front will be picked.
    for (UIWindow *window in [self.windowsWithKeyWindow reverseObjectEnumerator]) {
        if (window.hidden) {
            continue;
        }
        UIAccessibilityElement *element = [window accessibilityElementWithLabel:label accessibilityValue:value traits:traits];
        if (element) {
            return element;
        }
    }
    
    return nil;
}

- (UIAccessibilityElement *)accessibilityElementMatchingBlock:(BOOL(^)(UIAccessibilityElement *))matchBlock;
{
    for (UIWindow *window in [self.windowsWithKeyWindow reverseObjectEnumerator]) {
        UIAccessibilityElement *element = [window accessibilityElementMatchingBlock:matchBlock];
        if (element) {
            return element;
        }
    }
    
    return nil;
}

#pragma mark - Interesting windows

- (UIWindow *)keyboardWindow;
{
    for (UIWindow *window in self.windowsWithKeyWindow) {
        if ([NSStringFromClass([window class]) isEqual:@"UITextEffectsWindow"]) {
            return window;
        }
    }
    
    return nil;
}

- (UIWindow *)datePickerWindow;
{
    return [self getWindowForSubviewClass:@"UIDatePicker"];
}

- (UIWindow *)pickerViewWindow;
{
    return [self getWindowForSubviewClass:@"UIPickerView"];
}

- (UIWindow *)dimmingViewWindow;
{
    return [self getWindowForSubviewClass:@"UIDimmingView"];
}

- (UIWindow *)getWindowForSubviewClass:(NSString*)className;
{
    for (UIWindow *window in self.windowsWithKeyWindow) {
        NSArray *subViews = [window subviewsWithClassNameOrSuperClassNamePrefix:className];
        if (subViews.count > 0) {
            return window;
        }
    }

    return nil;
}

- (NSArray *)windowsWithKeyWindow
{
    NSMutableArray *windows = self.windows.mutableCopy;
    UIWindow *keyWindow = self.keyWindow;
    if (keyWindow && ![windows containsObject:keyWindow]) {
        [windows addObject:keyWindow];
    }
    return windows;
}

- (float)animationSpeed
{
    if (!self.keyWindow) {
        return 1.0f;
    }
    return self.keyWindow.layer.speed;
}

- (void)setAnimationSpeed:(float)animationSpeed
{
    self.keyWindow.layer.speed = animationSpeed;
}

#pragma mark - Screenshotting

- (BOOL)writeScreenshotForLine:(NSUInteger)lineNumber inFile:(NSString *)filename description:(NSString *)description error:(NSError **)error;
{
    NSString *outputPath = [[[NSProcessInfo processInfo] environment] objectForKey:@"KIF_SCREENSHOTS"];
    if (!outputPath) {
        if (error) {
            *error = [NSError KIFErrorWithFormat:@"Screenshot path not defined. Please set KIF_SCREENSHOTS environment variable."];
        }
        return NO;
    }
    
    NSArray *windows = [self windowsWithKeyWindow];
    if (windows.count == 0) {
        if (error) {
            *error = [NSError KIFErrorWithFormat:@"Could not take screenshot.  No windows were available."];
        }
        return NO;
    }
    
    if (!filename.length) {
        if (error) {
            *error = [NSError KIFErrorWithFormat:@"Missing screenshot filename."];
        }
        return NO;
    }
    
    UIGraphicsBeginImageContextWithOptions([[windows objectAtIndex:0] bounds].size, YES, 0);
    for (UIWindow *window in windows) {
		//avoid https://github.com/kif-framework/KIF/issues/679
		if (window.hidden) {
			continue;
		}

        if ([window respondsToSelector:@selector(drawViewHierarchyInRect:afterScreenUpdates:)]) {
            [window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
        } else {
            [window.layer renderInContext:UIGraphicsGetCurrentContext()];
        }
    }
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    outputPath = [outputPath stringByExpandingTildeInPath];

    NSError *directoryCreationError = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:outputPath withIntermediateDirectories:YES attributes:nil error:&directoryCreationError]) {
        if (directoryCreationError) {
            *error = [NSError KIFErrorWithFormat:@"Couldn't create directory at path %@ (details: %@)", outputPath, directoryCreationError];
        }
        return NO;
    }

    NSString *imageName = [self imageNameForFile:filename lineNumber:lineNumber description:description];
    
    outputPath = [outputPath stringByAppendingPathComponent:imageName];
    outputPath = [outputPath stringByAppendingPathExtension:@"png"];

    if (![UIImagePNGRepresentation(image) writeToFile:outputPath atomically:YES]) {
        if (error) {
            *error = [NSError KIFErrorWithFormat:@"Could not write file at path %@", outputPath];
        }
        return NO;
    }
    
    return YES;
}

- (NSString *)imageNameForFile:(NSString *)filename lineNumber:(NSUInteger)lineNumber description:(NSString *)description {
    if (!filename.length) {
        return nil;
    }
    
    NSString *imageName = [filename lastPathComponent];
    
    if (lineNumber > 0) {
        imageName = [imageName stringByAppendingFormat:@", line %lu", (unsigned long)lineNumber];
    }
    
    if (description.length) {
        imageName = [imageName stringByAppendingFormat:@", %@", description];
    }

    return imageName;
}

#pragma mark - Run loop monitoring

- (NSMutableArray *)KIF_runLoopModes;
{
    NSMutableArray *modes = objc_getAssociatedObject(self, KIFRunLoopModesKey);
    if (!modes) {
        modes = [NSMutableArray arrayWithObject:(id)kCFRunLoopDefaultMode];
        objc_setAssociatedObject(self, KIFRunLoopModesKey, modes, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return modes;
}

- (CFStringRef)currentRunLoopMode;
{
    return (__bridge CFStringRef)[self KIF_runLoopModes].lastObject;
}

- (void)KIF_pushRunLoopMode:(NSString *)mode;
{
    [[self KIF_runLoopModes] addObject:mode];
    [self KIF_pushRunLoopMode:mode];
}

- (void)KIF_pushRunLoopMode:(NSString *)mode requester:(id)requester;
{
    [[self KIF_runLoopModes] addObject:mode];
    [self KIF_pushRunLoopMode:mode requester:requester];
}

- (void)KIF_popRunLoopMode:(NSString *)mode;
{
    [[self KIF_runLoopModes] removeLastObject];
    [self KIF_popRunLoopMode:mode];
}


- (void)KIF_popRunLoopMode:(NSString *)mode requester:(id)requester;
{
    [[self KIF_runLoopModes] removeLastObject];
    [self KIF_popRunLoopMode:mode requester:requester];
}

- (BOOL)KIF_openURL:(NSURL *)URL;
{
    if (_KIF_UIApplicationMockOpenURL) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidMockOpenURLNotification object:self userInfo:@{UIApplicationOpenedURLKey: URL}];
        return _KIF_UIApplicationMockOpenURL_returnValue;
    } else {
        return [self KIF_openURL:URL];
    }
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
- (BOOL)KIF_openURL:(NSURL *)URL options:(NSDictionary<NSString *, id> *)options completionHandler:(void (^ __nullable)(BOOL success))completionHandler;
{
    if (_KIF_UIApplicationMockOpenURL) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidMockOpenURLNotification object:self userInfo:@{UIApplicationOpenedURLKey: URL}];
        return _KIF_UIApplicationMockOpenURL_returnValue;
    } else {
        return [self KIF_openURL:URL options: options completionHandler: completionHandler];
    }
}
#endif

- (BOOL)KIF_canOpenURL:(NSURL *)URL;
{
    if (_KIF_UIApplicationMockOpenURL) {
        [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidMockCanOpenURLNotification object:self userInfo:@{UIApplicationOpenedURLKey: URL}];
        return _KIF_UIApplicationMockOpenURL_returnValue;
    } else {
        return [self KIF_canOpenURL:URL];
    }
}

static inline void Swizzle(Class c, SEL orig, SEL new)
{
    Method origMethod = class_getInstanceMethod(c, orig);
    Method newMethod = class_getInstanceMethod(c, new);
    if(class_addMethod(c, orig, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)))
        class_replaceMethod(c, new, method_getImplementation(origMethod), method_getTypeEncoding(origMethod));
    else
        method_exchangeImplementations(origMethod, newMethod);
}

+ (void)swizzleRunLoop;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Swizzle(self, @selector(pushRunLoopMode:), @selector(KIF_pushRunLoopMode:));
        Swizzle(self, @selector(pushRunLoopMode:requester:), @selector(KIF_pushRunLoopMode:requester:));
        Swizzle(self, @selector(popRunLoopMode:), @selector(KIF_popRunLoopMode:));
        Swizzle(self, @selector(popRunLoopMode:requester:), @selector(KIF_popRunLoopMode:requester:));
    });
}

#pragma mark - openURL mocking

+ (void)startMockingOpenURLWithReturnValue:(BOOL)returnValue;
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Swizzle(self, @selector(openURL:), @selector(KIF_openURL:));
        #if __IPHONE_OS_VERSION_MAX_ALLOWED >= 100000
            Swizzle(self, @selector(openURL:options:completionHandler:), @selector(KIF_openURL:options:completionHandler:));
        #endif
        Swizzle(self, @selector(canOpenURL:), @selector(KIF_canOpenURL:));
    });

    _KIF_UIApplicationMockOpenURL = YES;
    _KIF_UIApplicationMockOpenURL_returnValue = returnValue;
}

+ (void)stopMockingOpenURL;
{
    _KIF_UIApplicationMockOpenURL = NO;
}

@end
