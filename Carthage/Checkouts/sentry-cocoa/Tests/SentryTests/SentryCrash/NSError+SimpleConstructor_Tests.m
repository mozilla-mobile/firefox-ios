//
//  NSError+SimpleConstructor_Tests.m
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

#import "NSError+SentrySimpleConstructor.h"


@interface NSError_SimpleConstructor_Tests : XCTestCase @end


@implementation NSError_SimpleConstructor_Tests

- (void) testErrorWithDomain
{
    NSError* error = [NSError errorWithDomain:@"Domain" code:10 description:@"A description %d", 1];
    NSString* expectedDomain = @"Domain";
    NSInteger expectedCode = 10;
    NSString* expectedDescription = @"A description 1";
    XCTAssertEqualObjects(error.domain, expectedDomain, @"");
    XCTAssertEqual(error.code, expectedCode, @"");
    XCTAssertEqualObjects(error.localizedDescription, expectedDescription, @"");
}

- (void) testFillError
{
    NSError* error = nil;
    [NSError fillError:&error withDomain:@"Domain" code:10 description:@"A description %d", 1];
    NSString* expectedDomain = @"Domain";
    NSInteger expectedCode = 10;
    NSString* expectedDescription = @"A description 1";
    XCTAssertEqualObjects(error.domain, expectedDomain, @"");
    XCTAssertEqual(error.code, expectedCode, @"");
    XCTAssertEqualObjects(error.localizedDescription, expectedDescription, @"");
}

- (void) testFillErrorNil
{
    [NSError fillError:nil withDomain:@"Domain" code:10 description:@"A description %d", 1];
}

- (void) testClearError
{
    NSError* error = [NSError errorWithDomain:@"" code:1 description:@""];
    XCTAssertNotNil(error, @"");
    [NSError clearError:&error];
    XCTAssertNil(error, @"");
}

- (void) testClearErrorNil
{
    [NSError clearError:nil];
}

@end
