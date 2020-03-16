//
//  SentryCrashReportConverter_Tests.m
//
//  Created by Karl Stenerud on 2012-02-24.
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


#import "FileBasedTestCase.h"
#import "XCTestCase+SentryCrash.h"


//#import "SentryCrashReportConverter.h"
#import "SentryCrashReportStore.h"

#define REPORT_PREFIX @"CrashReport-SentryCrashTest"

#define REPORT_BADPOINTER @"CrashReport-SentryCrashTest-BadPointer.json"
#define REPORT_NSEXCEPTION @"CrashReport-SentryCrashTest-NSException.json"

#define APPLE_BADPOINTER_UNSYMBOLICATED @"AppleReport-SentryCrashTest-BadPointer-Unsymbolicated.txt"
#define APPLE_NSEXCEPTION_UNSYMBOLICATED @"AppleReport-SentryCrashTest-NSException-Unsymbolicated.txt"


@interface SentryCrashReportConverter_Tests : FileBasedTestCase @end

@implementation SentryCrashReportConverter_Tests
#if 0
- (void) setUp
{
    [super setUp];
    [self createTempReportsAtPath:self.tempPath prefix:REPORT_PREFIX];
}

- (SentryCrashReportStore*) store
{
//    return [SentryCrashReportStore storeWithPath:self.tempPath filenamePrefix:REPORT_PREFIX];
    return nil;
}

- (NSString*) resourcePathOfFile:(NSString*) file
{
    return [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:file];
}

- (NSString*) loadAppleReportNamed:(NSString*) name
{
    NSString* filename = [[[NSBundle bundleForClass:[self class]] resourcePath] stringByAppendingPathComponent:name];
    NSError* error = nil;
    NSString* result = [NSString stringWithContentsOfFile:filename encoding:NSUTF8StringEncoding error:&error];
    XCTAssertNil(error, @"");
    return result;
}

- (void) testConvertReportsUnsymbolicated
{
    // TODO
    return;

//    SentryCrashReportStore* store = [self store];
//    NSDictionary* report = [store reportNamed:REPORT_BADPOINTER];
//    NSString* converted = [SentryCrashReportConverter toAppleFormat:report
//                                                    reportStyle:SentryCrashAppleReportStyleUnsymbolicated];
//    XCTAssertNotNil(converted, @"");
//
//    NSString* expected = [self loadAppleReportNamed:APPLE_BADPOINTER_UNSYMBOLICATED];
//    XCTAssertNotNil(expected, @"");
//
//    XCTAssertTrue([converted isEqualToString:expected], @"");
}
#endif
@end
