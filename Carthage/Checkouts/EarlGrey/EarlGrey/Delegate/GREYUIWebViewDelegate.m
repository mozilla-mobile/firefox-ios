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

#import "Delegate/GREYUIWebViewDelegate.h"

#if !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0

#import "Additions/UIWebView+GREYAdditions.h"

#import "Synchronization/GREYAppStateTracker.h"
#import "Synchronization/GREYUIThreadExecutor+Internal.h"
#import "Synchronization/GREYUIWebViewIdlingResource.h"

static NSString *const kAjaxListenerScheme = @"greyajaxlistener";
static NSString *const kAjaxListenerScript =
    @"function __ajaxHandlerScript() {                                                            "
    @"  if (typeof grey_ajaxListener === 'undefined') {                                           "
    @"    var grey_ajaxListener = new Object();                                                   "
    @"    /* Store original functions before overriding them. */                                  "
    @"    grey_ajaxListener.originalOpen = XMLHttpRequest.prototype.open;                         "
    @"    grey_ajaxListener.originalSend = XMLHttpRequest.prototype.send;                         "
    @"    /* Function for sending a status update to the web view's delegate. */                  "
    @"    grey_ajaxListener.updateStatus = function(a) {                                          "
    @"      window.open('greyajaxlistener://' + a);                                               "
    @"    };                                                                                      "
    @"    /* Stores data passed in when XMLHttpRequest is first opened. */                        "
    @"    XMLHttpRequest.prototype.open = function(method, url, async, user, password) {          "
    @"      if (!method) var method = '';                                                         "
    @"      if (!url) var url = '';                                                               "
    @"      if (!user) var user = '';                                                             "
    @"      if (!password) var password = '';                                                     "
    @"      /* false means don't return from XMLHttpRequest.send until it is complete. */         "
    @"      grey_ajaxListener.originalOpen.apply(this, [method, url, false, user, password]);     "
    @"    };                                                                                      "
    @"    /* Sends status updates to the delegate before and after the request. */                "
    @"    XMLHttpRequest.prototype.send = function(params) {                                      "
    @"      grey_ajaxListener.updateStatus('starting');                                           "
    @"      try {                                                                                 "
    @"        grey_ajaxListener.originalSend.apply(this, arguments);                              "
    @"      } catch(err) {                                                                        "
    @"      }                                                                                     "
    @"      grey_ajaxListener.updateStatus('completed');                                          "
    @"    };                                                                                      "
    @"  }                                                                                         "
    @"}                                                                                           "
    @"/* Run handler script in top-most frame */                                                  "
    @"window.eval(__ajaxHandlerScript());                                                         "
    @"/* Run script in every iframe. */                                                           "
    @"for (var i = 0; i < window.frames.length; i++) {                                            "
    @"  window.frames[i].eval(__ajaxHandlerScript());                                             "
    @"}                                                                                           ";

@implementation GREYUIWebViewDelegate

- (instancetype)initWithOriginalUIWebViewDelegate:(id<UIWebViewDelegate>)originalDelegate {
  return [super initWithOriginalDelegate:originalDelegate isWeak:YES];
}

#pragma mark - UIWebViewDelegate Protocol

- (BOOL)webView:(UIWebView *)webView
    shouldStartLoadWithRequest:(NSURLRequest *)request
                navigationType:(UIWebViewNavigationType)navigationType {
  // Clear any pending interactions, since the UIWebView delegate has now been called.
  [webView grey_clearPendingInteraction];

  BOOL retVal = YES;

  // Detect AJAX Handler calls by checking the request's URL scheme.
  // If the request is a ping from the AJAX handler, update tracking.
  // Return NO at the end as we don't want the UIWebView to actually load the request.
  NSURL *requestURL = [request URL];
  if ([[requestURL scheme] isEqual:kAjaxListenerScheme]) {
    NSString *host = [[requestURL absoluteURL] host];
    if ([host isEqual:@"starting"]) {
      NSLog(@"AJAX load starting");
      [webView grey_trackAJAXLoading];
    } else if ([host isEqual:@"completed"]) {
      NSLog(@"AJAX load completed");
      [webView grey_untrackAJAXLoading];
      [GREYUIWebViewIdlingResource idlingResourceForWebView:webView name:@"AJAX Rendering Tracker"];
    }
    retVal = NO;
  } else if ([self.originalDelegate respondsToSelector:_cmd]) {
    retVal = [self.originalDelegate webView:webView
                 shouldStartLoadWithRequest:request
                             navigationType:navigationType];
  }

  if (retVal) {
    // In some cases, for instance, when NSURLProtocol decides to intercept a request and cancel
    // the underlying connection responsible for loading the webview, webViewDidFinishLoad is never
    // actually invoked so keeping a counter of will/did calls is moot.
    // Hence, we install an idling resource that tracks UIWebView's loading and rendering,
    // providing the desired synchronization.
    [GREYUIWebViewIdlingResource idlingResourceForWebView:webView
                                                     name:@"UIWebView Pre-Load Tracker"];
  }
  return retVal;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
  // The web view idling resources rely on accurate tracking of the web view's loading state.
  // Unfortunately, we cannot use UIWebView's isLoading method because it is not always accurate.
  // isLoading can get permanently stuck in a loading state, but we can rely on the delegate
  // callbacks being called.
  [webView grey_setIsLoadingFrame:YES];

  if ([self.originalDelegate respondsToSelector:_cmd]) {
    [self.originalDelegate webViewDidStartLoad:webView];
  }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
  [webView grey_setIsLoadingFrame:NO];
  // Inject greyAjaxHandler to monitor for any ajax calls.
  [webView stringByEvaluatingJavaScriptFromString:kAjaxListenerScript];

  // Re-install tracker since we don't know whether the pre-load tracker is still alive. Plus, this
  // is fairly inexpensive anyway.
  [GREYUIWebViewIdlingResource idlingResourceForWebView:webView
                                                   name:@"UIWebView Post-Load Rendering Tracker"];

  if ([self.originalDelegate respondsToSelector:_cmd]) {
    [self.originalDelegate webViewDidFinishLoad:webView];
  }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
  [webView grey_setIsLoadingFrame:NO];
  // TODO: Uninstall idling resources as well.
  [webView grey_untrackAJAXLoading];

  if ([self.originalDelegate respondsToSelector:_cmd]) {
    [self.originalDelegate webView:webView didFailLoadWithError:error];
  }
}

@end

#endif  // !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0
