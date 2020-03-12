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

#import <EarlGrey/GREYMatcher.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  A class to transform an OCHamcrest matcher and into a GREYMatcher instance.
 *  Since EarlGrey requires its matchers to conform to the GREYMatcher protocol, this class provides
 *  a convinient way to represent OCHamcrest matchers as GREYMatchers.
 */
@interface GREYHCMatcher : NSObject<GREYMatcher>

/**
 *  This method takes in a matcher object conforming to HCMatcher protocol and returns an object
 *  conforming to the GREYMatcher protocol.
 *
 *  @param HCMatcher The OCHamcrest matcher to be transformed.
 *
 *  @return An object conforming to GREYMatcher protocol that uses the provided @c HCMatcher for
 *          as the matcher.
 */
- (instancetype)initWithHCMatcher:(id)HCMatcher;

@end

NS_ASSUME_NONNULL_END
