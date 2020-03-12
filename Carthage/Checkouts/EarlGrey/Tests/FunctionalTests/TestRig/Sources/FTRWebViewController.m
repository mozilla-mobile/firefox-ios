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

#import "FTRWebViewController.h"

@implementation FTRWebViewController

@synthesize activityIndicator = _activityIndicator;
@synthesize webView = _webView;

/**
 *  Returns the url to the test HTML file.
 */
+ (NSURL *)urlToTestHTMLFile {
  return [[NSBundle mainBundle] URLForResource:@"testpage" withExtension:@"html"];
}

/**
 *  Returns the url to the test a PDF file.
 */
+ (NSURL *)urlToTestPDF {
  return [[NSBundle mainBundle] URLForResource:@"bigtable" withExtension:@"pdf"];
}

- (instancetype)init {
  NSAssert(NO, @"Invalid Initializer");
  return nil;
}

- (void)dealloc {
  // Must clear any custom delegate in dealloc
  [_webView setDelegate:nil];
}

- (void)viewDidLoad {
  [super viewDidLoad];

  // Must be set explicitly, otherwise iPad will show the title of the previous UIViewController,
  // while iPhone will show Back. This is because "EarlGrey TestApp" is too long to fit on iPhone.
  self.navigationController.navigationBar.backItem.title = @"Back";
  self.extendedLayoutIncludesOpaqueBars = NO;
  self.edgesForExtendedLayout = UIRectEdgeNone;
  self.view.isAccessibilityElement = NO;
  _webView.superview.isAccessibilityElement = NO;
  _webView.accessibilityElementsHidden = NO;
  _webView.userInteractionEnabled = YES;
  _webView.accessibilityIdentifier = @"FTRTestWebView";
}

- (void)viewDidLayoutSubviews {
  _webView.frame = self.view.bounds;
}

- (IBAction)userDidTapLoadGoogle {
  NSURL *url = [NSURL URLWithString:@"https://www.google.com/#q=test"];
  NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
  [_webView loadRequest:requestObj];
  _webView.scrollView.bounces = _webViewBounceSwitch.isOn;
}

- (IBAction)userDidTapLoadLocalTestPage {
  [_webView loadRequest:[NSURLRequest requestWithURL:[FTRWebViewController urlToTestHTMLFile]]];
  _webView.scrollView.bounces = _webViewBounceSwitch.isOn;
}

- (IBAction)userDidTapLoadHTMLUsingLoadHTMLString {
  NSString *html = [NSString stringWithContentsOfURL:[FTRWebViewController urlToTestHTMLFile]
                                            encoding:NSUTF8StringEncoding
                                               error:nil];
  [_webView loadHTMLString:html baseURL:[NSURL URLWithString:@"http://www.earlgrey.com"]];
  _webView.scrollView.bounces = _webViewBounceSwitch.isOn;
}

- (IBAction)userDidTapLoadPDF {
  NSData *pdfData = [NSData dataWithContentsOfURL:[[self class] urlToTestPDF]];
  [_webView loadData:pdfData
              MIMEType:@"application/pdf"
      textEncodingName:@"utf-8"
               baseURL:[NSURL URLWithString:@"about:blank"]];
}

- (IBAction)userDidToggleBounce:(UISwitch *)sender {
  _webView.scrollView.bounces = sender.isOn;
}

#pragma mark - UIWebViewDelegate methods

- (void)webViewDidStartLoad:(UIWebView *)view {
  [_activityIndicator startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)view {
  [_activityIndicator stopAnimating];
}

@end
