//
//  WKWebViewController.m
//  AdjustWebBridgeTestApp
//
//  Created by Pedro Silva (@nonelse) on 6th August 2018.
//  Copyright © 2018 Adjust GmbH. All rights reserved.
//

#import "WKWebViewController.h"
#import <JavaScriptCore/JavaScriptCore.h>

#import "AdjustBridge.h"
#import "TestLibraryBridge.h"


@interface WKWebViewController ()

@property AdjustBridge *adjustBridge;
@property TestLibraryBridge *testLibraryBridge;

@end

@implementation WKWebViewController

- (void)viewWillAppear:(BOOL)animated {
    WKWebView *webView = [[NSClassFromString(@"WKWebView") alloc] initWithFrame:self.view.bounds];
    webView.navigationDelegate = self;
    [self.view addSubview:webView];

    _adjustBridge = [[AdjustBridge alloc] init];
    [_adjustBridge loadWKWebViewBridge:webView wkWebViewDelegate:self];

    self.testLibraryBridge = [[TestLibraryBridge alloc] initWithAdjustBridgeRegister:[self.adjustBridge bridgeRegister]];

    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"AdjustTestApp-WebView" ofType:@"html"];
    NSString *appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
    [webView loadHTMLString:appHtml baseURL:baseURL];
}

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"webViewDidStartLoad");
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"webViewDidFinishLoad");
}

@end
