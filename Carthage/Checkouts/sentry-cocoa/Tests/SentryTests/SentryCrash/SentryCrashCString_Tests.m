//
//  SentryCrashCString_Tests.m
//
//  Created by Karl Stenerud on 2013-03-09.
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

#import "SentryCrashCString.h"


@interface SentryCrashCString_Tests : XCTestCase @end


@implementation SentryCrashCString_Tests

- (void) testNSString
{
    NSString* expected = @"Expected";
    SentryCrashCString* actual = [SentryCrashCString stringWithString:expected];
    BOOL matches = strcmp([expected cStringUsingEncoding:NSUTF8StringEncoding], actual.bytes) == 0;
    XCTAssertTrue(matches, @"");
    XCTAssertEqual(actual.length, expected.length, @"");
}

- (void) testCString
{
    const char* expected = "Expected";
    NSUInteger expectedLength = strlen(expected);
    SentryCrashCString* actual = [SentryCrashCString stringWithCString:expected];
    BOOL matches = strcmp(expected, actual.bytes) == 0;
    XCTAssertTrue(matches, @"");
    XCTAssertEqual(actual.length, expectedLength, @"");
}

- (void) testNSData
{
    const char* expected = "Expected";
    NSUInteger expectedLength = strlen(expected);
    NSData* source = [NSData dataWithBytes:expected length:expectedLength];
    SentryCrashCString* actual = [SentryCrashCString stringWithData:source];
    BOOL matches = strcmp(expected, actual.bytes) == 0;
    XCTAssertTrue(matches, @"");
    XCTAssertEqual(actual.length, expectedLength, @"");
}

- (void) testData
{
    const char* expected = "Expected";
    NSUInteger expectedLength = strlen(expected);
    SentryCrashCString* actual = [SentryCrashCString stringWithData:expected length:expectedLength];
    BOOL matches = strcmp(expected, actual.bytes) == 0;
    XCTAssertTrue(matches, @"");
    XCTAssertEqual(actual.length, expectedLength, @"");
}

@end
