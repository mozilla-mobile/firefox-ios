//
//  WKWebViewController.h
//  AdjustExample-WebView
//
//  Created by Uglješa Erceg on 31/05/16.
//  Copyright © 2016 adjust GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "AdjustBridge.h"

@interface WKWebViewController : UINavigationController<WKNavigationDelegate>

@property AdjustBridge *adjustBridge;

@end
