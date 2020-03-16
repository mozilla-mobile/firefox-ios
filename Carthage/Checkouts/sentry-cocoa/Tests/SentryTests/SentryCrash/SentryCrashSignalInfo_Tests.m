//
//  SentryCrashSignalInfo_Tests.m
//
//  Created by Karl Stenerud on 2012-03-03.
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

#import "SentryCrashSignalInfo.h"


@interface SentryCrashSignalInfo_Tests : XCTestCase @end


@implementation SentryCrashSignalInfo_Tests

- (void) testSignalName
{
    NSString* expected = @"SIGBUS";
    NSString* actual = [NSString stringWithCString:sentrycrashsignal_signalName(SIGBUS) encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(actual, expected, @"");
}

- (void) testHighSignalName
{
    const char* result = sentrycrashsignal_signalName(90);
    XCTAssertTrue(result == NULL, @"");
}

- (void) testNegativeSignalName
{
    const char* result = sentrycrashsignal_signalName(-1);
    XCTAssertTrue(result == NULL, @"");
}

- (void) testSignalCodeName
{
    NSString* expected = @"BUS_ADRERR";
    NSString* actual = [NSString stringWithCString:sentrycrashsignal_signalCodeName(SIGBUS, BUS_ADRERR)
                                          encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(actual, expected, @"");
}

- (void) testHighSignalCodeName
{
    const char* result = sentrycrashsignal_signalCodeName(SIGBUS, 90);
    XCTAssertTrue(result == NULL, @"");
}

- (void) testNegativeSignalCodeName
{
    const char* result = sentrycrashsignal_signalCodeName(SIGBUS, -1);
    XCTAssertTrue(result == NULL, @"");
}

- (void) testFatalSignals
{
    const int* fatalSignals = sentrycrashsignal_fatalSignals();
    XCTAssertTrue(fatalSignals != NULL, @"");
}

- (void) testNumFatalSignals
{
    int numSignals = sentrycrashsignal_numFatalSignals();
    XCTAssertTrue(numSignals > 0, @"");
}

@end
