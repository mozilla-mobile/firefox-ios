//
//  AdjustBridgeRegister.m
//  Adjust
//
//  Created by Pedro Filipe on 10/06/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import "AdjustBridgeRegister.h"

static NSString * const kHandlerPrefix = @"adjust_";

@interface AdjustUIBridgeRegister()

@property (nonatomic, strong) WebViewJavascriptBridge *uiBridge;

@end

@implementation AdjustUIBridgeRegister

+ (id<AdjustBridgeRegister>)bridgeRegisterWithUIWebView:(WVJB_WEBVIEW_TYPE *)uiWebView {
    return [[AdjustUIBridgeRegister alloc] initWithUIWebView:uiWebView];
}

- (id)initWithUIWebView:(WVJB_WEBVIEW_TYPE *)uiWebView {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    self.uiBridge = [WebViewJavascriptBridge bridgeForWebView:uiWebView];

    return self;
}

- (void)registerHandler:(NSString *)handlerName handler:(WVJBHandler)handler {
    if ([handlerName hasPrefix:kHandlerPrefix] == NO) {
        return;
    }

    [self.uiBridge registerHandler:handlerName handler:handler];
}

- (void)callHandler:(NSString *)handlerName data:(id)data {
    if ([handlerName hasPrefix:kHandlerPrefix] == NO) {
        return;
    }

    [self.uiBridge callHandler:handlerName data:data];
}

@end

@interface AdjustWKBridgeRegister()

@property (nonatomic, strong) WKWebViewJavascriptBridge *wkBridge;

@end

@implementation AdjustWKBridgeRegister

+ (id<AdjustBridgeRegister>)bridgeRegisterWithWKWebView:(WKWebView *)wkWebView {
    return [[AdjustWKBridgeRegister alloc] initWithWKWebView:wkWebView];
}

- (id)initWithWKWebView:(WKWebView *)wkWebView {
    self = [super init];

    if (self == nil) {
        return nil;
    }

    self.wkBridge = [WKWebViewJavascriptBridge bridgeForWebView:wkWebView];

    return self;
}

- (void)registerHandler:(NSString *)handlerName handler:(WVJBHandler)handler {
    if ([handlerName hasPrefix:kHandlerPrefix] == NO) {
        return;
    }

    [self.wkBridge registerHandler:handlerName handler:handler];
}

- (void)callHandler:(NSString *)handlerName data:(id)data {
    if ([handlerName hasPrefix:kHandlerPrefix] == NO) {
        return;
    }

    [self.wkBridge callHandler:handlerName data:data];
}

@end
