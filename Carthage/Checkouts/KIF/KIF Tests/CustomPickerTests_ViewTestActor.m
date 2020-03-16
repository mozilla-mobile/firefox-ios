//
//  CustomPickerTests_ViewTestActor.m
//  KIF
//
//  Created by Deepakkumar Sharma on 19/08/17.
//
//

#import <KIF/KIF.h>

@interface CustomPickerTests_ViewTestActor : KIFTestCase
@end

@implementation CustomPickerTests_ViewTestActor

- (void)beforeEach
{
    [[viewTester usingLabel:@"Custom Picker"] tap];
}

- (void)afterEach
{
    [[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tap];
}

- (void)testSelectingCustomLabelRowInComponent
{
    [[viewTester usingLabel:@"Custom Label Selection"] tap];
    [viewTester selectPickerViewRowWithTitle:@"12" inComponent:0];
    [viewTester selectPickerViewRowWithTitle:@"11" inComponent:1];
    [viewTester selectPickerViewRowWithTitle:@"93" inComponent:2];
    [[[viewTester usingLabel:@"Custom Label Selection"] usingValue:@"121193"] waitForView];
}

- (void)testSelectingAttributedTitleRowInComponent
{
    [[viewTester usingLabel:@"Attributed Title Selection"] tap];
    [viewTester selectPickerViewRowWithTitle:@"12" inComponent:0];
    [viewTester selectPickerViewRowWithTitle:@"11" inComponent:1];
    [viewTester selectPickerViewRowWithTitle:@"93" inComponent:2];
    [[[viewTester usingLabel:@"Attributed Title Selection"] usingValue:@"121193"] waitForView];
}

- (void)testSelectingTextTitleRowInComponent
{
    [[viewTester usingLabel:@"Text Title Selection"] tap];
    [viewTester selectPickerViewRowWithTitle:@"12" inComponent:0];
    [viewTester selectPickerViewRowWithTitle:@"11" inComponent:1];
    [viewTester selectPickerViewRowWithTitle:@"93" inComponent:2];
    [[[viewTester usingLabel:@"Text Title Selection"] usingValue:@"121193"] waitForView];
}

@end
