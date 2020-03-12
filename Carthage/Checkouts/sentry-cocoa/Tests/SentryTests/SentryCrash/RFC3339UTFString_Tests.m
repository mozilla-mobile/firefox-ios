//
// RFC3339DateTool_Tests.m
//
// Copyright (c) 2010 Karl Stenerud. All rights reserved.
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
#import "SentryCrashDate.h"


@interface RFC3339DateTool_Tests : XCTestCase @end

NSString* stringFromDate(NSDate* date)
{
    char string[21];
    time_t timestamp = (time_t)date.timeIntervalSince1970;
    sentrycrashdate_utcStringFromTimestamp(timestamp, string);
    return [NSString stringWithUTF8String:string];
}

@implementation RFC3339DateTool_Tests

- (NSDate*) gmtDateWithYear:(int) year
                      month:(int) month
                        day:(int) day
                       hour:(int) hour
                     minute:(int) minute
                     second:(int) second
{
    NSDateComponents* components = [[NSDateComponents alloc] init];
    components.year = year;
    components.month = month;
    components.day = day;
    components.hour = hour;
    components.minute = minute;
    components.second = second;
    NSCalendar* calendar = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    [calendar setTimeZone:(NSTimeZone* _Nonnull)[NSTimeZone timeZoneWithAbbreviation:@"GMT"]];
    return [calendar dateFromComponents:components];
}

- (void) testStringFromDate
{
    NSDate* date = [self gmtDateWithYear:2000 month:1 day:2 hour:3 minute:4 second:5];
    NSString* expected = @"2000-01-02T03:04:05Z";
    NSString* actual = stringFromDate(date);

    XCTAssertEqualObjects(actual, expected, @"");
}

@end
