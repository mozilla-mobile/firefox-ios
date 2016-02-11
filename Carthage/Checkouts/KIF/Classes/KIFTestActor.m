//
//  KIFTester.m
//  KIF
//
//  Created by Brian Nickel on 12/13/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#ifndef KIF_SENTEST
#import <XCTest/XCTest.h>
#import "NSException-KIFAdditions.h"
#else
#import <SenTestingKit/SenTestingKit.h>
#endif

#import "KIFTestActor.h"
#import "NSError-KIFAdditions.h"
#import <dlfcn.h>
#import <objc/runtime.h>
#import "UIApplication-KIFAdditions.h"
#import "UIView-KIFAdditions.h"

@interface AccessibilitySettingsController
- (void)setAXInspectorEnabled:(NSNumber*)enabled specifier:(id)specifier;
@end


@implementation KIFTestActor

+ (void)load
{
    @autoreleasepool {
        NSLog(@"KIFTester loaded");
        [KIFTestActor _enableAccessibility];
        [UIApplication swizzleRunLoop];
    }
}

+ (void)_enableAccessibility;
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
        id axSettingPrefController = [[axSettingsPrefControllerClass alloc] init];
        [axSettingPrefController setAXInspectorEnabled:@(YES) specifier:nil];
    }
}

- (instancetype)initWithFile:(NSString *)file line:(NSInteger)line delegate:(id<KIFTestActorDelegate>)delegate
{
    self = [super init];
    if (self) {
        _file = file;
        _line = line;
        _delegate = delegate;
        _executionBlockTimeout = [[self class] defaultTimeout];
        _animationWaitingTimeout = [[self class] defaultAnimationWaitingTimeout];
    }
    return self;
}

+ (instancetype)actorInFile:(NSString *)file atLine:(NSInteger)line delegate:(id<KIFTestActorDelegate>)delegate
{
    return [[self alloc] initWithFile:file line:line delegate:delegate];
}

- (instancetype)usingTimeout:(NSTimeInterval)executionBlockTimeout
{
    self.executionBlockTimeout = executionBlockTimeout;
    return self;
}

- (BOOL)tryRunningBlock:(KIFTestExecutionBlock)executionBlock complete:(KIFTestCompletionBlock)completionBlock timeout:(NSTimeInterval)timeout error:(out NSError **)error
{
    NSDate *startDate = [NSDate date];
    KIFTestStepResult result;
    NSError *internalError;
    
    while ((result = executionBlock(&internalError)) == KIFTestStepResultWait && -[startDate timeIntervalSinceNow] < timeout) {
        CFRunLoopRunInMode([[UIApplication sharedApplication] currentRunLoopMode] ?: kCFRunLoopDefaultMode, KIFTestStepDelay, false);
    }

    if (result == KIFTestStepResultWait) {
        internalError = [NSError KIFErrorWithUnderlyingError:internalError format:@"The step timed out after %.2f seconds: %@", timeout, internalError.localizedDescription];
        result = KIFTestStepResultFailure;
    }

    if (completionBlock) {
        completionBlock(result, internalError);
    }

    if (error) {
        *error = internalError;
    }
    
    return result != KIFTestStepResultFailure;
}

- (void)runBlock:(KIFTestExecutionBlock)executionBlock complete:(KIFTestCompletionBlock)completionBlock timeout:(NSTimeInterval)timeout
{
    NSError *error = nil;
    if (![self tryRunningBlock:executionBlock complete:completionBlock timeout:timeout error:&error]) {
        [self failWithError:error stopTest:YES];
    }
}

- (void)runBlock:(KIFTestExecutionBlock)executionBlock complete:(KIFTestCompletionBlock)completionBlock
{
    [self runBlock:executionBlock complete:completionBlock timeout:self.executionBlockTimeout];
}

- (void)runBlock:(KIFTestExecutionBlock)executionBlock timeout:(NSTimeInterval)timeout
{
    [self runBlock:executionBlock complete:nil timeout:timeout];
}

- (void)runBlock:(KIFTestExecutionBlock)executionBlock
{
    [self runBlock:executionBlock complete:nil];
}


#pragma mark Class Methods

static NSTimeInterval KIFTestStepDefaultAnimationWaitingTimeout = 0.5;
static NSTimeInterval KIFTestStepDefaultTimeout = 10.0;
static NSTimeInterval KIFTestStepDelay = 0.1;

+ (NSTimeInterval)defaultAnimationWaitingTimeout
{
    return KIFTestStepDefaultAnimationWaitingTimeout;
}

+ (void)setDefaultAnimationWaitingTimeout:(NSTimeInterval)newDefaultAnimationWaitingTimeout;
{
    KIFTestStepDefaultAnimationWaitingTimeout = newDefaultAnimationWaitingTimeout;
}

+ (NSTimeInterval)defaultTimeout;
{
    return KIFTestStepDefaultTimeout;
}

+ (void)setDefaultTimeout:(NSTimeInterval)newDefaultTimeout;
{
    KIFTestStepDefaultTimeout = newDefaultTimeout;
}

+ (NSTimeInterval)stepDelay;
{
    return KIFTestStepDelay;
}

+ (void)setStepDelay:(NSTimeInterval)newStepDelay;
{
    KIFTestStepDelay = newStepDelay;
}

#pragma mark Generic tests

- (void)fail
{
    [self runBlock:^KIFTestStepResult(NSError **error) {
        KIFTestCondition(NO, error, @"This test always fails");
    }];
}

- (void)failWithError:(NSError *)error stopTest:(BOOL)stopTest
{
    [self.delegate failWithException:[NSException failureInFile:self.file atLine:(int)self.line withDescription:error.localizedDescription] stopTest:stopTest];
}

- (void)waitForTimeInterval:(NSTimeInterval)timeInterval
{
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    
    [self runBlock:^KIFTestStepResult(NSError **error) {
        KIFTestWaitCondition((([NSDate timeIntervalSinceReferenceDate] - startTime) >= timeInterval), error, @"Waiting for time interval to expire.");
        return KIFTestStepResultSuccess;
    } timeout:timeInterval + 1];
}

@end

@implementation KIFTestActor (Delegate)

- (void)failWithException:(NSException *)exception stopTest:(BOOL)stop
{
    [self failWithExceptions:@[exception] stopTest:stop];
}

- (void)failWithExceptions:(NSArray *)exceptions stopTest:(BOOL)stop
{
    NSException *firstException = [exceptions objectAtIndex:0];
    NSException *newException = [NSException failureInFile:self.file atLine:(int)self.line withDescription:@"Failure in child step: %@", firstException.description];

    [self.delegate failWithExceptions:[exceptions arrayByAddingObject:newException] stopTest:stop];
}

@end
