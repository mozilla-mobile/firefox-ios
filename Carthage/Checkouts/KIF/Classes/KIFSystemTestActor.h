//
//  KIFTester+Generic.h
//  KIF
//
//  Created by Brian Nickel on 12/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "KIFTestActor.h"
#import <UIKit/UIKit.h>


#define systemTester KIFActorWithClass(KIFSystemTestActor)

// The symbol `system` collides with the cstdlib for compiling C++. Leaving it available for compatibility reasons.
// This will be removed with the next major KIF release, please start using `systemTester` instead.
#ifndef __cplusplus

#if DEPRECATE_KIF_SYSTEM
// Add `-DDEPRECATE_KIF_SYSTEM=1` to OTHER_CFLAGS if you'd like to prevent usage of the `system` macro.
@class KIFSystemTestActor;
KIFSystemTestActor *_KIF_system() __attribute__((deprecated("Use of `system` has been deprecated; Use `systemTester` instead.")));
#define system _KIF_system()
#else
#define system KIFActorWithClass(KIFSystemTestActor)
#endif

#endif

@interface KIFSystemTestActor : KIFTestActor

/*!
 @abstract Waits for a specific NSNotification.
 @discussion Useful when a test requires an asynchronous task to complete, especially when that task does not trigger a visible change in the view hierarchy.
 @param name The name of the NSNotification.
 @param object The object to which the step should listen. Nil value will listen to all objects.
 @return The detected NSNotification.
 */
- (NSNotification *)waitForNotificationName:(NSString*)name object:(id)object;

/*!
 @abstract Waits for a specific NSNotification, emitted during or after execution of a block.
 @discussion Useful when step execution causes a notification to be emitted, but executes too quickly for waitForNotificationName: to observe it.
 An observer will be registered for the notification before the block is executed.
 @param name The name of the NSNotification.
 @param object The object to which the step should listen. Nil value will listen to all objects.
 @param block The block of code to be executed.
 @return The detected NSNotification.
 */
- (NSNotification *)waitForNotificationName:(NSString *)name object:(id)object whileExecutingBlock:(void(^)(void))block;

/*!
 @abstract Simulates a memory warning.
 */
- (void)simulateMemoryWarning;

/*!
 @abstract Simulates a device rotation to a specific orentation from its last set orientation.
 @discussion The first time this method is called, it will be from the device's natural orientation to the orientation described.
 @param orientation The desired orientation.
 */
- (void)simulateDeviceRotationToOrientation:(UIDeviceOrientation)orientation;

/*!
 @abstract Waits for the application to request a specific URL while executing a block.
 @param URLString The absolute string representation of the URL to detect.
 @param block The block of code to be executed.
 @param returnValue The value to return from @c +[UIApplication openURL:].
 */
- (void)waitForApplicationToOpenURL:(NSString *)URLString whileExecutingBlock:(void(^)(void))block returning:(BOOL)returnValue;

/*!
 @abstract Waits for the application to request any URL while executing a block.
 @param block The block of code to be executed.
 @param returnValue The value to return from @c +[UIApplication openURL:].
 */
- (void)waitForApplicationToOpenAnyURLWhileExecutingBlock:(void(^)(void))block returning:(BOOL)returnValue;

/*!
 @abstract Waits for the application to request any URL with the given URL Scheme while executing a block.
 @param URLScheme The scheme component of the URL to detect.
 @param block The block of code to be executed.
 @param returnValue The value to return from @c +[UIApplication openURL:].
 */
- (void)waitForApplicationToOpenURLWithScheme:(NSString *)URLScheme whileExecutingBlock:(void (^)(void))block returning:(BOOL)returnValue;

/*!
 @abstract Captured a screenshot of the current screen and writes it to disk with an optional description.
 @discussion This step will fail if the @c KIF_SCREENSHOTS environment variable is not set or if the screenshot cannot be written to disk.
 @param description A description to use when writing the file to disk.
 */
- (void)captureScreenshotWithDescription:(NSString *)description;

/*!
 @abstract Backgrounds app using UIAutomation command, simulating pressing the Home button
 @param duration Amount of time for a background event before the app becomes active again
 */
- (void)deactivateAppForDuration:(NSTimeInterval)duration;

@end
