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

#import "Synchronization/GREYUIWebViewIdlingResource.h"

#if !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0

#import "Additions/UIWebView+GREYAdditions.h"
#import "Assertion/GREYAssertionDefines.h"
#import "Common/GREYDefines.h"
#import "Common/GREYThrowDefines.h"
#import "Synchronization/GREYUIThreadExecutor+Internal.h"
#import "Synchronization/GREYUIThreadExecutor.h"

/**
 *  The maximum number of render passes to wait for before the UIWebView can be considered idle.
 */
static const NSInteger kMaxRenderPassesToWait = 2;

/**
 *  This script adds a JavaScript snippet that keeps tracks of browser's render passes in a global
 *  variable @c grey_renderPassesCount. This process will continue until the global variable
 *  @c grey_shouldTrackRendering is set to false. The return value is the number of passes the
 *  script was able to track. Note that iOS safari may drop recursively called request for animation
 *  frames if the page is loaded using UIWebView's loadHTMLString:baseURL: and also if the target
 *  page has JavaScript errors. Hence, this script must be injected multiple times.
 */
static NSString *const kRenderPassTrackerScript =
    @"  (function() {                                                                       "
    @"    function onRenderPass() {                                                         "
    @"      if (!window.grey_renderPassesCount) {                                           "
    @"        window.grey_shouldTrackRendering = true;                                      "
    @"        window.grey_renderPassesCount = 0;                                            "
    @"      }                                                                               "
    @"      window.grey_renderPassesCount += 1;                                             "
    @"      if (window.grey_shouldTrackRendering) {                                         "
    @"        window.requestAnimationFrame(onRenderPass);                                   "
    @"      }                                                                               "
    @"    }                                                                                 "
    @"    window.requestAnimationFrame(onRenderPass);                                       "
    @"    return (window.grey_renderPassesCount ? window.grey_renderPassesCount : 0);       "
    @"  })()                                                                                ";

/**
 *  This script sets @c grey_shouldTrackRendering to false to stop any EarlGrey tracking code
 *  present on the page.
 */
static NSString *const kTrackerScriptCleanupScript =
    @"  (function() {                                                                       "
    @"     window.grey_shouldTrackRendering = false;                                        "
    @"  })()                                                                                ";

@implementation GREYUIWebViewIdlingResource {
  /**
   *  Main UIWebView being interacted with.
   */
  __weak UIWebView *_webView;
  /**
   *  Object name returned by idling resource name.
   */
  NSString *_webViewName;
}

+ (instancetype)idlingResourceForWebView:(UIWebView *)webView name:(NSString *)name {
  GREYUIWebViewIdlingResource *res =
      [[GREYUIWebViewIdlingResource alloc] initWithUIWebView:webView
                                                        name:name];
  [[GREYUIThreadExecutor sharedInstance] registerIdlingResource:res];
  return res;
}

- (instancetype)initWithUIWebView:(UIWebView *)webView name:(NSString *)name {
  GREYThrowOnNilParameter(webView);

  self = [super init];
  if (self) {
    _webViewName = [name copy];
    _webView = webView;
  }
  return self;
}

#pragma mark - GREYIdlingResource

- (NSString *)idlingResourceName {
  return _webViewName;
}

- (NSString *)idlingResourceDescription {
  return _webViewName;
}

