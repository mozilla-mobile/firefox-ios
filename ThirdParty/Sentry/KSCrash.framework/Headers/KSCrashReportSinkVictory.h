//
//  KSCrashReportSinkVictory.h
//
//  Created by Kelp on 2013-03-14.
//
//  Copyright (c) 2013 Karl Stenerud. All rights reserved.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall remain in place
// in this source code.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//


#import "KSCrashReportFilter.h"


/**
 * Sends crash reports to Victory server.
 *
 * Input: NSDictionary
 * Output: Same as input (passthrough)
 */
@interface KSCrashReportSinkVictory : NSObject <KSCrashReportFilter>

/** Constructor.
 *
 * @param url The URL to connect to.
 * @param userName The user name of crash information *required. If value is nil it will be replaced with UIDevice.currentDevice.name
 * @param userEmail The user email of crash information *optional
 */
+ (KSCrashReportSinkVictory*) sinkWithURL:(NSURL*) url
                                   userName:(NSString*) userName
                                  userEmail:(NSString*) userEmail;;

/** Constructor.
 *
 * @param url The URL to connect to.
 * @param userName The user name of crash information *required. If value is nil it will be replaced with UIDevice.currentDevice.name
 * @param userEmail The user email of crash information *optional
 */
- (id) initWithURL:(NSURL*) url
          userName:(NSString*) userName
         userEmail:(NSString*) userEmail;

- (id <KSCrashReportFilter>) defaultCrashReportFilterSet;

@end
