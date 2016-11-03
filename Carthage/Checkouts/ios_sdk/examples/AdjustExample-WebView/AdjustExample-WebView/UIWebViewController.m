//
//  ViewController.m
//  AdjustExample-WebView
//
//  Created by Uglješa Erceg on 31/05/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import "UIWebViewController.h"

@interface UIWebViewController ()

@end

@implementation UIWebViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)viewWillAppear:(BOOL)animated {
    [self loadUIWebView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)loadUIWebView {
    UIWebView *uiWebView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:uiWebView];

    _adjustBridge = [[AdjustBridge alloc] init];
    [_adjustBridge loadUIWebViewBridge:uiWebView];

    NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"AdjustExample-WebView" ofType:@"html"];
    NSString *appHtml = [NSString stringWithContentsOfFile:htmlPath encoding:NSUTF8StringEncoding error:nil];
    NSURL *baseURL = [NSURL fileURLWithPath:htmlPath];
    [uiWebView loadHTMLString:appHtml baseURL:baseURL];
}

- (void)callUiHandler:(id)sender {

}

@end

