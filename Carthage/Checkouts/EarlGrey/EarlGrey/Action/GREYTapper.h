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

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Class containing utility methods for performing taps.
 */
@interface GREYTapper : NSObject

/**
 *  Taps on an element at a location for a number of times.
 *
 *  @param      element      The element to be tapped.
 *  @param      numberOfTaps The number of taps.
 *  @param      location     The location to be tapped, relative to the view being tapped.
 *  @param[out] errorOrNil   Error that will be populated on failure with the cause of failure. If
 *                           an action succeeds, then it is @c nil. However, if there is a failure
 *                           and it is @c nil, then an error is logged to console.
 *
 *  @return @c YES if the action succeeded, else @c NO.
 */
+ (BOOL)tapOnElement:(id)element
        numberOfTaps:(NSUInteger)numberOfTaps
            location:(CGPoint)location
               error:(__strong NSError **)errorOrNil;

/**
 *  Taps on a window at a location for a number of times.
 *
 *  @param      window       The window to be tapped.
 *  @param      numberOfTaps The number of taps.
 *  @param      location     The location to be tapped, relative to the view being tapped.
 *  @param[out] errorOrNil   Error that will be populated on failure with the cause of failure. If
 *                           @c nil, then an error with code
 *                           @c kGREYInteractionActionFailedErrorCode is logged to console.
 *
 *  @return @c YES if the action succeeded, else @c NO.
 */
+ (BOOL)tapOnWindow:(UIWindow *)window
        numberOfTaps:(NSUInteger)numberOfTaps
            location:(CGPoint)location
               error:(__strong NSError **)errorOrNil;

/**
 *  Performs a long press on an element for a specified duration.
 *
 *  @param      element    The element on which the long press should be performed.
 *  @param      location   The touch location, relative to the view being long pressed.
 *  @param      duration   The duration of the long press.
 *  @param[out] errorOrNil Error that will be populated on failure with the cause of failure. If
 *                         @c nil, then an error with code @c kGREYInteractionActionFailedErrorCode
 *                         is logged to console.
 *
 *  @return @c YES if the action succeeded, else @c NO.
 */
+ (BOOL)longPressOnElement:(id)element
                  location:(CGPoint)location
                  duration:(CFTimeInterval)duration
                     error:(__strong NSError **)errorOrNil;
@end

NS_ASSUME_NONNULL_END
