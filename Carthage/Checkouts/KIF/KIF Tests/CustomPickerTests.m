//
//  CustomPickerTests.m
//  KIF
//
//  Created by Deepakkumar Sharma on 19/08/17.
//
//

#import <KIF/KIF.h>

@interface CustomPickerTests : KIFTestCase
@end

@implementation CustomPickerTests

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"Custom Picker"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
}

- (void)testSelectingCustomLabelRowInComponent
{
    [tester tapViewWithAccessibilityLabel:@"Custom Label Selection"];
    [tester selectPickerViewRowWithTitle:@"12" inComponent:0];
    [tester selectPickerViewRowWithTitle:@"11" inComponent:1];
    [tester selectPickerViewRowWithTitle:@"93" inComponent:2];
    [tester waitForViewWithAccessibilityLabel:@"Custom Label Selection" value:@"121193" traits:UIAccessibilityTraitNone];
}

- (void)testSelectingAttributedTitleRowInComponent
{
    [tester tapViewWithAccessibilityLabel:@"Attributed Title Selection"];
    [tester selectPickerViewRowWithTitle:@"12" inComponent:0];
    [tester selectPickerViewRowWithTitle:@"11" inComponent:1];
    [tester selectPickerViewRowWithTitle:@"93" inComponent:2];
    [tester waitForViewWithAccessibilityLabel:@"Attributed Title Selection" value:@"121193" traits:UIAccessibilityTraitNone];
}

- (void)testSelectingTextTitleRowInComponent
{
    [tester tapViewWithAccessibilityLabel:@"Text Title Selection"];
    [tester selectPickerViewRowWithTitle:@"12" inComponent:0];
    [tester selectPickerViewRowWithTitle:@"11" inComponent:1];
    [tester selectPickerViewRowWithTitle:@"93" inComponent:2];
    [tester waitForViewWithAccessibilityLabel:@"Text Title Selection" value:@"121193" traits:UIAccessibilityTraitNone];
}

@end

