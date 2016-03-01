//
//  SpecificControlTests.m
//  Test Suite
//
//  Created by Brian Nickel on 6/28/13.
//  Copyright (c) 2013 Brian Nickel. All rights reserved.
//

#import <KIF/KIF.h>

@interface SpecificControlTests : KIFTestCase
@end

@implementation SpecificControlTests

- (void)beforeEach
{
    [tester tapViewWithAccessibilityLabel:@"Tapping"];
}

- (void)afterEach
{
    [tester tapViewWithAccessibilityLabel:@"Test Suite" traits:UIAccessibilityTraitButton];
}

- (void)testTogglingASwitch
{
    [tester waitForViewWithAccessibilityLabel:@"Happy" value:@"1" traits:UIAccessibilityTraitNone];
    [tester setOn:NO forSwitchWithAccessibilityLabel:@"Happy"];
    [tester waitForViewWithAccessibilityLabel:@"Happy" value:@"0" traits:UIAccessibilityTraitNone];
    [tester setOn:YES forSwitchWithAccessibilityLabel:@"Happy"];
    [tester waitForViewWithAccessibilityLabel:@"Happy" value:@"1" traits:UIAccessibilityTraitNone];
}

- (void)testMovingASlider
{
    [tester waitForTimeInterval:1];
    [tester setValue:3 forSliderWithAccessibilityLabel:@"Slider"];
    [tester waitForViewWithAccessibilityLabel:@"Slider" value:@"3" traits:UIAccessibilityTraitNone];
    [tester setValue:0 forSliderWithAccessibilityLabel:@"Slider"];
    [tester waitForViewWithAccessibilityLabel:@"Slider" value:@"0" traits:UIAccessibilityTraitNone];
    [tester setValue:5 forSliderWithAccessibilityLabel:@"Slider"];
    [tester waitForViewWithAccessibilityLabel:@"Slider" value:@"5" traits:UIAccessibilityTraitNone];
}

- (void)testPickingAPhoto {
    [tester tapViewWithAccessibilityLabel:@"Photos"];
    [tester acknowledgeSystemAlert];
    [tester waitForTimeInterval:0.5f]; // Wait for view to stabilize

    NSOperatingSystemVersion iOS8 = {8, 0, 0};
    if ([NSProcessInfo instancesRespondToSelector:@selector(isOperatingSystemAtLeastVersion:)] && [[NSProcessInfo new] isOperatingSystemAtLeastVersion:iOS8]) {
        [tester choosePhotoInAlbum:@"Camera Roll" atRow:1 column:2];
    } else {
        [tester choosePhotoInAlbum:@"Saved Photos" atRow:1 column:2];
    }
    [tester waitForViewWithAccessibilityLabel:@"UIImage"];
}

@end
