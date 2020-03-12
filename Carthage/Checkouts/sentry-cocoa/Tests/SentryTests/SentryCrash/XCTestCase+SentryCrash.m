//
//  SenTestCase+SentryCrash.m
//
//  Created by Karl Stenerud on 2012-02-11.
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


#import "XCTestCase+SentryCrash.h"


@implementation XCTestCase (XCTestCase_SentryCrash)

- (NSString*) createTempPath
{
    NSString* path = [NSTemporaryDirectory() stringByAppendingString: [[NSProcessInfo processInfo] globallyUniqueString]];
    NSFileManager* fm = [NSFileManager defaultManager];
    if(![fm fileExistsAtPath:path])
    {
        [fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];
    }
    return path;
}

- (void) removePath:(NSString*) path
{
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
}


- (void) createTempReportsAtPath:(NSString*) reportsPath
                          prefix:(NSString*) reportPrefix
{
    NSError* error = nil;
    NSFileManager* fm = [NSFileManager defaultManager];

    [fm createDirectoryAtPath:reportsPath withIntermediateDirectories:YES attributes:nil error:&error];
    XCTAssertNil(error, @"");

    NSString* bundlePath = [[NSBundle bundleForClass:[self class]] resourcePath];
    NSArray* files = [fm contentsOfDirectoryAtPath:bundlePath error:&error];
    XCTAssertNil(error, @"");

    for(NSString* filename in files)
    {
        if([filename rangeOfString:reportPrefix].location != NSNotFound)
        {
            [fm copyItemAtPath:[bundlePath stringByAppendingPathComponent:filename]
                        toPath:[reportsPath stringByAppendingPathComponent:filename]
                         error:&error];
            XCTAssertNil(error, @"");
        }
    }
}

- (void) deleteTempReports:(NSString*) tempReportsPath
{
    NSError* error = nil;
    [[NSFileManager defaultManager] removeItemAtPath:tempReportsPath error:&error];
}

@end
