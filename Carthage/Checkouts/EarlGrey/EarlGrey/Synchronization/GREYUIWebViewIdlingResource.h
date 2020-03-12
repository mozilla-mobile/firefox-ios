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

#if !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0

#import <EarlGrey/GREYIdlingResource.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  An idling resource used for detecting when a UIWebView has loaded all the required resources,
 *  rendered, and generated its accessibility element tree.
 */
@interface GREYUIWebViewIdlingResource : NSObject<GREYIdlingResource>

/**
 *  Creates and registers an idling resource before returning the created instance.
 *
 *  @param webView The UIWebView being tracked.
 *  @param name The name used to identify this idling resource.
 *  @return instance of GREYUIWebViewIdlingResource for the provided @c webView.
 */
+ (instancetype)idlingResourceForWebView:(UIWebView *)webView name:(NSString *)name;

/**
 *  @remark init is not an available initializer. Use the other initializers.
 */
- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END

#endif  // !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0
