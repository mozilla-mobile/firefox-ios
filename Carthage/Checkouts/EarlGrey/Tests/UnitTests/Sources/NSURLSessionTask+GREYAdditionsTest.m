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

#import "Synchronization/GREYAppStateTracker.h"
#import "GREYBaseTest.h"

// A global used by GREYUTURLProxyProtocol to determine whether to serve error (404) responses
// or test data.
static BOOL gShouldServeError;

// The response delay simulated by GREYUTURLProxyProtocol for all requests.
static const CFTimeInterval kResponseDelayInSeconds = 1.0;

// A NSURLProtocol class that serves http requests locally with the constraints set up by the test.
@interface GREYUTURLProxyProtocol : NSURLProtocol

// Sets up GREYUTURLProxyProtocol to either serve error (404) responses (|shouldServeError| is YES)
// or test data (|shouldServeError| is NO).
+ (void)setupURLToServeError:(BOOL)shouldServeError;
@end

@implementation GREYUTURLProxyProtocol

+ (void)setupURLToServeError:(BOOL)errorEnabled {
  gShouldServeError = errorEnabled;
}

// Returns YES to override all http requests.
+ (BOOL)canInitWithRequest:(NSURLRequest *)request {
  return [request.URL.scheme isEqualToString:@"http"];
}

// A required overidden method.
+ (NSURLRequest *)canonicalRequestForRequest:(NSURLRequest *)request {
  return request;
}

- (NSCachedURLResponse *)cachedResponse {
  return nil; // returning nil to indicate that supported URLs are never cached.
}

- (void)startLoading {
  if (gShouldServeError) {
    // Simulate a response delay and serve a 404.
    [NSThread sleepForTimeInterval:kResponseDelayInSeconds];
    NSString *errorDescription =
        [NSString stringWithFormat:@"Failing for test request %@.", self.request];
    NSError *error = [NSError errorWithDomain:@"Server connection error"
                                         code:404
                                     userInfo:@{ NSLocalizedDescriptionKey : errorDescription }];
    [self.client URLProtocol:self didFailWithError:error];
  } else {
    // Create a HTTP response with the test data.
    NSDictionary *headers = @{ @"Content-Type": @"text/plain" };
    NSHTTPURLResponse *response = [[NSHTTPURLResponse alloc] initWithURL:self.request.URL
                                                              statusCode:200
                                                             HTTPVersion:@"HTTP/1.1"
                                                            headerFields:headers];

    // Serve the response with simulated delay.
    CFTimeInterval delay = kResponseDelayInSeconds / 3.0;
    [NSThread sleepForTimeInterval:delay];
    [self.client URLProtocol:self
          didReceiveResponse:response
          cacheStoragePolicy:NSURLCacheStorageNotAllowed];
    [NSThread sleepForTimeInterval:delay];
    [self.client URLProtocol:self
                 didLoadData:[@"Test Data" dataUsingEncoding:NSUTF8StringEncoding]];
    [NSThread sleepForTimeInterval:delay];
    [self.client URLProtocolDidFinishLoading:self];
  }
}

// A required overidden method.
- (void)stopLoading {
}

@end

@interface NSURLSessionTask_GREYAdditionsTest : GREYBaseTest
@end

@implementation NSURLSessionTask_GREYAdditionsTest {
  // Indicates if the test response has been fetched or not.
  __block BOOL _fetchIsComplete;

  // Indicates if an error is expected in the test response.
  __block BOOL _expectError;
}

- (void)setUp {
  [super setUp];

  _fetchIsComplete = NO;
  _expectError = NO;
  [NSURLProtocol registerClass:[GREYUTURLProxyProtocol class]];
}

- (void)tearDown {
  [NSURLProtocol unregisterClass:[GREYUTURLProxyProtocol class]];

  [super tearDown];
}

- (void)testSynchronizationWorksForValidURLs {
  [GREYUTURLProxyProtocol setupURLToServeError:NO];

  [self assertIdle];
  [self beginFetchUsingConfiguration:nil];
  [self assertBusy];
  [self assertBusyWhileWaitingForNewtworkRequest];
}

- (void)testSynchronizationWorksForFailingURLs {
  _expectError = YES;
  [GREYUTURLProxyProtocol setupURLToServeError:YES];

  [self assertIdle];
  [self beginFetchUsingConfiguration:nil];
  [self assertBusy];
  [self assertBusyWhileWaitingForNewtworkRequest];
}

- (void)testSynchronizationWorksWithTimeout {
  [GREYUTURLProxyProtocol setupURLToServeError:NO];

  // Setup request and resource timeouts to ensure that test requests always timeout.
  NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
  config.timeoutIntervalForRequest = kResponseDelayInSeconds / 2;
  config.timeoutIntervalForResource = kResponseDelayInSeconds / 2;
  _expectError = YES; // Expect timeout errors.

  [self assertIdle] ;
  [self beginFetchUsingConfiguration:config];
  [self assertBusy];
  [self assertBusyWhileWaitingForNewtworkRequest];
}

#pragma mark - Helper Methods

// Asserts that |GREYNSURLSessionIdlingResource| is idle.
- (void)assertIdle {
  XCTAssertFalse([[GREYAppStateTracker sharedInstance] currentState] & kGREYPendingNetworkRequest,
                 @"Must *NOT* be pending any network requests.");
}

// Asserts that |GREYNSURLSessionIdlingResource| is busy.
- (void)assertBusy {
  XCTAssertTrue([[GREYAppStateTracker sharedInstance] currentState] & kGREYPendingNetworkRequest,
                @"Must be pending network request.");
}

// Asserts that |GREYNSURLSessionIdlingResource| is busy while network fetch is not complete, the
// method blocks until the fetch is complete.
- (void)assertBusyWhileWaitingForNewtworkRequest {
  NSTimeInterval timeoutTime = CACurrentMediaTime() + kResponseDelayInSeconds + 1.0;
  // Wait for network fetch to be complete within 1.0 of possible response delay.
  while (CACurrentMediaTime() < timeoutTime && !_fetchIsComplete) {
    [self assertBusy];
    CFRunLoopRunInMode(kCFRunLoopDefaultMode, 0.1, false);
  }
  XCTAssertTrue(_fetchIsComplete, @"Timed out waiting for network fetch to complete.");
}

// Initiates a network fetch using the given |configOrNil|, if |configOrNil| is nil the default
// configuration is used.
- (void)beginFetchUsingConfiguration:(NSURLSessionConfiguration *)configOrNil {
  _fetchIsComplete = NO;
  NSURLSession *session;
  if (configOrNil) {
    session = [NSURLSession sessionWithConfiguration:configOrNil];
  } else {
    session = [NSURLSession sharedSession];
  }
  NSURLSessionTask *task =
      [session dataTaskWithURL:[NSURL URLWithString:@"http://www.youtube.com/"]
             completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
               _fetchIsComplete = YES;
               NSAssert(error && _expectError || !error && !_expectError,
                        @"Error assertion has failed with %@.", error);
  }];
  [task resume];
}

@end
