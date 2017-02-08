//
//  LPMessageTemplates.h
//
//  Copyright 2016 Leanplum, Inc.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// 1. The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 2. This software and its derivatives may only be used in conjunction with the
// Leanplum SDK within apps that have a valid subscription to the Leanplum platform,
// at http://www.leanplum.com
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
// Standard use (somewhere before [Leanplum start]):
//   [LPMessageTemplates sharedTemplates];
// That's it!

#import <Foundation/Foundation.h>
#import "Leanplum/Leanplum.h"

#ifndef LPMessageTemplatesClass
#define LPMessageTemplatesClass LPMessageTemplates
#endif

@interface LPMessageTemplatesClass : NSObject
#if LP_NOT_TV
    <UIAlertViewDelegate, UIWebViewDelegate>
#endif

+ (LPMessageTemplatesClass *)sharedTemplates;

#if LP_NOT_TV
- (void)disableAskToAsk;
- (void)refreshPushPermissions;
#endif

@end
