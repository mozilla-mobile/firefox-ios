//
//  SentryCrashSysCtl_Tests.m
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

#import "SentryCrashSysCtl.h"


@interface SentryCrashSysCtl_Tests : XCTestCase @end


@implementation SentryCrashSysCtl_Tests

- (void) testSysCtlInt32
{
    int32_t result = sentrycrashsysctl_int32(CTL_KERN, KERN_POSIX1);
    XCTAssertTrue(result > 0, @"");
}

- (void) testSysCtlInt32Invalid
{
    int32_t result = sentrycrashsysctl_int32(CTL_KERN, 1000000);
    XCTAssertTrue(result == 0, @"");
}

- (void) testSysCtlInt32ForName
{
    int32_t result = sentrycrashsysctl_int32ForName("kern.posix1version");
    XCTAssertTrue(result > 0, @"");
}

- (void) testSysCtlInt32ForNameInvalid
{
    int32_t result = sentrycrashsysctl_int32ForName("kernblah.posix1version");
    XCTAssertTrue(result == 0, @"");
}

- (void) testSysCtlInt64
{
    int64_t result = sentrycrashsysctl_int64(CTL_KERN, KERN_USRSTACK64);
    XCTAssertTrue(result > 0, @"");
}

- (void) testSysCtlInt64Invalid
{
    int64_t result = sentrycrashsysctl_int64(CTL_KERN, 1000000);
    XCTAssertTrue(result == 0, @"");
}

- (void) testSysCtlInt64ForName
{
    int64_t result = sentrycrashsysctl_int64ForName("kern.usrstack64");
    XCTAssertTrue(result > 0, @"");
}

- (void) testSysCtlInt64ForNameInvalid
{
    int64_t result = sentrycrashsysctl_int64ForName("kernblah.usrstack64");
    XCTAssertTrue(result == 0, @"");
}

- (void) testSysCtlUInt32
{
    uint32_t result = sentrycrashsysctl_uint32(CTL_KERN, KERN_POSIX1);
    XCTAssertTrue(result > 0, @"");
}

- (void) testSysCtlUInt32Invalid
{
    uint32_t result = sentrycrashsysctl_uint32(CTL_KERN, 1000000);
    XCTAssertTrue(result == 0, @"");
}

- (void) testSysCtlUInt32ForName
{
    uint32_t result = sentrycrashsysctl_uint32ForName("kern.posix1version");
    XCTAssertTrue(result > 0, @"");
}

- (void) testSysCtlUInt32ForNameInvalid
{
    uint32_t result = sentrycrashsysctl_uint32ForName("kernblah.posix1version");
    XCTAssertTrue(result == 0, @"");
}

- (void) testSysCtlUInt64
{
    uint64_t result = sentrycrashsysctl_uint64(CTL_KERN, KERN_USRSTACK64);
    XCTAssertTrue(result > 0, @"");
}

- (void) testSysCtlUInt64Invalid
{
    uint64_t result = sentrycrashsysctl_uint64(CTL_KERN, 1000000);
    XCTAssertTrue(result == 0, @"");
}

- (void) testSysCtlUInt64ForName
{
    uint64_t result = sentrycrashsysctl_uint64ForName("kern.usrstack64");
    XCTAssertTrue(result > 0, @"");
}

- (void) testSysCtlUInt64ForNameInvalid
{
    uint64_t result = sentrycrashsysctl_uint64ForName("kernblah.usrstack64");
    XCTAssertTrue(result == 0, @"");
}

- (void) testSysCtlString
{
    char buff[100] = {0};
    bool success = sentrycrashsysctl_string(CTL_KERN, KERN_OSTYPE, buff, sizeof(buff));
    XCTAssertTrue(success, @"");
    XCTAssertTrue(buff[0] != 0, @"");
}

- (void) testSysCtlStringInvalid
{
    char buff[100] = {0};
    bool success = sentrycrashsysctl_string(CTL_KERN, 1000000, buff, sizeof(buff));
    XCTAssertFalse(success, @"");
    XCTAssertTrue(buff[0] == 0, @"");
}

- (void) testSysCtlStringForName
{
    char buff[100] = {0};
    bool success = sentrycrashsysctl_stringForName("kern.ostype", buff, sizeof(buff));
    XCTAssertTrue(success, @"");
    XCTAssertTrue(buff[0] != 0, @"");
}

- (void) testSysCtlStringForNameInvalid
{
    char buff[100] = {0};
    bool success = sentrycrashsysctl_stringForName("kernblah.ostype", buff, sizeof(buff));
    XCTAssertFalse(success, @"");
    XCTAssertTrue(buff[0] == 0, @"");
}

- (void) testSysCtlDate
{
    struct timeval value = sentrycrashsysctl_timeval(CTL_KERN, KERN_BOOTTIME);
    XCTAssertTrue(value.tv_sec > 0, @"");
}

- (void) testSysCtlDateInvalid
{
    struct timeval value = sentrycrashsysctl_timeval(CTL_KERN, 1000000);
    XCTAssertTrue(value.tv_sec == 0, @"");
}

- (void) testSysCtlDateForName
{
    struct timeval value = sentrycrashsysctl_timevalForName("kern.boottime");
    XCTAssertTrue(value.tv_sec > 0, @"");
}

- (void) testSysCtlDateForNameInvalid
{
    struct timeval value = sentrycrashsysctl_timevalForName("kernblah.boottime");
    XCTAssertTrue(value.tv_sec == 0, @"");
}

- (void) testGetProcessInfo
{
    int pid = getpid();
    struct kinfo_proc procInfo = {{{{0}}}};
    bool success = sentrycrashsysctl_getProcessInfo(pid, &procInfo);
    XCTAssertTrue(success, @"");
    NSString* processName = [NSString stringWithCString:procInfo.kp_proc.p_comm encoding:NSUTF8StringEncoding];
    NSString* expected = @"xctest";
    XCTAssertEqualObjects(processName, expected, @"");
}

// This sysctl always returns true for some reason...
//- (void) testGetProcessInfoInvalid
//{
//    int pid = 1000000;
//    struct kinfo_proc procInfo = {{{{0}}}};
//    bool success = sentrycrashsysctl_getProcessInfo(pid, &procInfo);
//    XCTAssertFalse(success, @"");
//}

- (void) testGetMacAddress
{
    unsigned char macAddress[6] = {0};
    bool success = sentrycrashsysctl_getMacAddress("en0", (char*)macAddress);
    XCTAssertTrue(success, @"");
    unsigned int result = 0;
    for(unsigned i = 0; i < sizeof(macAddress); i++)
    {
        result |= macAddress[i];
    }
    XCTAssertTrue(result != 0, @"");
}

- (void) testGetMacAddressInvalid
{
    unsigned char macAddress[6] = {0};
    bool success = sentrycrashsysctl_getMacAddress("blah blah", (char*)macAddress);
    XCTAssertFalse(success, @"");
}

@end
