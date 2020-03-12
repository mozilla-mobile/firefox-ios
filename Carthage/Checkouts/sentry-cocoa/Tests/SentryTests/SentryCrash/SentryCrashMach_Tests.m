//
//  SentryCrashMach_Tests.m
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

#import "SentryCrashMach.h"
#include <mach/exception_types.h>
#include <mach/kern_return.h>


@interface SentryCrashMach_Tests : XCTestCase @end

@implementation SentryCrashMach_Tests

- (void) testExceptionName
{
    NSString* expected = @"EXC_ARITHMETIC";
    NSString* actual = [NSString stringWithCString:sentrycrashmach_exceptionName(EXC_ARITHMETIC)
                                          encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(actual, expected, @"");
}

- (void) testVeryHighExceptionName
{
    const char* result = sentrycrashmach_exceptionName(100000);
    XCTAssertTrue(result == NULL, @"");
}

- (void) testKernReturnCodeName
{
    NSString* expected = @"KERN_FAILURE";
    NSString* actual = [NSString stringWithCString:sentrycrashmach_kernelReturnCodeName(KERN_FAILURE)
                                          encoding:NSUTF8StringEncoding];
    XCTAssertEqualObjects(actual, expected, @"");
}

- (void) testVeryHighKernReturnCodeName
{
    const char* result = sentrycrashmach_kernelReturnCodeName(100000);
    XCTAssertTrue(result == NULL, @"");
}

#define EXC_UNIX_BAD_SYSCALL 0x10000 /* SIGSYS */
#define EXC_UNIX_BAD_PIPE    0x10001 /* SIGPIPE */
#define EXC_UNIX_ABORT       0x10002 /* SIGABRT */

- (void) testMachExeptionsForSignals
{
    [self assertMachException:EXC_ARITHMETIC code:0 matchesSignal:SIGFPE];
    [self assertMachException:EXC_BAD_ACCESS code:0 matchesSignal:SIGBUS];
    [self assertMachException:EXC_BAD_ACCESS code:KERN_INVALID_ADDRESS matchesSignal:SIGSEGV];
    [self assertMachException:EXC_BAD_INSTRUCTION code:0 matchesSignal:SIGILL];
    [self assertMachException:EXC_BREAKPOINT code:0 matchesSignal:SIGTRAP];
    [self assertMachException:EXC_EMULATION code:0 matchesSignal:SIGEMT];
    [self assertMachException:EXC_SOFTWARE code:EXC_UNIX_BAD_SYSCALL matchesSignal:SIGSYS];
    [self assertMachException:EXC_SOFTWARE code:EXC_UNIX_BAD_PIPE matchesSignal:SIGPIPE];
    [self assertMachException:EXC_SOFTWARE code:EXC_UNIX_ABORT matchesSignal:SIGABRT];
    [self assertMachException:EXC_SOFTWARE code:EXC_SOFT_SIGNAL matchesSignal:SIGKILL];
    [self assertMachException:EXC_SOFTWARE code:100000000 matchesSignal:0];
    [self assertMachException:1000000000 code:0 matchesSignal:0];
}

- (void) testSignalsForMachExeptions
{
    [self assertSignal:SIGFPE matchesMachException:EXC_ARITHMETIC];
    [self assertSignal:SIGSEGV matchesMachException:EXC_BAD_ACCESS];
    [self assertSignal:SIGBUS matchesMachException:EXC_BAD_ACCESS];
    [self assertSignal:SIGILL matchesMachException:EXC_BAD_INSTRUCTION];
    [self assertSignal:SIGTRAP matchesMachException:EXC_BREAKPOINT];
    [self assertSignal:SIGEMT matchesMachException:EXC_EMULATION];
    [self assertSignal:SIGSYS matchesMachException:EXC_UNIX_BAD_SYSCALL];
    [self assertSignal:SIGPIPE matchesMachException:EXC_UNIX_BAD_PIPE];
    [self assertSignal:SIGABRT matchesMachException:EXC_CRASH];
    [self assertSignal:SIGKILL matchesMachException:EXC_SOFT_SIGNAL];
    [self assertSignal:1000000000 matchesMachException:0];
}

- (void) assertMachException:(int) exception code:(int) code matchesSignal:(int) signal
{
    int result = sentrycrashmach_signalForMachException(exception, code);
    XCTAssertEqual(result, signal, @"");
}

- (void) assertSignal:(int) signal matchesMachException:(int) exception
{
    int result = sentrycrashmach_machExceptionForSignal(signal);
    XCTAssertEqual(result, exception, @"");
}

@end
