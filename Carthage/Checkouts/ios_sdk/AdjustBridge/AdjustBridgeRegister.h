//
//  AdjustWebViewJSBridge.h
//  Adjust
//
//  Created by Pedro Filipe on 10/06/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WebViewJavascriptBridge.h"
#import "WKWebViewJavascriptBridge.h"

@protocol AdjustBridgeRegister <NSObject>

- (void)callHandler:(NSString *)handlerName data:(id)data;
- (void)registerHandler:(NSString *)handlerName handler:(WVJBHandler)handler;

@end

@interface AdjustUIBridgeRegister : NSObject<AdjustBridgeRegister>

+ (id<AdjustBridgeRegister>)bridgeRegisterWithUIWebView:(WVJB_WEBVIEW_TYPE *)webView;

@end

@interface AdjustWKBridgeRegister : NSObject<AdjustBridgeRegister>

+ (id<AdjustBridgeRegister>)bridgeRegisterWithWKWebView:(WKWebView *)webView;

@end
