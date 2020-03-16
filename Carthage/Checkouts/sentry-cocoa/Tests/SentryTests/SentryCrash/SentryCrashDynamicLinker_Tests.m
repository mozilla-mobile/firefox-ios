//
//  SentryCrashDynamicLinker_Tests.m
//
//  Created by Karl Stenerud on 2013-10-02.
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
#include <mach-o/dyld.h>

#import "SentryCrashDynamicLinker.h"

@interface SentryCrashDynamicLinker_Tests : XCTestCase @end

@implementation SentryCrashDynamicLinker_Tests

- (void) testImageUUID
{
    // Just abritrarily grab the name of the 4th image...
    const char* name = _dyld_get_image_name(4);
    const uint8_t* uuidBytes = sentrycrashdl_imageUUID(name, true);
    XCTAssertTrue(uuidBytes != NULL, @"");
}

- (void) testImageUUIDInvalidName
{
    const uint8_t* uuidBytes = sentrycrashdl_imageUUID("sdfgserghwerghwrh", true);
    XCTAssertTrue(uuidBytes == NULL, @"");
}

- (void) testImageUUIDNULLName
{
    const uint8_t* uuidBytes = sentrycrashdl_imageUUID(NULL, true);
    XCTAssertTrue(uuidBytes == NULL, @"");
}

- (void) testImageUUIDPartialMatch
{
    const uint8_t* uuidBytes = sentrycrashdl_imageUUID("libSystem", false);
    XCTAssertTrue(uuidBytes != NULL, @"");
}

- (void) testGetImageNameNULL
{
    uint32_t imageIdx = sentrycrashdl_imageNamed(NULL, false);
    XCTAssertEqual(imageIdx, UINT32_MAX, @"");
}


@end
