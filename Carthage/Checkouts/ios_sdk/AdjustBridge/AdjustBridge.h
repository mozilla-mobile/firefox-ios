//
//  AdjustBridge.h
//  Adjust
//
//  Created by Pedro Filipe on 27/04/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <Foundation/Foundation.h>

#import "WKWebViewJavascriptBridge.h"

@interface AdjustBridge : NSObject

- (void)loadUIWebViewBridge:(UIWebView *)webView;
- (void)loadWKWebViewBridge:(WKWebView *)webView;
- (void)sendDeeplinkToWebView:(NSURL *)deeplink;

@end
