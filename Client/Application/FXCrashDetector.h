/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

@import Foundation;

@protocol FXCrashDetectorData

- (void)setExceptionForPreviousCrash:(NSException *)exception;
- (void)setSignalForPreviousCrash:(int)signal;
- (void)clearPreviousCrash;
- (BOOL)containsCrash;

@end

@interface FXCrashDetector : NSObject

@property (nonatomic, strong, readonly) id<FXCrashDetectorData> crashData;

+ (id)sharedDetector;

- (BOOL)hasCrashed;
- (void)listenForCrashes;

@end
