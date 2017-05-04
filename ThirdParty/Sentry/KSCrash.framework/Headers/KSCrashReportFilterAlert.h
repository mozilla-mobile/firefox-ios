//
//  KSCrashReportFilterAlert.h
//
//  Created by Karl Stenerud on 2012-08-24.
//
//  Copyright (c) 2012 Karl Stenerud. All rights reserved.
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


#import <Foundation/Foundation.h>
#import "KSCrashReportFilter.h"


/** Pops up a standard alert window and awaits a user response before continuing.
 *
 * This filter can be set up as a conditional or unconditional filter. If both a
 * "yes" and "no" button are defined, it will only continue if the user presses
 * the "yes" button. If only a "yes" button is defined ("no" button is nil), it
 * will continue unconditionally when the alert is dismissed.
 *
 * Input: Any
 * Output: Same as input (passthrough)
 */
@interface KSCrashReportFilterAlert : NSObject <KSCrashReportFilter>

/**
 * @param title The title of the alert.
 * @param message The contents of the alert.
 * @param yesAnswer The text to put in the "yes" button.
 * @param noAnswer The text to put in the "no" button. If nil, the filter will
 *                 proceed unconditionally.
 */
+ (KSCrashReportFilterAlert*) filterWithTitle:(NSString*) title
                                      message:(NSString*) message
                                    yesAnswer:(NSString*) yesAnswer
                                     noAnswer:(NSString*) noAnswer;

/**
 * @param title The title of the alert.
 * @param message The contents of the alert.
 * @param yesAnswer The text to put in the "yes" button.
 * @param noAnswer The text to put in the "no" button. If nil, the filter will
 *                 proceed unconditionally.
 */
- (id) initWithTitle:(NSString*) title
             message:(NSString*) message
           yesAnswer:(NSString*) yesAnswer
            noAnswer:(NSString*) noAnswer;

@end
