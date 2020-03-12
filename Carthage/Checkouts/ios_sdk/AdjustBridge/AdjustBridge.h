//
//  AdjustBridge.h
//  Adjust SDK
//
//  Created by Pedro Filipe (@nonelse) on 27th April 2016.
//  Copyright © 2016-2018 Adjust GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <Foundation/Foundation.h>
#import "AdjustBridgeRegister.h"

@interface AdjustBridge : NSObject

@property (nonatomic, strong, readonly) AdjustBridgeRegister *bridgeRegister;

- (void)loadWKWebViewBridge:(WKWebView *)wkWebView;
- (void)loadWKWebViewBridge:(WKWebView *)wkWebView wkWebViewDelegate:(id<WKNavigationDelegate>)wkWebViewDelegate;
- (void)augmentHybridWebView;

@end
