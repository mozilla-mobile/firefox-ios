//
//  NewSpecificControlTests.m
//  KIF
//
//  Created by Alex Odawa on 1/27/15.
//
//

#import <KIF/KIF.h>

@interface SpecificControlTests_ViewTestActor : KIFTestCase
@end

@implementation SpecificControlTests_ViewTestActor

- (void)beforeEach
{
    [[viewTester usingLabel:@"Tapping"] tap];
}

- (void)afterEach
{
    [[[viewTester usingLabel:@"Test Suite"] usingTraits:UIAccessibilityTraitButton] tap];
}

- (void)testTogglingASwitch
{
    [[[viewTester usingLabel:@"Happy"] usingValue:@"1"] waitForView];
    [[viewTester usingLabel:@"Happy"] setSwitchOn:NO];
    [[[viewTester usingLabel:@"Happy"] usingValue:@"0"] waitForView];
    [[viewTester usingLabel:@"Happy"] setSwitchOn:YES];
    [[[viewTester usingLabel:@"Happy"] usingValue:@"1"] waitForView];
}

- (void)testMovingASlider
{
    [viewTester waitForTimeInterval:1];
    [[viewTester usingLabel:@"Slider"] setSliderValue:3];
    [[[viewTester usingLabel:@"Slider"] usingValue:@"3"] waitForView];
    [[viewTester usingLabel:@"Slider"] setSliderValue:0];
    [[[viewTester usingLabel:@"Slider"] usingValue:@"0"] waitForView];
    [[viewTester usingLabel:@"Slider"] setSliderValue:5];
    [[[viewTester usingLabel:@"Slider"] usingValue:@"5"] waitForView];
}

- (void)testPickingAPhoto
{
    // 'acknowledgeSystemAlert' can't be used on iOS7
    // The console shows a message "AX Lookup problem! 22 com.apple.iphone.axserver:-1"
    if ([UIDevice.currentDevice.systemVersion compare:@"8.0" options:NSNumericSearch] < 0) {
        return;
    }
    
    [[viewTester usingLabel:@"Photos"] tap];
    [viewTester acknowledgeSystemAlert];
    [viewTester waitForTimeInterval:0.5f]; // Wait for view to stabilize
    
    [viewTester choosePhotoInAlbum:@"Camera Roll" atRow:1 column:2];
    [[viewTester usingLabel:@"UIImage"] waitForView];
}

@end
