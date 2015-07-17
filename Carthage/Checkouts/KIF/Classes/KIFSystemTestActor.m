//
//  KIFTester+Generic.m
//  KIF
//
//  Created by Brian Nickel on 12/14/12.
//  Licensed to Square, Inc. under one or more contributor license agreements.
//  See the LICENSE file distributed with this work for the terms under
//  which Square, Inc. licenses this file to you.

#import "KIFSystemTestActor.h"
#import <UIKit/UIKit.h>
#import "UIApplication-KIFAdditions.h"
#import "NSError-KIFAdditions.h"

@implementation KIFSystemTestActor

- (NSNotification *)waitForNotificationName:(NSString*)name object:(id)object
{
    return [self waitForNotificationName:name object:object whileExecutingBlock:nil];
}

- (NSNotification *)waitForNotificationName:(NSString *)name object:(id)object whileExecutingBlock:(void(^)())block
{
    return [self waitForNotificationName:name object:object whileExecutingBlock:block complete:nil];
}

- (NSNotification *)waitForNotificationName:(NSString *)name object:(id)object whileExecutingBlock:(void(^)())block complete:(void(^)())complete
{
    __block NSNotification *detectedNotification = nil;
    id observer = [[NSNotificationCenter defaultCenter] addObserverForName:name object:object queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        detectedNotification = note;
    }];
    
    if (block) {
        block();
    }
    
    [self runBlock:^KIFTestStepResult(NSError **error) {
        KIFTestWaitCondition(detectedNotification, error, @"Waiting for notification \"%@\"", name);
        return KIFTestStepResultSuccess;
    } complete:^(KIFTestStepResult result, NSError *error) {
        [[NSNotificationCenter defaultCenter] removeObserver:observer];
        
        if (complete) {
            complete();
        }
    }];
    
    return detectedNotification;
}

- (void)simulateMemoryWarning
{
    [[NSNotificationCenter defaultCenter] postNotificationName:UIApplicationDidReceiveMemoryWarningNotification object:[UIApplication sharedApplication]];
}

- (void)simulateDeviceRotationToOrientation:(UIDeviceOrientation)orientation
{
    if ([[UIApplication sharedApplication] respondsToSelector:@selector(rotateIfNeeded:completion:)]) {
        dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
        [[UIApplication sharedApplication] rotateIfNeeded:orientation completion:^{
            dispatch_semaphore_signal(semaphore);
        }];
        while (dispatch_semaphore_wait(semaphore, DISPATCH_TIME_NOW)) {
            CFRunLoopRunInMode([[UIApplication sharedApplication] currentRunLoopMode] ?: kCFRunLoopDefaultMode, 0.1, false);
        }
    } else {
        [[UIApplication sharedApplication] rotateIfNeeded:orientation];
    }
}


- (void)waitForApplicationToOpenAnyURLWhileExecutingBlock:(void (^)())block returning:(BOOL)returnValue
{
    [self waitForApplicationToOpenURL:nil whileExecutingBlock:block returning:returnValue];
}

- (void)waitForApplicationToOpenURLWithScheme:(NSString *)URLScheme whileExecutingBlock:(void (^)())block returning:(BOOL)returnValue {
    [self waitForApplicationToOpenURLMatchingBlock:^(NSURL *actualURL){
        if (URLScheme && ![URLScheme isEqualToString:actualURL.scheme]) {
            [self failWithError:[NSError KIFErrorWithFormat:@"Expected %@ to start with %@", actualURL.absoluteString, URLScheme] stopTest:YES];
        }
    } whileExecutingBlock:block returning:returnValue];
}

- (void)waitForApplicationToOpenURL:(NSString *)URLString whileExecutingBlock:(void (^)())block returning:(BOOL)returnValue {
    [self waitForApplicationToOpenURLMatchingBlock:^(NSURL *actualURL){

        if (URLString && ![[actualURL absoluteString] isEqualToString:URLString]) {
            [self failWithError:[NSError KIFErrorWithFormat:@"Expected %@, got %@", URLString, actualURL.absoluteString] stopTest:YES];
        }
    } whileExecutingBlock:block returning:returnValue];
}

- (void)waitForApplicationToOpenURLMatchingBlock:(void (^)(NSURL *actualURL))URLMatcherBlock whileExecutingBlock:(void (^)())block returning:(BOOL)returnValue
{
    [UIApplication startMockingOpenURLWithReturnValue:returnValue];
    NSNotification *notification = [self waitForNotificationName:UIApplicationDidMockOpenURLNotification object:[UIApplication sharedApplication] whileExecutingBlock:block complete:^{
        [UIApplication stopMockingOpenURL];
    }];

    if (URLMatcherBlock) {
        NSURL *actualURL = [notification.userInfo objectForKey:UIApplicationOpenedURLKey];
        URLMatcherBlock(actualURL);
    }
}

- (void)captureScreenshotWithDescription:(NSString *)description
{
    NSError *error;
    if (![[UIApplication sharedApplication] writeScreenshotForLine:(NSUInteger)self.line inFile:self.file description:description error:&error]) {
        [self failWithError:error stopTest:NO];
    }
}

@end
