//
//  SentryCrashMonitor_Signal_Tests.m
//
//  Created by Karl Stenerud on 2013-01-26.
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


#import <XCTest/XCTest.h>

#import "SentryCrashMonitorContext.h"
#import "SentryCrashMonitor_Signal.h"


@interface SentryCrashMonitor_Signal_Tests : XCTestCase @end


@implementation SentryCrashMonitor_Signal_Tests

- (void) testInstallAndRemove
{
    SentryCrashMonitorAPI* api = sentrycrashcm_signal_getAPI();
    api->setEnabled(true);
    XCTAssertTrue(api->isEnabled());
    [NSThread sleepForTimeInterval:0.1];
    api->setEnabled(false);
    XCTAssertFalse(api->isEnabled());
}

- (void) testDoubleInstallAndRemove
{
    SentryCrashMonitorAPI* api = sentrycrashcm_signal_getAPI();

    api->setEnabled(true);
    XCTAssertTrue(api->isEnabled());
    api->setEnabled(true);
    XCTAssertTrue(api->isEnabled());

    api->setEnabled(false);
    XCTAssertFalse(api->isEnabled());
    api->setEnabled(false);
    XCTAssertFalse(api->isEnabled());
}

@end
