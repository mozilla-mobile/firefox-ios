//
//  NewPickerTests.m
//  KIF
//
//  Created by Alex Odawa on 1/27/15.
//
//

#import <KIF/KIF.h>

@implementation KIFUIViewTestActor (pickertests)

- (KIFUIViewTestActor *)dateSelector
{
    return [self usingLabel:@"Date Selection"];
}

- (KIFUIViewTestActor *)dateTimeSelector
{
    return [self usingLabel:@"Date Time Selection"];
}

- (KIFUIViewTestActor *)timeSelector
{
    return [self usingLabel:@"Time Selection"];
}

- (KIFUIViewTestActor * )countdownSelector
{
    return [self usingLabel:@"Countdown Selection"];
}

@end


@interface PickerTests_ViewTestActor : KIFTestCase
@end

@implementation PickerTests_ViewTestActor

- (void)beforeEach
{
    [[viewTester usingLabel:@"Pickers"] tap];
}

- (void)afterEach
{
    [[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tap];
}

- (void)testSelectingDateInPast
{
    [[viewTester dateSelector] tap];
    NSArray *date = @[ @"June", @"17", @"1965" ];
    // If the UIDatePicker LocaleIdentifier would be de_DE then the date to set
    // would look like this: NSArray *date = @[@"17.", @"Juni", @"1965"
    [viewTester selectDatePickerValue:date];
    [[[viewTester dateSelector] usingValue:@"Jun 17, 1965"] waitForView];
}

- (void)testSelectingDateInFuture
{
    [[viewTester dateSelector] tap];
    NSArray *date = @[ @"December", @"31", @"2030" ];
    [viewTester selectDatePickerValue:date];
    [[[viewTester dateSelector] usingValue:@"Dec 31, 2030"] waitForView];
}

- (void)testSelectingDateTime
{
    [[viewTester dateTimeSelector] tap];
    NSArray *dateTime = @[ @"Jun 17", @"6", @"43", @"AM" ];
    [viewTester selectDatePickerValue:dateTime];
    [[[viewTester dateTimeSelector] usingValue:@"Jun 17, 06:43 AM"] waitForView];
}

- (void)testSelectingTime
{
    [[viewTester timeSelector] tap];
    NSArray *time = @[ @"7", @"44", @"AM" ];
    [viewTester selectDatePickerValue:time];
    [[[viewTester timeSelector] usingValue:@"7:44 AM"] waitForView];
}

- (void)testSelectingCountdown
{
    [[viewTester countdownSelector] tap];
    NSArray *countdown = @[ @"4", @"10" ];
    [viewTester selectDatePickerValue:countdown];
    [[[viewTester countdownSelector] usingValue:@"15000.000000"] waitForView];
}

- (void)testSelectingAPickerRow
{
    [viewTester selectPickerViewRowWithTitle:@"Charlie"];

    NSOperatingSystemVersion iOS8 = {8, 0, 0};
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)] && [[NSProcessInfo new] isOperatingSystemAtLeastVersion:iOS8]) {
        [[[viewTester usingLabel:@"Call Sign"] usingValue:@"Charlie"] waitForView];
    } else {
        [[[viewTester usingLabel:@"Call Sign"] usingValue:@"Charlie. 3 of 3"] waitForView];
    }
}

- (void)testSelectingRowInComponent
{
    [[viewTester dateSelector] tap];
    NSArray *date = @[ @"December", @"31", @"2030" ];
    [viewTester selectDatePickerValue:date];
    [viewTester selectPickerViewRowWithTitle:@"17" inComponent:1];
    [[[viewTester dateSelector] usingValue:@"Dec 17, 2030"] waitForView];
}

@end
