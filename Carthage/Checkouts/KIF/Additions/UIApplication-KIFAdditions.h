//
//  UIApplication-KIFAdditions.h
//  KIF
//
//  Created by Eric Firestone on 5/20/11.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import <UIKit/UIKit.h>


#define UIApplicationCurrentRunMode ([[UIApplication sharedApplication] currentRunLoopMode])

/*!
 @abstract When mocking @c -openURL: or -openURL:options:completionHandler:, this notification is posted.
 */
UIKIT_EXTERN NSString *const UIApplicationDidMockOpenURLNotification;

/*!
 @abstract When mocking @c -canOpenURL:, this notification is posted.
 */
UIKIT_EXTERN NSString *const UIApplicationDidMockCanOpenURLNotification;

/*!
 @abstract The key for the opened URL in the @c UIApplicationDidMockOpenURLNotification notification.
 */
UIKIT_EXTERN NSString *const UIApplicationOpenedURLKey;

/*!
 @abstract A wrapper for CFRunLoopRunInMode that scales the seconds parameter relative to the animation speed.
 */
CF_EXPORT SInt32 KIFRunLoopRunInModeRelativeToAnimationSpeed(CFStringRef mode, CFTimeInterval seconds, Boolean returnAfterSourceHandled);

@interface UIApplication (KIFAdditions)

/*!
 @abstract Finds an accessibility element with a matching label, value, and traits across all windows in the application starting at the frontmost window.
 @param label The accessibility label of the element to search for.
 @param value The accessibility value of the element to search for.  If @c nil, all values will be accepted.
 @param traits The accessibility traits of the element to search for. Elements that do not include at least these traits are ignored.
 @return The found accessibility element or @c nil if the element could not be found.
 */
- (UIAccessibilityElement *)accessibilityElementWithLabel:(NSString *)label accessibilityValue:(NSString *)value traits:(UIAccessibilityTraits)traits;

/*!
 @abstract Finds an accessibility element where @c matchBlock returns @c YES, across all windows in the application starting at the fronmost window.
 @discussion This method should be used if @c accessibilityElementWithLabel:accessibilityValue:traits: does not meet your requirements.  For example, if you are searching for an element that begins with a pattern or if of a certain view type.
 @param matchBlock  A block to be performed on each element to see if it passes.
 */
- (UIAccessibilityElement *)accessibilityElementMatchingBlock:(BOOL(^)(UIAccessibilityElement *))matchBlock;

/*!
 @returns The window containing the keyboard or @c nil if the keyboard is not visible.
 */
- (UIWindow *)keyboardWindow;

/*!
 @returns The topmost window containing a @c UIDatePicker.
 */
- (UIWindow *)datePickerWindow;

/*!
 @returns The topmost window containing a @c UIPickerView.
 */
- (UIWindow *)pickerViewWindow;

/*!
 @returns The topmost window containing a @c UIDimmingView.
 */
- (UIWindow *)dimmingViewWindow;

/*!
 @returns All windows in the application, including the key window even if it does not appear in @c -windows.
 */
- (NSArray *)windowsWithKeyWindow;

/*!
 The current Core Animation speed of the keyWindow's CALayer.
 */
@property (nonatomic, assign) float animationSpeed;

/*!
 @abstract Writes a screenshot to disk.
 @discussion This method only works if the @c KIF_SCREENSHOTS environment variable is set.
 @param lineNumber The line number in the code at which the screenshot was taken.
 @param filename The name of the file in which the screenshot was taken.
 @param description An optional description of the scene being captured.
 @param error If the method returns @c YES, this optional parameter provides additional information as to why it failed.
 @returns @c YES if the screenshot was written to disk, otherwise @c NO.
 */
- (BOOL)writeScreenshotForLine:(NSUInteger)lineNumber inFile:(NSString *)filename description:(NSString *)description error:(NSError **)error;

/*!
 @returns The current run loop mode.
 */
- (CFStringRef)currentRunLoopMode;

/*!
 @abstract Swizzles the run loop modes so KIF can better switch between them.
 */
+ (void)swizzleRunLoop;

/*!
 @abstract Starts mocking requests to @c -openURL:, announcing all requests with a notification.
 @discussion After calling this method, whenever @c -openURL: is called a notification named @c UIApplicationDidMockOpenURLNotification with the URL in the @c UIApplicationOpenedURL will be raised and the normal behavior will be cancelled.
 @param returnValue The value to return when @c -openURL: is called.
 */
+ (void)startMockingOpenURLWithReturnValue:(BOOL)returnValue;

/*!
 @abstract Stops the application from mocking requests to @c -openURL:.
 */
+ (void)stopMockingOpenURL;

@end

@interface UIApplication (Private)
- (UIWindow *)statusBarWindow;
@property(getter=isStatusBarHidden) BOOL statusBarHidden;
@end

