#import <KIF/KIF.h>

@interface PickerTests : KIFTestCase
@end

@implementation PickerTests

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"Pickers"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
}

- (void)testSelectingDateInPast
{
    [tester tapViewWithAccessibilityLabel:@"Date Selection"];
    NSArray *date = @[@"June", @"17", @"1965"];
    // If the UIDatePicker LocaleIdentifier would be de_DE then the date to set
    // would look like this: NSArray *date = @[@"17.", @"Juni", @"1965"
    [tester selectDatePickerValue:date];
    [tester waitForViewWithAccessibilityLabel:@"Date Selection" value:@"Jun 17, 1965" traits:UIAccessibilityTraitNone];
}

- (void)testSelectingDateInFuture
{
    [tester tapViewWithAccessibilityLabel:@"Date Selection"];
    NSArray *date = @[@"December", @"31", @"2030"];
    [tester selectDatePickerValue:date];
    [tester waitForViewWithAccessibilityLabel:@"Date Selection" value:@"Dec 31, 2030" traits:UIAccessibilityTraitNone];
}

- (void)testSelectingDateTime
{
    [tester tapViewWithAccessibilityLabel:@"Date Time Selection"];
    NSArray *dateTime = @[@"Jun 17", @"6", @"43", @"AM"];
    [tester selectDatePickerValue:dateTime];
    [tester waitForViewWithAccessibilityLabel:@"Date Time Selection" value:@"Jun 17, 06:43 AM" traits:UIAccessibilityTraitNone];
}

- (void)testSelectingTime
{
    [tester tapViewWithAccessibilityLabel:@"Time Selection"];
    NSArray *time = @[@"7", @"44", @"AM"];
    [tester selectDatePickerValue:time];
    [tester waitForViewWithAccessibilityLabel:@"Time Selection" value:@"7:44 AM" traits:UIAccessibilityTraitNone];
}

- (void)testSelectingCountdown
{
    [tester tapViewWithAccessibilityLabel:@"Countdown Selection"];
    NSArray *countdown = @[@"4", @"10"];
    [tester selectDatePickerValue:countdown];
    [tester waitForViewWithAccessibilityLabel:@"Countdown Selection" value:@"15000.000000" traits:UIAccessibilityTraitNone];
}

- (void)testSelectingAPickerRow
{
    [tester selectPickerViewRowWithTitle:@"Charlie"];
    
    NSOperatingSystemVersion iOS8 = {8, 0, 0};
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)] && [[NSProcessInfo new] isOperatingSystemAtLeastVersion:iOS8]) {
        [tester waitForViewWithAccessibilityLabel:@"Call Sign" value:@"Charlie" traits:UIAccessibilityTraitNone];
    } else {
        [tester waitForViewWithAccessibilityLabel:@"Call Sign" value:@"Charlie. 3 of 3" traits:UIAccessibilityTraitNone];
    }
}

- (void)testSelectingRowInComponent
{
    [tester tapViewWithAccessibilityLabel:@"Date Selection"];
    NSArray *date = @[@"December", @"31", @"2030"];
    [tester selectDatePickerValue:date];
    [tester selectPickerViewRowWithTitle:@"17" inComponent:1];
    [tester waitForViewWithAccessibilityLabel:@"Date Selection" value:@"Dec 17, 2030" traits:UIAccessibilityTraitNone];
}

@end
