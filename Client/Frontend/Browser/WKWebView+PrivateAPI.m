/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

#import "WKWebView+PrivateAPI.h"

@interface WKWebView (Internal)

- (void)_loadAlternateHTMLString:(NSString *)string baseURL:(NSURL *)baseURL forUnreachableURL:(NSURL *)unreachableURL;

@end

@implementation WKWebView (PrivateAPI)

- (void)loadAlternateHTMLString:(NSString *)string baseURL:(NSURL *)baseURL forUnreachableURL:(NSURL *)unreachableURL
{
    [self _loadAlternateHTMLString:string baseURL:baseURL forUnreachableURL:unreachableURL];
}

@end
