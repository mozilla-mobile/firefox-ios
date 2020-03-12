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

#import "FTRNetworkProxy.h"

/**
 *  Specifies if the proxy is enabled or not.
 */
static BOOL gFTRProxyEnabled;

/**
 *  Specifies the simulated delay that the proxy injects into the proxied requests.
 */
static NSTimeInterval gFTRProxySimulatedDelayInSeconds;

/**
 *  Stores list of all URLs proxied so far.
 */
static NSMutableArray *gFTRProxiedURLs;

/**
 *  An array of dictionaries with regex and the response string to be served for URLs matching that
 *  regex.
 */
static NSMutableArray *gFTRProxyRules;

/**
 *  Key to proxy rule's regex string value.
 */
static NSString *const kFTRNetworkProxyRuleRegexKey = @"kFTRNetworkProxyRuleRegexKey";

/**
 *  Key to proxy rule's response string value.
 */
static NSString *const kFTRNetworkProxyRuleResponseKey = @"kFTRNetworkProxyRuleResponseKey";

/**
 *  Error domain for errors occurring in FTRNetworkProxy.
 */
static NSString *const kFTRNetworkProxyErrorDomain =
    @"com.google.earlgrey.FTRNetworkProxyErrorDomain";

@implementation FTRNetworkProxy

+ (void)ftr_setProxyEnabled:(BOOL)enabled {
  @synchronized(self) {
    gFTRProxyEnabled = enabled;
    gFTRProxiedURLs = nil;
  }
}

+ (BOOL)ftr_isProxyEnabled {
  @synchronized(self) {
    return gFTRProxyEnabled;
  }
}

+ (void)ftr_setSimulatedNetworkDelay:(NSTimeInterval)delayInSeconds {
  gFTRProxySimulatedDelayInSeconds = delayInSeconds;
}

+ (void)ftr_addProxyRuleForUrlsMatchingRegexString:(NSString *)regexString
                                    responseString:(NSString *)data {
  @synchronized(self) {
    if (!gFTRProxyRules) {
      gFTRProxyRules = [[NSMutableArray alloc] init];
    }
    [gFTRProxyRules addObject:@{ kFTRNetworkProxyRuleRegexKey: regexString,
                                 kFTRNetworkProxyRuleResponseKey: data }];
    if ([gFTRProxyRules count] == 1) {
      // First rule has been added start proxying now.
      if (![NSURLProtocol registerClass:[self class]]) {
        NSAssert(NO, @"FTRNetworkProxy could not be installed");
      }
      gFTRProxiedURLs = nil;
    }
  }
}

+ (void)ftr_removeMostRecentProxyRuleMatchingUrlRegexString:(NSString *)regexString {
  @synchronized(self) {
    for (NSDictionary *rule in gFTRProxyRules.reverseObjectEnumerator) {
      if ([rule[kFTRNetworkProxyRuleRegexKey] isEqualToString:regexString]) {
        [gFTRProxyRules removeObject:rule];
        if ([gFTRProxyRules count] == 0) {
          // All rules have been removed, uninstall the proxy.
          [NSURLProtocol unregisterClass:[self class]];
        }
        return;
      }
    }
    NSAssert(NO, @"%@ regex did not match any existing rule.", regexString);
  }
}

+ (NSArray *)ftr_requestsReceived {
  @synchronized(self) {
    return [NSArray arrayWithArray:gFTRProxiedURLs];
  }
}

+ (void)ftr_clearRequestsReceived {
  @synchronized(self) {
    gFTRProxiedURLs = nil;
  }
}

#pragma mark - Private

/**
 *  @return @c YES if the proxy is setup to proxy the URL specified in @c urlString.
 */
+ (BOOL)ftr_isRequestProxiedWithURLString:(NSString *)urlString {
  @synchronized(self) {
    if (!gFTRProxyEnabled) {
      return NO;
    }
    for (NSDictionary *rule in gFTRProxyRules.reverseObjectEnumerator) {
      NSError *error;
      NSString *regexString = rule[kFTRNetworkProxyRuleRegexKey];
      NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString
                                                                             options:0
                                                                               error:&error];
      NSAssert(!error, @"Invalid regex:\"%@\". See error: %@",
               regexString, [error localizedDescription]);
      if ([regex numberOfMatchesInString:urlString
                                 options:0
                                   range:NSMakeRange(0, [urlString length])]) {
        return YES;
      }
    }
    return NO;
  }
}

/**
 *  @return The response string to be served by the proxy for the URL specified in @c urlString,
 *          or @c nil if the URL is not to be proxied.
 */
+ (NSString *)ftr_responseWithURLString:(NSString *)urlString {
  @synchronized(self) {
    for (NSDictionary *rule in gFTRProxyRules.reverseObjectEnumerator) {
      NSError *error;
      NSString *regexString = rule[kFTRNetworkProxyRuleRegexKey];
      NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:regexString
                                                                             options:0
                                                                               error:&error];
      NSAssert(!error, @"Invalid regex:\"%@\". See error: %@", regexString, error);
      if ([regex numberOfMatchesInString:urlString
                                 options:0
                                   range:NSMakeRange(0, [urlString length])] > 0) {
        return rule[kFTRNetworkProxyRuleResponseKey];
      }
    }
  }
  return nil;
}

#pragma mark - NSURLProtocol

+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
  return [FTRNetworkProxy ftr_isRequestProxiedWithURLString:request.URL.absoluteString];
}

/**
 *  @remark This is a required overidden method.
 *
 *  @return A canonical version of the specified @c request.
 */
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
  return request;
}

- (NSCachedURLResponse *)cachedResponse {
  return nil; // returning nil to indicate that supported URLs are never cached.
}

- (void)startLoading {
  NSString *absoluteUrl = self.request.URL.absoluteString;
  @synchronized([FTRNetworkProxy class]) {
    if (gFTRProxiedURLs == nil) {
      gFTRProxiedURLs = [[NSMutableArray alloc] init];
    }
    [gFTRProxiedURLs addObject:absoluteUrl];
  }
  NSString *data = [FTRNetworkProxy ftr_responseWithURLString:absoluteUrl];
  if (data) {
    // Simulate a delay if set.
    if (gFTRProxySimulatedDelayInSeconds > 0) {
      [NSThread sleepForTimeInterval:gFTRProxySimulatedDelayInSeconds];
    }

    // Create a HTTP response with the proxied data.
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                              statusCode:200
                                                             HTTPVersion:@"HTTP/1.1"
                                                            headerFields:@{}];

    // Serve the proxied request.
    [self.client URLProtocol:self
          didReceiveResponse:response
          cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [self.client URLProtocol:self didLoadData:[data dataUsingEncoding:NSUTF8StringEncoding]];
    [self.client URLProtocolDidFinishLoading:self];
  } else {
    // Serve 404.
    NSString *errorDescription =
        [NSString stringWithFormat:@"Request %@ proxied to 404.", self.request];
    NSError *error = [NSError errorWithDomain:kFTRNetworkProxyErrorDomain
                                         code:404
                                     userInfo:@{ NSLocalizedDescriptionKey : errorDescription }];
    [self.client URLProtocol:self didFailWithError:error];
  }
}


/**
 * @remark This is a required overidden method that stops loading an URL.
 */
- (void)stopLoading {
}

@end
