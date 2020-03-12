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

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Class responsible for preparing the test environment for automation.
 */
@interface GREYAutomationSetup : NSObject

/**
 *  @return The singleton instance.
 */
+ (instancetype)sharedInstance;

/**
 *  @remark init is not an available initializer. Use singleton instance.
 */
- (instancetype)init NS_UNAVAILABLE;

/**
 * Perform setup actions as the EarlGrey frameworked is loaded. Setup actions performed here are:
 *
 * * Turn on accessibility if on a simulator.
 * * Install crash handlers
 *
 * @remark Must be called during XCTestCase invocation, otherwise the behavior is undefined.
 */
- (void)prepareOnLoad;

/**
 *
 * Performs setup actions as the test case is invoked. Setup actions performed here are:
 *
 * * Turn on accessibility if on a device.
 * * Turn off autocorrect on software keyboard
 *
 * @remark Must be called before test starts and after the Earlgrey library is loaded in memory.
 *         For iOS 11, the UI is seen to fade / turn black as soon as we call these
 *         keyboard-related methods. This might be caused due to the keyboard modifications
 *         coinciding with the UI being loaded. For this purpose, we now perform changes for
 *         keyboard modifications when the test is invoked rather than in +load.
 */
- (void)preparePostLoad;

@end

NS_ASSUME_NONNULL_END