- (BOOL)isIdleNow {
  UIWebView *strongWebView = _webView;

  if (!strongWebView) {
    [[GREYUIThreadExecutor sharedInstance] deregisterIdlingResource:self];
    return YES;
  }

  // Make this check before running any JavaScript. The JavaScript operations are synchronous,
  // very heavy, and will drastically slow down page loading.
  if ([strongWebView grey_isLoadingFrame]) {
    return NO;
  }

  NSString *documentState =
      [self grey_evaluateAndAssertNoErrorsJavaScriptInString:@"document.readyState"];
  if ([documentState isEqualToString:@"loading"]) {
    return NO;
  }

  NSString *visibilityState =
      [self grey_evaluateAndAssertNoErrorsJavaScriptInString:@"document.visibilityState"];
  // Ignore if document is hidden because our attempts to inject image into DOM won't work.
  // See https://developer.mozilla.org/en-US/docs/Web/Guide/User_experience/Using_the_Page_Visibility_API
  if (![visibilityState isEqualToString:@"hidden"]) {
    NSString *renderPassCountResult =
        [self grey_evaluateAndAssertNoErrorsJavaScriptInString:kRenderPassTrackerScript];
    NSInteger renderPasses = [renderPassCountResult integerValue];
    if (renderPasses < kMaxRenderPassesToWait) {
      return NO;
    } else {
      // Run the cleanup script and discard the return value.
      [self grey_evaluateAndAssertNoErrorsJavaScriptInString:kTrackerScriptCleanupScript];
    }
  }

  id webViewInternal = [_webView valueForKey:@"_internal"];

  // UIWebViews may be used to display PDFs in addition to HTML based content. Test if there's a PDF
  // view populated in UIWebView's hierarchy.
  BOOL webViewIsDisplayingPDF =
      ([[webViewInternal valueForKey:@"pdfHandler"] valueForKey:@"pdfView"] != nil);
  if (webViewIsDisplayingPDF) {
    return YES;
  }

  id internalWebBrowserView = [webViewInternal valueForKey:@"browserView"];
  if (internalWebBrowserView) {
    @autoreleasepool {
      // There is a slight delay between a UIWebView delegate receiving webViewDidFinishLoad and
      // all of the WebAccessibilityObjectWrappers corresponding to the text on the web page being
      // populated.  While the UIWebView's accessibility tree is being populated,
      // accessibilityElementCount will come back as NSNotFound instead of >= 0.
      // If we traverse the tree ensuring none are returning NSNotFound,
      // then we know loading is most likely done.
      NSMutableArray *runningElementHierarchy = [[NSMutableArray alloc] init];
      [runningElementHierarchy addObject:internalWebBrowserView];
      while (runningElementHierarchy.count > 0) {
        id currentElement = [runningElementHierarchy firstObject];
        NSInteger accessibilityElementCount = [currentElement accessibilityElementCount];
        [runningElementHierarchy removeObjectAtIndex:0];
        // Verify the child accessibility element has a valid element count.
        if (accessibilityElementCount == NSNotFound) {
          return NO;
        }
        // Add all children elements.
        for (NSInteger i = 0; i < accessibilityElementCount; i++) {
          id childElement = [currentElement accessibilityElementAtIndex:i];
          if (childElement) {
            [runningElementHierarchy addObject:childElement];
          }
        }
      }
    }
  }
  // If all of the child accessibility elements have valid element counts, then iOS is done
  // populating the WebAccessibilityObjectWrappers.
  [[GREYUIThreadExecutor sharedInstance] deregisterIdlingResource:self];
  return YES;
}

/**
 *  Evaluates JavaScript in @c jsString wrapping it in a try-catch block to detect errors and
 *  asserts that there were no errors after the javascript was executed.
 *
 *  @param jsString JavaScript source code to be evaluated.
 *  @return Stringified JavaScript value as returned by the script.
 */
- (NSString *)grey_evaluateAndAssertNoErrorsJavaScriptInString:(NSString *)jsString {
  NSString *grey_errorPrefix = @"grey_errorPrefix";
  NSString *const safeJavaScriptTemplate =
      @"  (function() {                                                                    "
      @"     try {                                                                         "
      @"       return (%@);                                                                "
      @"     } catch(e) {                                                                  "
      @"       return '%@:' + String(e);                                                   "
      @"     }                                                                             "
      @"   })();                                                                           ";
  NSString *safeJavaScript =
      [NSString stringWithFormat:safeJavaScriptTemplate, jsString, grey_errorPrefix];
  NSString *result = [_webView stringByEvaluatingJavaScriptFromString:safeJavaScript];
  I_GREYAssertFalse([result hasPrefix:grey_errorPrefix],
                    @"Javascript error %@ was detected in %@.",
                    jsString, [result substringFromIndex:[grey_errorPrefix length]]);
  return result;
}

@end

#endif  // !defined(__IPHONE_12_0) || __IPHONE_OS_VERSION_MIN_REQUIRED < __IPHONE_12_0
