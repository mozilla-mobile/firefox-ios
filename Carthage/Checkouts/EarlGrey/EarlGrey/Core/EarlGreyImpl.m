//
// Copyright 2016 Google Inc.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "Core/EarlGreyImpl.h"

#import "Common/GREYAnalytics.h"
#import "Common/GREYAppleInternals.h"
#import "Common/GREYError.h"
#import "Common/GREYErrorConstants.h"
#import "Common/GREYFatalAsserts.h"
#import "Core/GREYKeyboard.h"
#import "Event/GREYSyntheticEvents.h"
#import "Exception/GREYDefaultFailureHandler.h"
#import "Synchronization/GREYUIThreadExecutor.h"
#import "EarlGrey.h"

NSString *const kGREYFailureHandlerKey = @"GREYFailureHandlerKey";
NSString *const kGREYKeyboardDismissalErrorDomain = @"com.google.earlgrey.KeyboardDismissalDomain";

@implementation EarlGreyImpl

+ (void)load {
  @autoreleasepool {
    // These need to be set in load since someone might call GREYAssertXXX APIs without calling
    // into EarlGrey.
    resetFailureHandler();
  }
}

+ (instancetype)invokedFromFile:(NSString *)fileName lineNumber:(NSUInteger)lineNumber {
  static EarlGreyImpl *instance = nil;
  static dispatch_once_t token = 0;
  dispatch_once(&token, ^{
    instance = [[EarlGreyImpl alloc] initOnce];
  });

  SEL invocationFileAndLineSEL = @selector(setInvocationFile:andInvocationLine:);
  id<GREYFailureHandler> failureHandler;
  @synchronized (self) {
    failureHandler = grey_getFailureHandler();
  }
  if ([failureHandler respondsToSelector:invocationFileAndLineSEL]) {
    [failureHandler setInvocationFile:fileName andInvocationLine:lineNumber];
  }
  [[GREYAnalytics sharedInstance] didInvokeEarlGrey];
  return instance;
}

- (instancetype)initOnce {
  self = [super init];
  return self;
}

- (GREYElementInteraction *)selectElementWithMatcher:(id<GREYMatcher>)elementMatcher {
  return [[GREYElementInteraction alloc] initWithElementMatcher:elementMatcher];
}

- (void)setFailureHandler:(id<GREYFailureHandler>)handler {
  GREYFatalAssertMainThread();
  @synchronized ([self class]) {
    if (handler) {
      NSMutableDictionary *TLSDict = [[NSThread mainThread] threadDictionary];
      [TLSDict setValue:handler forKey:kGREYFailureHandlerKey];
    } else {
      resetFailureHandler();
    }
  }
}

- (void)handleException:(GREYFrameworkException *)exception details:(NSString *)details {
  @synchronized ([self class]) {
    id<GREYFailureHandler> failureHandler = grey_getFailureHandler();
    [failureHandler handleException:exception details:details];
  }
}

- (BOOL)rotateDeviceToOrientation:(UIDeviceOrientation)deviceOrientation
                       errorOrNil:(__strong NSError **)errorOrNil {
  return [GREYSyntheticEvents rotateDeviceToOrientation:deviceOrientation errorOrNil:errorOrNil];
}

- (BOOL)shakeDeviceWithError:(__strong NSError **)errorOrNil {
  return [GREYSyntheticEvents shakeDeviceWithError:errorOrNil];
}

- (BOOL)dismissKeyboardWithError:(__strong NSError **)errorOrNil {
  __block NSError *executionError;
  [[GREYUIThreadExecutor sharedInstance] executeSync:^{
    if (![GREYKeyboard isKeyboardShown]) {
      executionError = GREYErrorMake(kGREYKeyboardDismissalErrorDomain,
                                     GREYKeyboardDismissalFailedErrorCode,
                                     @"Failed to dismiss keyboard since it was not showing.");
    } else {
      [[UIApplication sharedApplication] sendAction:@selector(resignFirstResponder)
                                                 to:nil
                                               from:nil
                                           forEvent:nil];
    }
  } error:&executionError];

  if (executionError) {
    if (errorOrNil) {
      *errorOrNil = executionError;
    } else {
      I_GREYFail(@"%@\nError: %@",
                 @"Dismising keyboard errored out.",
                 [GREYError grey_nestedDescriptionForError:executionError]);
    }
    return NO;
  }
  return YES;
}

#pragma mark - Private

// Resets the failure handler. Must be called from main thread otherwise behavior is undefined.
static inline void resetFailureHandler() {
  assert([NSThread isMainThread]);
  NSMutableDictionary *TLSDict = [[NSThread mainThread] threadDictionary];
  [TLSDict setValue:[[GREYDefaultFailureHandler alloc] init] forKey:kGREYFailureHandlerKey];
}

// Gets the failure handler. Must be called from main thread otherwise behavior is undefined.
inline id<GREYFailureHandler> grey_getFailureHandler() {
  assert([NSThread isMainThread]);
  NSMutableDictionary *TLSDict = [[NSThread mainThread] threadDictionary];
  return [TLSDict valueForKey:kGREYFailureHandlerKey];
}

@end
