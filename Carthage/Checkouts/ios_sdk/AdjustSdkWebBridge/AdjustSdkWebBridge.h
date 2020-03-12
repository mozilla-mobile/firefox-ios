//
//  AdjustSdkWebBridge.h
//  AdjustSdkWebBridge
//
//  Created by Uglješa Erceg (@uerceg) on 27th July 2018.
//  Copyright © 2018 Adjust GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

//! Project version number for AdjustSdkWebBridge.
FOUNDATION_EXPORT double AdjustSdkWebBridgeVersionNumber;

//! Project version string for AdjustSdkWebBridge.
FOUNDATION_EXPORT const unsigned char AdjustSdkWebBridgeVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <AdjustSdkWebBridge/PublicHeader.h>

#import <AdjustSdkWebBridge/Adjust.h>
#import <AdjustSdkWebBridge/AdjustBridge.h>
#import <AdjustSdkWebBridge/ADJEvent.h>
#import <AdjustSdkWebBridge/ADJConfig.h>
#import <AdjustSdkWebBridge/ADJLogger.h>
#import <AdjustSdkWebBridge/ADJAttribution.h>
#import <AdjustSdkWebBridge/ADJEventSuccess.h>
#import <AdjustSdkWebBridge/ADJEventFailure.h>
#import <AdjustSdkWebBridge/ADJSessionSuccess.h>
#import <AdjustSdkWebBridge/ADJSessionFailure.h>

// Exposing entire WebViewJavascriptBridge framework
#import <AdjustSdkWebBridge/WebViewJavascriptBridge_JS.h>
#import <AdjustSdkWebBridge/WebViewJavascriptBridgeBase.h>
#import <AdjustSdkWebBridge/WKWebViewJavascriptBridge.h>
