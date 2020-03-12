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

/**
 *  An NSURLProtocol based network proxy for proxying HTTP requests.
 */
@interface FTRNetworkProxy : NSURLProtocol

/**
 *  @return @c YES if proxy is enabled, @c NO otherwise.
 */
+ (BOOL)ftr_isProxyEnabled;

/**
 *  Enables (if @c enabled is @c YES) or disables the proxy.
 *
 *  @param enabled A BOOL specifying whether to enable or disable the proxy.
 */
+ (void)ftr_setProxyEnabled:(BOOL)enabled;

/**
 *  Sets the simulated network delay that all proxied requests take to complete.
 */
+ (void)ftr_setSimulatedNetworkDelay:(NSTimeInterval)delayInSeconds;

/**
 *  Adds a proxy rule that configures the proxy to serve the given @c data for all URLs matching the
 *  @c regexString, in case of multiple matches the data associated with the last added matching
 *  regex will be used.
 *
 *  @param data        The data to be served for the proxied request.
 *  @param regexString The regex to match URLs on.
 */
+ (void)ftr_addProxyRuleForUrlsMatchingRegexString:(NSString *)regexString
                                    responseString:(NSString *)data;

/**
 *  Removes the last added proxy rule that matches the given @c regexString.
 *
 *  @param regexString The regex to match URLs on.
 */
+ (void)ftr_removeMostRecentProxyRuleMatchingUrlRegexString:(NSString *)regexString;

/**
 *  @return Returns an array of all the requests proxied since the proxy was enabled or since it
 *          was last cleared which ever happened the last.
 */
+ (NSArray *)ftr_requestsReceived;

/**
 *  Clears the array that is used to save all the requests proxied so far.
 */
+ (void)ftr_clearRequestsReceived;

@end
