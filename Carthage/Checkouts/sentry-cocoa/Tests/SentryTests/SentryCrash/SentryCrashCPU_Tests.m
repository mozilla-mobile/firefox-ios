//
//  SentryCrashCPU_Tests.m
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

#import "SentryCrashCPU.h"
#import "SentryCrashMachineContext.h"
#import "TestThread.h"

#import <mach/mach.h>


@interface SentryCrashCPU_Tests : XCTestCase @end

@implementation SentryCrashCPU_Tests

- (void) testCPUState
{
    TestThread* thread = [[TestThread alloc] init];
    [thread start];
    [NSThread sleepForTimeInterval:0.1];
    kern_return_t kr;
    kr = thread_suspend(thread.thread);
    XCTAssertTrue(kr == KERN_SUCCESS, @"");

    SentryCrashMC_NEW_CONTEXT(machineContext);
    sentrycrashmc_getContextForThread(thread.thread, machineContext, NO);
    sentrycrashcpu_getState(machineContext);

    int numRegisters = sentrycrashcpu_numRegisters();
    for(int i = 0; i < numRegisters; i++)
    {
        const char* name = sentrycrashcpu_registerName(i);
        XCTAssertTrue(name != NULL, @"Register %d was NULL", i);
        sentrycrashcpu_registerValue(machineContext, i);
    }

    const char* name = sentrycrashcpu_registerName(1000000);
    XCTAssertTrue(name == NULL, @"");
    uint64_t value = sentrycrashcpu_registerValue(machineContext, 1000000);
    XCTAssertTrue(value == 0, @"");

    uintptr_t address;
    address = sentrycrashcpu_framePointer(machineContext);
    XCTAssertTrue(address != 0, @"");
    address = sentrycrashcpu_stackPointer(machineContext);
    XCTAssertTrue(address != 0, @"");
    address = sentrycrashcpu_instructionAddress(machineContext);
    XCTAssertTrue(address != 0, @"");

    numRegisters = sentrycrashcpu_numExceptionRegisters();
    for(int i = 0; i < numRegisters; i++)
    {
        name = sentrycrashcpu_exceptionRegisterName(i);
        XCTAssertTrue(name != NULL, @"Register %d was NULL", i);
        sentrycrashcpu_exceptionRegisterValue(machineContext, i);
    }

    name = sentrycrashcpu_exceptionRegisterName(1000000);
    XCTAssertTrue(name == NULL, @"");
    value = sentrycrashcpu_exceptionRegisterValue(machineContext, 1000000);
    XCTAssertTrue(value == 0, @"");

    sentrycrashcpu_faultAddress(machineContext);

    thread_resume(thread.thread);
    [thread cancel];
}

- (void) testStackGrowDirection
{
    sentrycrashcpu_stackGrowDirection();
}

@end
